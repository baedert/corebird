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
#include "CbUserCounter.h"
#include "CbUtils.h"
#include <libtweetlength.h>
#include "corebird.h"
#ifdef SPELLCHECK
#include <gspell/gspell.h>
#endif

#define TAG_NO_SPELL_CHECK "gtksourceview:context-classes:no-spell-check"
static const char * TEXT_TAGS[] = {"hashtag", "mention", "link", "snippet" };

G_DEFINE_TYPE (CbTextView, cb_text_view, GTK_TYPE_WIDGET);

enum {
  SIGNAL_CHANGED,
  SIGNAL_SEND,
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

static char *
cb_text_view_get_cursor_word (CbTextView *self,
                              guint      *start_index,
                              guint      *end_index)
{
  GtkTextBuffer *buffer;
  GtkTextIter start_iter;
  GtkTextIter end_iter;
  char *text;
  TlEntity *entities;
  gsize n_entities;
  guint i;
  guint cursor_position;
  char *cursor_word = NULL;

  if (start_index != NULL)
    g_assert (end_index != NULL);

  buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view));
  gtk_text_buffer_get_bounds (buffer, &start_iter, &end_iter);
  g_object_get (G_OBJECT (buffer), "cursor-position", &cursor_position, NULL);

  text = gtk_text_buffer_get_text (buffer, &start_iter, &end_iter, FALSE);
  entities = tl_extract_entities_and_text (text, &n_entities, NULL);

  for (i = 0; i < n_entities; i ++)
    {
      const TlEntity *e = &entities[i];

      if (e->start_character_index <= cursor_position &&
          e->start_character_index + e->length_in_characters >= cursor_position)
        {
          cursor_word = g_malloc (e->length_in_bytes + 1);
          memcpy (cursor_word, e->start, e->length_in_bytes);
          cursor_word[e->length_in_bytes] = '\0';

          if (start_index != NULL)
            {
              *start_index = e->start_character_index;
              *end_index = e->start_character_index + e->length_in_characters;
            }

          break;
        }
    }

  g_free (entities);
  g_free (text);

  return cursor_word;
}

static void
completion_animate_func (CbAnimation *animation,
                         double       t)
{
  CbTextView *self = (CbTextView *)animation->owner;

  self->completion_show_factor = t;
  gtk_widget_queue_allocate (animation->owner);
}

static void
users_received_cb (GObject      *source_object,
                   GAsyncResult *result,
                   gpointer      user_data)
{
  CbTextView *self = user_data;
  CbUserIdentity *ids;
  int n_ids;
  GError *error = NULL;

  ids = cb_utils_query_users_finish (result, &n_ids, &error);

  if (error != NULL)
    {
      if (error->code != G_IO_ERROR_CANCELLED)
        g_warning ("%s Error: %s", __FUNCTION__, error->message);

      return;
    }

  cb_user_completion_model_insert_items (self->completion_model, ids, n_ids);

  g_free (ids);
}

static void
cb_text_view_select_completion_row (CbTextView *self,
                                    int         row_index)
{
  int n_rows = (int)g_list_model_get_n_items (G_LIST_MODEL (self->completion_model));
  int new_index;
  GtkListBoxRow *row;

  /* We just don't support larger jumps here, which doesn't matter in practice... */
  if (row_index == -1)
    row_index = n_rows - 1;

  new_index = row_index % n_rows;
  row = gtk_list_box_get_row_at_index (GTK_LIST_BOX (self->completion_listbox), new_index);
  gtk_list_box_select_row (GTK_LIST_BOX (self->completion_listbox), row);

  self->selected_row = new_index;
}

static void
cb_text_view_start_completion (CbTextView *self,
                               const char *query)
{
  CbUserInfo *local_infos;
  int n_local_infos;

  g_return_if_fail (query != NULL);

  if (!gtk_widget_get_realized (GTK_WIDGET (self)))
    return;

  if (self->completion_word != NULL &&
      strcmp (query, self->completion_word) == 0)
    return;

  g_free (self->completion_word);
  self->completion_word = g_strdup (query);

  if (self->completion_cancellable != NULL)
    g_cancellable_cancel (self->completion_cancellable);

  cb_user_completion_model_clear (self->completion_model);

  cb_user_counter_query_by_prefix (((Account*)self->account)->user_counter,
                                   sql_database_get_sqlite_db (((Account*)self->account)->db),
                                   query, 10, &local_infos, &n_local_infos);

  cb_user_completion_model_insert_infos (self->completion_model,
                                         local_infos,
                                         n_local_infos);

  /* Now load users from the server */
  self->completion_cancellable = g_cancellable_new ();
  cb_utils_query_users_async (REST_PROXY (((Account*)self->account)->proxy),
                              query,
                              self->completion_cancellable,
                              users_received_cb,
                              self);

  gtk_widget_show (self->completion_scroller);
  if (!cb_animation_is_running (&self->completion_show_animation) &&
      self->completion_show_factor < 1.0)
    cb_animation_start (&self->completion_show_animation);

  if (g_list_model_get_n_items (G_LIST_MODEL (self->completion_model)) > 0)
    cb_text_view_select_completion_row (self, 0);

  g_free (local_infos);
}

static void
cb_text_view_stop_completion (CbTextView *self)
{
  if (self->completion_show_factor <= 0.0)
    return;

  self->completion_show_factor = 0.0;
  self->selected_row = 0;
  cb_animation_start_reverse (&self->completion_show_animation);
}

static gboolean
cb_text_view_is_completing (CbTextView *self)
{
  return self->completion_show_factor > 0;
}

static GtkWidget *
create_completion_row_func (gpointer item,
                            gpointer user_data)
{
  const CbUserIdentity *id = item;
  char *screen_name;
  GtkWidget *row = gtk_list_box_row_new ();
  GtkWidget *box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 0);
  GtkWidget *l1 = gtk_label_new (id->user_name);
  GtkWidget *l2 = gtk_label_new (NULL);

  screen_name = g_strdup_printf ("@%s", id->screen_name);
  gtk_label_set_label (GTK_LABEL (l2), screen_name);
  g_free (screen_name);

  gtk_style_context_add_class (gtk_widget_get_style_context (box), "col-spacing");
  gtk_style_context_add_class (gtk_widget_get_style_context (l2), "dim-label");

  gtk_container_add (GTK_CONTAINER (box), l1);
  gtk_container_add (GTK_CONTAINER (box), l2);
  gtk_container_add (GTK_CONTAINER (row), box);

  g_object_set_data_full (G_OBJECT (row), "row-data", g_strdup (id->screen_name), g_free);

  return row;
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

  if (gtk_widget_get_visible (self->completion_scroller))
    {
      int min_height;

      child_alloc.y = allocation->height - (allocation->height - 50) * self->completion_show_factor;
      gtk_widget_measure (self->completion_scroller, GTK_ORIENTATION_VERTICAL, -1,
                          &min_height, NULL, NULL, NULL);

      child_alloc.height = MAX (min_height, allocation->height - child_alloc.y);

      gtk_widget_size_allocate (self->completion_scroller, &child_alloc, -1, &child_clip);
    }
}

static void
cb_text_view_snapshot (GtkWidget   *widget,
                       GtkSnapshot *snapshot)
{
  gtk_snapshot_push_clip (snapshot,
                          &GRAPHENE_RECT_INIT(
                            0, 0,
                            gtk_widget_get_width (widget), gtk_widget_get_height (widget)),
                          "CbTextView");

  GTK_WIDGET_CLASS (cb_text_view_parent_class)->snapshot (widget, snapshot);

  gtk_snapshot_pop (snapshot);
}

static void
cb_text_view_finalize (GObject *object)
{
  CbTextView *self = CB_TEXT_VIEW (object);

  gtk_widget_unparent (self->box);
  gtk_widget_unparent (self->scrolled_window);
  gtk_widget_unparent (self->completion_scroller);

  cb_animation_destroy (&self->completion_show_animation);

  g_object_unref (self->account);

  g_free (self->completion_word);

  G_OBJECT_CLASS (cb_text_view_parent_class)->finalize (object);
}

static void
cb_text_view_grab_focus (GtkWidget *widget)
{
  CbTextView *self = CB_TEXT_VIEW (widget);

  gtk_widget_grab_focus (self->text_view);
}

static void
text_buffer_cursor_position_changed_cb (GObject    *object,
                                        GParamSpec *pspec,
                                        gpointer    user_data)
{
  CbTextView *self = user_data;
  char *cursor_word;

  cursor_word = cb_text_view_get_cursor_word (self, NULL, NULL);

  if (cursor_word == NULL ||
      cursor_word[0] == '\n')
    {
      cb_text_view_stop_completion (self);
      goto out;
    }

  g_debug ("'%s'", cursor_word);

  if (cursor_word[0] == '@' &&
      strlen (cursor_word) > 1)
    cb_text_view_start_completion (self, cursor_word + 1);
  else
    cb_text_view_stop_completion (self);

out:
  g_free (cursor_word);
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
      switch (e->type)
        {
          case TL_ENT_MENTION:
            gtk_text_buffer_apply_tag_by_name (buffer, TAG_NO_SPELL_CHECK, &entity_start, &entity_end);
            gtk_text_buffer_apply_tag_by_name (buffer, "mention", &entity_start, &entity_end);
            break;
          case TL_ENT_HASHTAG:
            gtk_text_buffer_apply_tag_by_name (buffer, TAG_NO_SPELL_CHECK, &entity_start, &entity_end);
            gtk_text_buffer_apply_tag_by_name (buffer, "hashtag", &entity_start, &entity_end);
            break;
          case TL_ENT_LINK:
            gtk_text_buffer_apply_tag_by_name (buffer, TAG_NO_SPELL_CHECK, &entity_start, &entity_end);
            gtk_text_buffer_apply_tag_by_name (buffer, "link", &entity_start, &entity_end);
            break;

          default: {}

        }
    }

  g_free (entities);
  g_free (text);
  g_signal_emit (self, text_view_signals[SIGNAL_CHANGED], 0);
}

static gboolean
cb_text_view_insert_completion (CbTextView    *self,
                                GtkListBoxRow *row)
{
  const char *screen_name;
  GtkTextBuffer *buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view));
  guint word_start, word_end;
  char *cursor_word = cb_text_view_get_cursor_word (self, &word_start, &word_end);
  GtkTextIter word_start_iter, word_end_iter;
  char *completion;

  if (row == NULL)
    return FALSE;

  screen_name = g_object_get_data (G_OBJECT (row), "row-data");
  g_assert (screen_name != NULL);

  if (cursor_word == NULL)
    return FALSE;

  g_object_freeze_notify (G_OBJECT (buffer));

  gtk_text_buffer_get_iter_at_offset (buffer, &word_start_iter, word_start);
  gtk_text_buffer_get_iter_at_offset (buffer, &word_end_iter, word_end);

  /* Delete cursor word */
  gtk_text_buffer_delete (buffer, &word_start_iter, &word_end_iter);

  /* Now insert completion */
  completion = g_strdup_printf ("@%s ", screen_name);
  gtk_text_buffer_insert (buffer, &word_start_iter, completion, -1);

  /* Cursor gets placed after the completion automatically! */

  g_object_thaw_notify (G_OBJECT (buffer));

  g_free (completion);
  g_free (cursor_word);

  return TRUE;
}

static gboolean
cb_text_view_key_press_event_cb (GtkWidget   *widget,
                                 GdkEventKey *event,
                                 gpointer     user_data)
{
  CbTextView *self = user_data;
  guint keyval;
  GdkModifierType state;

  if (!gdk_event_get_keyval ((GdkEvent *)event, &keyval))
    return GDK_EVENT_PROPAGATE;

  gdk_event_get_state ((GdkEvent *)event, &state);

  /* Control + Return is send for us */
  if (keyval == GDK_KEY_Return &&
      (state & GDK_CONTROL_MASK) > 0)
    {
      g_signal_emit (self, text_view_signals[SIGNAL_SEND], 0);
      return GDK_EVENT_STOP;
    }


  if (!cb_text_view_is_completing (self))
    return GDK_EVENT_PROPAGATE;

  switch (keyval)
    {
      case GDK_KEY_Return:
          {
            GtkListBoxRow *selected_row = gtk_list_box_get_row_at_index (GTK_LIST_BOX (self->completion_listbox),
                                                                         self->selected_row);
            if (cb_text_view_insert_completion (self, selected_row))
              return GDK_EVENT_STOP;
            else
              return GDK_EVENT_PROPAGATE;
          }

      case GDK_KEY_Down:
        cb_text_view_select_completion_row (self, self->selected_row + 1);
        return GDK_EVENT_STOP;

      case GDK_KEY_Up:
        cb_text_view_select_completion_row (self, self->selected_row - 1);
        return GDK_EVENT_STOP;

      default:
          {}
    }

  return GDK_EVENT_PROPAGATE;
}

static void
cb_text_view_class_init (CbTextViewClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_text_view_finalize;

  widget_class->measure = cb_text_view_measure;
  widget_class->size_allocate = cb_text_view_size_allocate;
  widget_class->snapshot = cb_text_view_snapshot;
  widget_class->grab_focus = cb_text_view_grab_focus;

  text_view_signals[SIGNAL_CHANGED] = g_signal_new ("changed",
                                                    G_OBJECT_CLASS_TYPE (object_class),
                                                    G_SIGNAL_RUN_FIRST,
                                                    0,
                                                    NULL, NULL,
                                                    NULL, G_TYPE_NONE, 0);

  text_view_signals[SIGNAL_SEND] = g_signal_new ("send",
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
  gtk_scrolled_window_set_min_content_height (GTK_SCROLLED_WINDOW (self->scrolled_window), 80);
  gtk_widget_set_parent (self->scrolled_window, GTK_WIDGET (self));

  self->text_view = gtk_text_view_new ();
  g_signal_connect (self->text_view, "key-press-event",
                    G_CALLBACK (cb_text_view_key_press_event_cb), self);
  buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (self->text_view));
  g_signal_connect (buffer, "changed", G_CALLBACK (text_buffer_changed_cb), self);
  g_signal_connect (buffer, "notify::cursor-position",
                    G_CALLBACK (text_buffer_cursor_position_changed_cb), self);
  gtk_text_view_set_accepts_tab (GTK_TEXT_VIEW (self->text_view), FALSE);
  gtk_text_view_set_wrap_mode (GTK_TEXT_VIEW (self->text_view), PANGO_WRAP_WORD_CHAR);
  gtk_container_add (GTK_CONTAINER (self->scrolled_window), self->text_view);

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

  cb_animation_init (&self->completion_show_animation, GTK_WIDGET (self), completion_animate_func);
  self->completion_show_factor = 0.0;
  self->completion_scroller = gtk_scrolled_window_new (NULL, NULL);
  gtk_scrolled_window_set_propagate_natural_height (GTK_SCROLLED_WINDOW (self->completion_scroller),
                                                    TRUE);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->completion_scroller), "completion");
  gtk_widget_set_parent (self->completion_scroller, GTK_WIDGET (self));
  self->completion_listbox = gtk_list_box_new ();
  gtk_container_add (GTK_CONTAINER (self->completion_scroller), self->completion_listbox);
  self->completion_model = cb_user_completion_model_new ();
  cb_utils_bind_non_gobject_model (self->completion_listbox,
                                   G_LIST_MODEL (self->completion_model),
                                   create_completion_row_func,
                                   self);
  /* We aren't in completion mode initially */
  gtk_widget_hide (self->completion_scroller);

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
