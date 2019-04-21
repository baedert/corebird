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

#include "CbQuoteTweetWidget.h"
#include "CbTextButton.h"
#include "CbUtils.h"
#include "corebird.h"

G_DEFINE_TYPE (CbQuoteTweetWidget, cb_quote_tweet_widget, GTK_TYPE_WIDGET);



static void
cb_quote_tweet_widget_measure (GtkWidget      *widget,
                               GtkOrientation  orientation,
                               int             for_size,
                               int            *minimum,
                               int            *natural,
                               int            *minimum_baseline,
                               int            *natural_baseline)
{
  CbQuoteTweetWidget *self = (CbQuoteTweetWidget *)widget;
  guint i;

  if (orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      GtkWidget *group[] = { self->top_row_box , self->text_label};

      for (i = 0; i < G_N_ELEMENTS (group); i ++)
        {
          int child_min, child_nat;

          gtk_widget_measure (group[i], orientation, for_size, &child_min, &child_nat, NULL, NULL);

          *minimum = MAX (*minimum, child_min);
          *natural = MAX (*minimum, child_nat);
        }
    }
  else /* VERTICAL */
    {
      GtkWidget *group[] = { self->top_row_box, self->text_label };

      for (i = 0; i < G_N_ELEMENTS (group); i ++)
        {
          int child_min, child_nat;

          gtk_widget_measure (group[i], orientation, for_size, &child_min, &child_nat, NULL, NULL);

          *minimum += child_min;
          *natural += child_nat;
        }
    }
}

static void
cb_quote_tweet_widget_size_allocate (GtkWidget *widget,
                                     int        width,
                                     int        height,
                                     int        baseline)
{
  CbQuoteTweetWidget *self = (CbQuoteTweetWidget *)widget;
  GtkAllocation child_allocation;
  int min;

  child_allocation.x = 0;
  child_allocation.y = 0;

  child_allocation.width = width;
  gtk_widget_measure (self->top_row_box, GTK_ORIENTATION_VERTICAL, child_allocation.width,
                      &min, NULL, NULL, NULL);
  child_allocation.height = min;
  gtk_widget_size_allocate (self->top_row_box, &child_allocation, -1);

  /* Remainder of allocation */
  child_allocation.y = min;
  child_allocation.height = height - min;
  gtk_widget_size_allocate (self->text_label, &child_allocation, -1);
}

static GtkSizeRequestMode
cb_quote_tweet_widget_get_request_mode (GtkWidget *widget)
{
  return GTK_SIZE_REQUEST_HEIGHT_FOR_WIDTH;
}

static void
cb_quote_tweet_widget_finalize (GObject *object)
{
  CbQuoteTweetWidget *self = (CbQuoteTweetWidget *)object;

  g_free (self->screen_name);
  gtk_widget_unparent (self->top_row_box);
  gtk_widget_unparent (self->text_label);

  G_OBJECT_CLASS (cb_quote_tweet_widget_parent_class)->finalize (object);
}

static void
cb_quote_tweet_widget_class_init (CbQuoteTweetWidgetClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_quote_tweet_widget_finalize;

  widget_class->get_request_mode = cb_quote_tweet_widget_get_request_mode;
  widget_class->measure = cb_quote_tweet_widget_measure;
  widget_class->size_allocate = cb_quote_tweet_widget_size_allocate;

  gtk_widget_class_set_css_name (widget_class, "quotetweet");
}

static void
cb_quote_tweet_widget_init (CbQuoteTweetWidget *self)
{
  gtk_widget_set_has_surface ((GtkWidget *)self, FALSE);
}

static gboolean
link_activated_cb (GtkLabel   *label,
                   const char *uri,
                   gpointer    user_data)
{
  CbQuoteTweetWidget *self = user_data;
  GtkWidget *toplevel;

  toplevel = gtk_widget_get_toplevel ((GtkWidget *)self);

  if (!CB_IS_MAIN_WINDOW (toplevel))
    return FALSE;

  return tweet_utils_activate_link (uri, (CbMainWindow *)toplevel);
}

static void
name_button_clicked_cb (GtkButton *source,
                        gpointer   user_data)
{
  CbQuoteTweetWidget *self = user_data;
  CbBundle *bundle;
  GtkWidget *toplevel;

  toplevel = gtk_widget_get_toplevel ((GtkWidget *)self);

  if (!CB_IS_MAIN_WINDOW (toplevel))
    return;

  bundle = cb_bundle_new ();
  cb_bundle_put_int64 (bundle, PROFILE_PAGE_KEY_USER_ID, self->user_id);
  cb_bundle_put_string (bundle, PROFILE_PAGE_KEY_SCREEN_NAME, self->screen_name);

  main_widget_switch_page (MAIN_WIDGET (((CbMainWindow*)toplevel)->main_widget),
                           PAGE_PROFILE,
                           bundle);
}

static void
create_ui (CbQuoteTweetWidget *self)
{
  g_assert (self->top_row_box == NULL);

  self->top_row_box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->top_row_box), "header");
  gtk_widget_set_parent (self->top_row_box, (GtkWidget *)self);

  self->name_button = cb_text_button_new (NULL);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->name_button), "user-name");
  g_signal_connect (self->name_button, "clicked", G_CALLBACK (name_button_clicked_cb), self);
  gtk_widget_set_valign (self->name_button, GTK_ALIGN_BASELINE);
  gtk_container_add (GTK_CONTAINER (self->top_row_box), self->name_button);

  self->screen_name_label = gtk_label_new (NULL);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->screen_name_label),
                               "dim-label");
  gtk_widget_set_hexpand (self->screen_name_label, TRUE);
  gtk_widget_set_halign (self->screen_name_label, GTK_ALIGN_START);
  gtk_widget_set_valign (self->screen_name_label, GTK_ALIGN_BASELINE);
  gtk_container_add (GTK_CONTAINER (self->top_row_box), self->screen_name_label);

  self->time_delta_label = gtk_label_new (NULL);
  gtk_widget_set_valign (self->time_delta_label, GTK_ALIGN_BASELINE);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->time_delta_label), "dim-label");
  gtk_style_context_add_class (gtk_widget_get_style_context (self->time_delta_label), "time-delta");
  gtk_container_add (GTK_CONTAINER (self->top_row_box), self->time_delta_label);

  self->text_label = gtk_label_new (NULL);
  gtk_label_set_xalign (GTK_LABEL (self->text_label), 0.0f);
  gtk_label_set_yalign (GTK_LABEL (self->text_label), 0.0f);
  gtk_label_set_use_markup (GTK_LABEL (self->text_label), TRUE);
  gtk_label_set_track_visited_links (GTK_LABEL (self->text_label), FALSE);
  gtk_label_set_line_wrap (GTK_LABEL (self->text_label), TRUE);
  gtk_label_set_line_wrap_mode (GTK_LABEL (self->text_label), PANGO_WRAP_WORD_CHAR);
  gtk_widget_set_parent (self->text_label, (GtkWidget *)self);
  g_signal_connect (self->text_label, "activate-link", G_CALLBACK (link_activated_cb), self);
}

GtkWidget *
cb_quote_tweet_widget_new (void)
{
  CbQuoteTweetWidget *self = g_object_new (CB_TYPE_QUOTE_TWEET_WIDGET, NULL);

  create_ui (self);

  return (GtkWidget *)self;
}

void
cb_quote_tweet_widget_set_tweet (CbQuoteTweetWidget *self,
                                 const CbMiniTweet  *quote)
{
  char *text;

  g_assert (self->top_row_box != NULL);

  cb_text_button_set_text (self->name_button, quote->author.user_name);

  text = g_strdup_printf ("@%s", quote->author.screen_name);
  gtk_label_set_label (GTK_LABEL (self->screen_name_label), text);
  g_free (text);


  text = cb_text_transform_tweet (quote, settings_get_text_transform_flags (), 0);
  gtk_label_set_label (GTK_LABEL (self->text_label), text);
  g_free (text);

  self->user_id = quote->author.id;
  self->tweet_created_at = quote->created_at;

  g_free (self->screen_name);
  self->screen_name = g_strdup (quote->author.screen_name);
}


void
cb_quote_tweet_widget_update_time (CbQuoteTweetWidget *self,
                                   GDateTime          *now)
{
  GDateTime *cur_time = now != NULL ? g_date_time_ref (now) :
                                      g_date_time_new_now_local ();
  GDateTime *then;
  char *delta_str;

  then = g_date_time_new_from_unix_local (self->tweet_created_at);

  delta_str = cb_utils_get_time_delta (then, cur_time);
  gtk_label_set_label (GTK_LABEL (self->time_delta_label), delta_str);

  g_free (delta_str);
  g_date_time_unref (cur_time);
  g_date_time_unref (then);
}
