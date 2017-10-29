/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2017 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "CbTextView.h"
#include "libtl/libtweetlength.h"
#include "corebird.h"
#ifdef SPELLCHECK
#include <gspell/gspell.h>
#endif

#define TAG_NO_SPELL_CHECK "gtksourceview:context-classes:no-spell-check"
static const char * TEXT_TAGS[] = {"hashtag", "mention", "link", "snippet" };

G_DEFINE_TYPE (CbTextView, cb_text_view, GTK_TYPE_WIDGET);

enum {
  SIGNAL_CHANGED,
  LAST_SIGNAL
};
static guint text_view_signals[LAST_SIGNAL] = { 0 };


static void
get_link_color (CbTextView *self,
                GdkRGBA    *out_link_color)
{
  GtkStyleContext *context = gtk_widget_get_style_context (GTK_WIDGET (self));

  gtk_style_context_save (context);
  gtk_style_context_set_state (context, GTK_STATE_FLAG_LINK);
  gtk_style_context_get_color (context, out_link_color);
  gtk_style_context_restore (context);

  if (out_link_color->red == 1.0 &&
      out_link_color->green == 1.0 &&
      out_link_color->blue == 1.0 &&
      out_link_color->alpha == 1.0)
    {
      out_link_color->red = 1.0;
      out_link_color->green = 0.0;
      out_link_color->blue = 0.0;
      out_link_color->alpha = 1.0;
    }
}

static void
cb_text_view_measure (GtkWidget      *widget,
                      GtkOrientation  orientation,
                      int             for_size,
                      int            *minimum,
                      int            *natural,
                      int            *minimum_baseline,
                      int            *natural_baseline)
{
  CbTextView *self = CB_TEXT_VIEW (widget);
  int min1, nat1;
  int min2, nat2;

  gtk_widget_measure (self->scrolled_window, orientation, for_size, &min1, &nat1, NULL, NULL);
  gtk_widget_measure (self->box,             orientation, for_size, &min2, &nat2, NULL, NULL);

  if (orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      *minimum = MAX (min1, min2);
      *natural = MAX (nat1, nat2);
    }
  else /* VERTICAL */
    {
      *minimum = min1 + min2;
      *natural = nat1 + nat2;
    }
}

static void
cb_text_view_size_allocate (GtkWidget           *widget,
                            const GtkAllocation *allocation,
                            int                  baseline,
                            GtkAllocation       *out_clip)
{
  CbTextView *self = CB_TEXT_VIEW (widget);
  GtkAllocation child_alloc;
  int box_height;
  GdkRectangle child_clip;

  gtk_widget_measure (self->box, GTK_ORIENTATION_VERTICAL, allocation->width,
                      &box_height, NULL, NULL, NULL);

  child_alloc.x = 0;
  child_alloc.y = allocation->height - box_height;
  child_alloc.width = allocation->width;
  child_alloc.height = box_height;
  gtk_widget_size_allocate (self->box, &child_alloc, -1, out_clip);

  child_alloc.y = 0;
  child_alloc.height = allocation->height - box_height;
  gtk_widget_size_allocate (self->scrolled_window, &child_alloc, -1, &child_clip);

  gdk_rectangle_union (&child_clip, &child_clip, out_clip);
}

static void
cb_text_view_finalize (GObject *object)
{
  CbTextView *self = CB_TEXT_VIEW (object);

  gtk_widget_unparent (self->box);
  gtk_widget_unparent (self->scrolled_window);

  g_object_unref (self->account);

  G_OBJECT_CLASS (cb_text_view_parent_class)->finalize (object);
}

static void
cb_text_view_grab_focus (GtkWidget *widget)
{
  CbTextView *self = CB_TEXT_VIEW (widget);

  gtk_widget_grab_focus (self->text_view);
}

static void
text_buffer_changed_cb (GtkTextBuffer *buffer,
                        gpointer       user_data)
{
  CbTextView *self = user_data;
  GtkTextIter start_iter;
  GtkTextIter end_iter;
  char *text;
  TlEntity *entities;
  gsize n_entities;
  guint i;

  gtk_text_buffer_get_bounds (buffer, &start_iter, &end_iter);

  /* Remove all *our* tags (gspell might add others) */
  for (i = 0; i < G_N_ELEMENTS (TEXT_TAGS); i ++)
    gtk_text_buffer_remove_tag_by_name (buffer, TEXT_TAGS[i], &start_iter, &end_iter);

  text = gtk_text_buffer_get_text (buffer, &start_iter, &end_iter, FALSE);
  entities = tl_extract_entities_and_text (text, &n_entities, NULL);

  for (i = 0; i < n_entities; i ++)
    {
      const TlEntity *e = &entities[i];
      GtkTextIter entity_start;
      GtkTextIter entity_end;

      gtk_text_buffer_get_iter_at_offset (buffer, &entity_start, e->start_character_index);
      gtk_text_buffer_get_iter_at_offset (buffer, &entity_end,
                                          e->start_character_index + e->length_in_characters);

      /* We ignore spell checking for all our special entities */
      gtk_text_buffer_apply_tag_by_name (buffer, TAG_NO_SPELL_CHECK, &entity_start, &entity_end);

      switch (e->type)
        {
          case TL_ENT_MENTION:
            gtk_text_buffer_apply_tag_by_name (buffer, "mention", &entity_start, &entity_end);
            break;
          case TL_ENT_HASHTAG:
            gtk_text_buffer_apply_tag_by_name (buffer, "hashtag", &entity_start, &entity_end);
            break;
          case TL_ENT_LINK:
            gtk_text_buffer_apply_tag_by_name (buffer, "link", &entity_start, &entity_end);
            break;

          default: {}

        }
    }

  g_free (text);
  g_signal_emit (self, text_view_signals[SIGNAL_CHANGED], 0);
}

static void
cb_text_view_class_init (CbTextViewClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_text_view_finalize;

  widget_class->measure = cb_text_view_measure;
  widget_class->size_allocate = cb_text_view_size_allocate;
  widget_class->grab_focus = cb_text_view_grab_focus;

  text_view_signals[SIGNAL_CHANGED] = g_signal_new ("changed",
                                                    G_OBJECT_CLASS_TYPE (object_class),
                                                    G_SIGNAL_RUN_FIRST,
                                                    0,
                                                    NULL, NULL,
                                                    NULL, G_TYPE_NONE, 0);

  gtk_widget_class_set_css_name (GTK_WIDGET_CLASS (klass), "textview");
}

static void
cb_text_view_init (CbTextView *self)
{
  GtkTextBuffer *buffer;
  GdkRGBA link_color;
  GdkRGBA snippet_color = { 0.0, 0.65, 0.0627, 1.0};

  gtk_widget_set_has_window (GTK_WIDGET (self), FALSE);
  gtk_widget_set_can_focus (GTK_WIDGET (self), TRUE);

  self->scrolled_window = gtk_scrolled_window_new (NULL, NULL);
  gtk_widget_set_parent (self->scrolled_window, GTK_WIDGET (self));

  self->text_view = gtk_text_view_new ();
  g_signal_connect (gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view)),
                    "changed", G_CALLBACK (text_buffer_changed_cb), self);
  gtk_text_view_set_accepts_tab (GTK_TEXT_VIEW (self->text_view), FALSE);
  gtk_text_view_set_wrap_mode (GTK_TEXT_VIEW (self->text_view), PANGO_WRAP_WORD_CHAR);
  gtk_container_add (GTK_CONTAINER (self->scrolled_window), self->text_view);

  buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view));
  get_link_color (self, &link_color);
  gtk_text_buffer_create_tag (buffer, TAG_NO_SPELL_CHECK, NULL);
  gtk_text_buffer_create_tag (buffer, "mention", "foreground-rgba", &link_color, NULL);
  gtk_text_buffer_create_tag (buffer, "hashtag", "foreground-rgba", &link_color, NULL);
  gtk_text_buffer_create_tag (buffer, "link", "foreground-rgba", &link_color, NULL);
  gtk_text_buffer_create_tag (buffer, "snippet", "foreground-rgba", &snippet_color, NULL);


  self->box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->box), "dim-label");
  gtk_widget_set_parent (self->box, GTK_WIDGET (self));

  gtk_style_context_add_class (gtk_widget_get_style_context (GTK_WIDGET (self)), "view");
  gtk_style_context_add_class (gtk_widget_get_style_context (GTK_WIDGET (self)), "fancy");

#ifdef SPELLCHECK
  {
    GspellView *gspell_view = gspell_get_from_gtk_text_view (GTK_TEXT_VIEW (self->text_view));
    GspellTextBuffer *gspell_buffer;
    GspellChecker *checker;
    gspell_text_view_set_inline_spell_checking (gspell_view, TRUE);
    gspell_text_view_set_enable_language_menu (gspell_view, TRUE);

    gspell_buffer = gspell_text_buffer_get_from_gtk_text_buffer (buffer);
    checker = gspell_checker_new (gspell_language_get_default ());
    gspell_buffer_set_spell_checker (checker);
  }
#endif
}

GtkWidget *
cb_text_view_new (void)
{
  return GTK_WIDGET (g_object_new (CB_TYPE_TEXT_VIEW, NULL));
}

void
cb_text_view_set_account (CbTextView *self,
                          void       *account)
{
  g_set_object (&self->account, account);
}

void
cb_text_view_add_widget (CbTextView *self,
                         GtkWidget  *widget)
{
  gtk_container_add (GTK_CONTAINER (self->box), widget);
}

void
cb_text_view_insert_at_cursor (CbTextView *self,
                               const char *text)
{
  g_return_if_fail (text != NULL);

  gtk_text_buffer_insert_at_cursor (gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view)),
                                    text, -1);
}

void
cb_text_view_set_text (CbTextView *self,
                       const char *text)
{
  gtk_text_buffer_set_text (gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view)), text, -1);
}

char *
cb_text_view_get_text (CbTextView *self)
{
  GtkTextBuffer *buffer;
  GtkTextIter start_iter;
  GtkTextIter end_iter;

  buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view));
  gtk_text_buffer_get_start_iter (buffer, &start_iter);
  gtk_text_buffer_get_end_iter (buffer, &end_iter);

  return gtk_text_buffer_get_text (buffer,
                                   &start_iter,
                                   &end_iter,
                                   FALSE);
}
