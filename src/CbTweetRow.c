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

#include "CbTweetRow.h"
#include "CbUtils.h"
#include "CbQuoteTweetWidget.h"
#include "CbTwitterItem.h"
#include "CbTextButton.h"
#include "corebird.h"

static void cb_twitter_item_iface_init (CbTwitterItemInterface *iface);

G_DEFINE_TYPE_WITH_CODE (CbTweetRow, cb_tweet_row, GTK_TYPE_WIDGET,
                         G_IMPLEMENT_INTERFACE (CB_TYPE_TWITTER_ITEM, cb_twitter_item_iface_init));


static gint64
cb_tweet_row_get_sort_factor (CbTwitterItem *item)
{
  CbTweetRow *self = CB_TWEET_ROW (item);

  return self->tweet->id;
}

static gint64
cb_tweet_row_get_timestamp (CbTwitterItem *item)
{
  CbTweetRow *self = CB_TWEET_ROW (item);

  return self->tweet->source_tweet.created_at;
}

static int
cb_tweet_row_update_time_delta (CbTwitterItem *item,
                                GDateTime     *now)
{
  CbTweetRow *self = CB_TWEET_ROW (item);
  GDateTime *cur_time = now != NULL ? g_date_time_ref (now) :
                                      g_date_time_new_now_local ();
  GDateTime *then;
  char *delta_str;

  then = g_date_time_new_from_unix_local (self->tweet->retweeted_tweet != NULL ?
                                          self->tweet->retweeted_tweet->created_at :
                                          self->tweet->source_tweet.created_at);

  delta_str = cb_utils_get_time_delta (then, cur_time);
  gtk_label_set_label (GTK_LABEL (self->time_delta_label), delta_str);

  if (self->quote_widget != NULL)
    cb_quote_tweet_widget_update_time (CB_QUOTE_TWEET_WIDGET (self->quote_widget), now);

  g_free (delta_str);
  g_date_time_unref (cur_time);
  g_date_time_unref (then);

  return 0;
}

static void
cb_tweet_row_set_last_set_timediff (CbTwitterItem *item,
                                    GTimeSpan      diff)
{
  CbTweetRow *self = CB_TWEET_ROW (item);

  self->last_timediff = diff;
}

static GTimeSpan
cb_tweet_row_get_last_set_timediff (CbTwitterItem *item)
{
  CbTweetRow *self = CB_TWEET_ROW (item);

  return self->last_timediff;
}

static void
cb_twitter_item_iface_init (CbTwitterItemInterface *iface)
{
  iface->get_sort_factor = cb_tweet_row_get_sort_factor;
  iface->get_timestamp = cb_tweet_row_get_timestamp;
  iface->update_time_delta = cb_tweet_row_update_time_delta;
  iface->set_last_set_timediff = cb_tweet_row_set_last_set_timediff;
  iface->get_last_set_timediff = cb_tweet_row_get_last_set_timediff;
}

static void
cb_tweet_row_measure (GtkWidget      *widget,
                      GtkOrientation  orientation,
                      int             for_size,
                      int            *minimum,
                      int            *natural,
                      int            *minimum_baseline,
                      int            *natural_baseline)
{
  CbTweetRow *self = (CbTweetRow *)widget;

  if (orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      int min = 0;
      int top_box_min;
      int rt_min = 0;
      int m;


      gtk_widget_measure (self->avatar_widget, GTK_ORIENTATION_HORIZONTAL, -1,
                          &m, NULL, NULL, NULL);

      min += m;

      gtk_widget_measure (self->top_row_box, GTK_ORIENTATION_HORIZONTAL, -1,
                          &top_box_min, NULL, NULL, NULL);

      if (self->rt_image)
          {
            rt_min = 0;
            gtk_widget_measure (self->rt_image, GTK_ORIENTATION_HORIZONTAL, -1,
                                &m, NULL, NULL, NULL);
            rt_min += m;

            gtk_widget_measure (self->rt_label, GTK_ORIENTATION_HORIZONTAL, -1,
                                &m, NULL, NULL, NULL);

            rt_min += m;
          }

      min += MAX (top_box_min, rt_min);

      *minimum = min;
      *natural = min;
    }
  else /* VERTICAL */
    {
      int min = 0, nat = 0;
      guint i;
      GtkWidget* right_group[] = {
        self->top_row_box,
        self->reply_label,
        self->text_label,
        self->rt_image,
        self->quote_box == NULL ? self->mm_widget : self->quote_box,
      };
      int avatar_width, left_height;

      gtk_widget_measure (self->avatar_widget, GTK_ORIENTATION_HORIZONTAL, -1,
                          &avatar_width, NULL, NULL, NULL);
      gtk_widget_measure (self->avatar_widget, GTK_ORIENTATION_VERTICAL, -1,
                          &left_height, NULL, NULL, NULL);

      for (i = 0; i < G_N_ELEMENTS (right_group); i ++)
        {
          int m, n;

          if (right_group[i])
            {
              gtk_widget_measure (right_group[i], GTK_ORIENTATION_VERTICAL,
                                  MAX (-1, for_size - avatar_width), &m, &n, NULL, NULL);

              min += m;
              nat += n;
            }
        }

      *minimum = MAX (left_height, min);
      *natural = MAX (left_height, nat);
    }
}

static void
cb_tweet_row_size_allocate (GtkWidget *widget,
                            int        width,
                            int        height,
                            int        baseline)
{
  CbTweetRow *self = (CbTweetRow *)widget;
  GtkAllocation child_alloc;
  int min_width, nat_width;
  int min_height, nat_height;
  int avatar_width;
  int top_row_height;

  gtk_widget_measure (self->avatar_widget, GTK_ORIENTATION_HORIZONTAL, -1, &min_width, &nat_width, NULL, NULL);
  gtk_widget_measure (self->avatar_widget, GTK_ORIENTATION_VERTICAL, -1, &min_height, &nat_height, NULL, NULL);
  child_alloc.x = 0;
  child_alloc.y = 0;
  child_alloc.width = min_width;
  child_alloc.height = min_height;
  gtk_widget_size_allocate (self->avatar_widget, &child_alloc, -1);
  avatar_width = min_width;

  gtk_widget_measure (self->top_row_box, GTK_ORIENTATION_HORIZONTAL, -1, &min_width, &nat_width, NULL, NULL);
  gtk_widget_measure (self->top_row_box, GTK_ORIENTATION_VERTICAL, -1, &min_height, &nat_height, NULL, NULL);
  child_alloc.x += child_alloc.width;
  child_alloc.width = MAX (width - child_alloc.width, min_width);
  child_alloc.height = min_height;
  gtk_widget_size_allocate (self->top_row_box, &child_alloc, -1);
  top_row_height = min_height;

  if (self->reply_label != NULL)
    {
      gtk_widget_measure (self->reply_label, GTK_ORIENTATION_HORIZONTAL, -1, &min_width, &nat_width,
                          NULL, NULL);
      child_alloc.width = MAX (min_width, width - avatar_width);
      gtk_widget_measure (self->reply_label, GTK_ORIENTATION_VERTICAL, child_alloc.width,
                          &min_height, &nat_height, NULL, NULL);
      child_alloc.height = nat_height;
      child_alloc.y += top_row_height;
      gtk_widget_size_allocate (self->reply_label, &child_alloc, -1);
    }

  child_alloc.y += min_height;
  gtk_widget_measure (self->text_label, GTK_ORIENTATION_HORIZONTAL, -1, &min_width, &nat_width, NULL, NULL);
  child_alloc.width = MAX (width - avatar_width, min_width);
  gtk_widget_measure (self->text_label, GTK_ORIENTATION_VERTICAL, child_alloc.width,
                      &min_height, &nat_height, NULL, NULL);
  child_alloc.x = avatar_width;
  child_alloc.height = nat_height;
  gtk_widget_size_allocate (self->text_label, &child_alloc, -1);

  if (self->quote_box != NULL)
    {
      gtk_widget_measure (self->quote_box, GTK_ORIENTATION_HORIZONTAL, -1, &min_width, &nat_width,
                          NULL, NULL);
      child_alloc.width = MAX (width - avatar_width, min_width);
      gtk_widget_measure (self->quote_box, GTK_ORIENTATION_VERTICAL, child_alloc.width,
                          &min_height, &nat_height, NULL, NULL);
      child_alloc.x = avatar_width;
      child_alloc.y = child_alloc.y + child_alloc.height;
      child_alloc.height = min_height;
      gtk_widget_size_allocate (self->quote_box, &child_alloc, -1);
    }

  if (self->rt_image != NULL)
    {
      int min_image_height, min_label_height;
      g_assert (self->rt_label != NULL);

      gtk_widget_measure (self->rt_image, GTK_ORIENTATION_VERTICAL, -1, &min_image_height, NULL,
                          NULL, NULL);
      gtk_widget_measure (self->rt_label, GTK_ORIENTATION_VERTICAL, -1, &min_label_height, NULL,
                          NULL, NULL);

      gtk_widget_measure (self->rt_image, GTK_ORIENTATION_HORIZONTAL, -1, &min_width, &nat_width,
                          NULL, NULL);
      child_alloc.x = avatar_width;
      child_alloc.y = child_alloc.y + child_alloc.height;
      child_alloc.height = MAX (min_image_height, min_label_height);
      child_alloc.width = min_width;
      gtk_widget_size_allocate (self->rt_image, &child_alloc, -1);

      gtk_widget_measure (self->rt_label, GTK_ORIENTATION_HORIZONTAL, -1, &min_width, &nat_width,
                          NULL, NULL);
      child_alloc.x += child_alloc.width;
      child_alloc.width = MAX (width - avatar_width, min_width);
      gtk_widget_size_allocate (self->rt_label, &child_alloc, -1);
    }

  if (self->mm_widget != NULL &&
      self->quote_box == NULL)
    {
      gtk_widget_measure (self->mm_widget, GTK_ORIENTATION_HORIZONTAL, -1, &min_width, &nat_width,
                          NULL, NULL);
      child_alloc.width = MAX (width - avatar_width, min_width);
      gtk_widget_measure (self->mm_widget, GTK_ORIENTATION_VERTICAL, child_alloc.width,
                          &min_height, &nat_height, NULL, NULL);
      child_alloc.x = avatar_width;
      child_alloc.y = child_alloc.y + child_alloc.height;
      child_alloc.height = min_height;
      gtk_widget_size_allocate (self->mm_widget, &child_alloc, -1);
    }
}

static void
cb_tweet_row_finalize (GObject *object)
{
  CbTweetRow *self = CB_TWEET_ROW (object);

  g_object_unref (self->tweet);
  gtk_widget_unparent (self->avatar_widget);
  gtk_widget_unparent (self->top_row_box);
  gtk_widget_unparent (self->text_label);

  if (self->reply_label)
    gtk_widget_unparent (self->reply_label);

  if (self->quote_box)
    gtk_widget_unparent (self->quote_box);

  if (self->mm_widget && self->quote_box == NULL)
    gtk_widget_unparent (self->mm_widget);

  if (self->rt_label)
    {
      gtk_widget_unparent (self->rt_label);
      gtk_widget_unparent (self->rt_image);
    }

  G_OBJECT_CLASS (cb_tweet_row_parent_class)->finalize (object);
}

static GtkSizeRequestMode
cb_tweet_row_get_request_mode (GtkWidget *widget)
{
  return GTK_SIZE_REQUEST_HEIGHT_FOR_WIDTH;
}

static void
cb_tweet_row_class_init (CbTweetRowClass *klass)
{
  GObjectClass *object_class = (GObjectClass *)klass;
  GtkWidgetClass *widget_class = (GtkWidgetClass *)klass;

  object_class->finalize = cb_tweet_row_finalize;

  widget_class->measure = cb_tweet_row_measure;
  widget_class->size_allocate = cb_tweet_row_size_allocate;
  widget_class->get_request_mode = cb_tweet_row_get_request_mode;

  gtk_widget_class_set_css_name (widget_class, "row");
}

static void
cb_tweet_row_init (CbTweetRow *self)
{
}

static gboolean
link_activated_cb (GtkLabel   *label,
                   const char *uri,
                   gpointer    user_data)
{
  CbTweetRow *self = user_data;

  gtk_widget_grab_focus (GTK_WIDGET (self));

  return tweet_utils_activate_link (uri, self->main_window);
}

static void
name_button_clicked_cb (GtkButton *source,
                        gpointer   user_data)
{
  CbTweetRow *self = user_data;
  CbBundle *bundle;
  gint64 user_id;
  const char *screen_name;

  if (self->tweet->retweeted_tweet != NULL)
    {
      user_id = self->tweet->retweeted_tweet->author.id;
      screen_name = self->tweet->retweeted_tweet->author.screen_name;
    }
  else
    {
      user_id = self->tweet->source_tweet.author.id;
      screen_name = self->tweet->source_tweet.author.screen_name;
    }

  bundle = cb_bundle_new ();
  cb_bundle_put_int64 (bundle, PROFILE_PAGE_KEY_USER_ID, user_id);
  cb_bundle_put_string (bundle, PROFILE_PAGE_KEY_SCREEN_NAME, screen_name);

  main_widget_switch_page (MAIN_WIDGET (((CbMainWindow*)self->main_window)->main_widget),
                           PAGE_PROFILE,
                           bundle);
}

static void
media_clicked_cb (GtkWidget *source,
                  CbMedia   *media,
                  int        index,
                  double     px,
                  double     py,
                  gpointer   user_data)
{
  CbTweetRow *self = user_data;

  tweet_utils_handle_media_click (self->tweet, self->main_window, index, px, py);
}

static void
tweet_state_changed_cb (CbTweet *tweet,
                        gpointer user_data)
{
  CbTweetRow *self = user_data;

  if ((tweet->state & CB_TWEET_STATE_DELETED) > 0)
    gtk_widget_set_sensitive (GTK_WIDGET (self), FALSE);
}

static void
create_ui (CbTweetRow *self)
{
  self->avatar_widget = (GtkWidget *)avatar_widget_new ();
  gtk_widget_set_parent (self->avatar_widget, (GtkWidget *)self);
  self->top_row_box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->top_row_box), "header");
  gtk_widget_set_parent (self->top_row_box, (GtkWidget *)self);

  self->name_button = cb_text_button_new ("");
  gtk_style_context_add_class (gtk_widget_get_style_context (self->name_button), "user-name");
  gtk_widget_set_valign (self->name_button, GTK_ALIGN_BASELINE);
  g_signal_connect (self->name_button, "clicked", G_CALLBACK (name_button_clicked_cb), self);
  gtk_box_append (GTK_BOX (self->top_row_box), self->name_button);

  self->screen_name_label = gtk_label_new (NULL);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->screen_name_label),
                               "dim-label");
  gtk_widget_set_hexpand (self->screen_name_label, TRUE);
  gtk_widget_set_halign (self->screen_name_label, GTK_ALIGN_START);
  gtk_widget_set_valign (self->screen_name_label, GTK_ALIGN_BASELINE);
  gtk_box_append (GTK_BOX (self->top_row_box), self->screen_name_label);

  self->time_delta_label = gtk_label_new ("");
  gtk_widget_set_valign (self->time_delta_label, GTK_ALIGN_BASELINE);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->time_delta_label), "dim-label");
  gtk_style_context_add_class (gtk_widget_get_style_context (self->time_delta_label), "time-delta");
  gtk_box_append (GTK_BOX (self->top_row_box), self->time_delta_label);

  self->text_label = gtk_label_new (NULL);
  gtk_label_set_xalign (GTK_LABEL (self->text_label), 0.0f);
  gtk_label_set_yalign (GTK_LABEL (self->text_label), 0.0f);
  gtk_label_set_use_markup (GTK_LABEL (self->text_label), TRUE);
  gtk_label_set_wrap (GTK_LABEL (self->text_label), TRUE);
  gtk_label_set_wrap_mode (GTK_LABEL (self->text_label), PANGO_WRAP_WORD_CHAR);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->text_label), "text");
  gtk_widget_set_parent (self->text_label, (GtkWidget *)self);
  g_signal_connect (self->text_label, "activate-link", G_CALLBACK (link_activated_cb), self);

  gtk_style_context_add_class (gtk_widget_get_style_context ((GtkWidget *)self), "tweet");
}

GtkWidget *
cb_tweet_row_new (CbTweet      *tweet,
                  CbMainWindow *main_window)
                  /*Account    *account)*/
{
  CbTweetRow *self  = (CbTweetRow *)g_object_new (CB_TYPE_TWEET_ROW, NULL);

  self->main_window = main_window;
  create_ui (self);
  cb_tweet_row_set_tweet (self, tweet);

  return (GtkWidget *)self;
}

//
// 1) _new will first call create_ui and then _set_tweet.
// 2) Thus, create_ui will only *CREATE* the widgets that always exist,
//    but not set any values on them
// 3) So, set_tweet() will then create and/or destroy widgets that don't apply
//    to the given tweet, as well as fill out the ones that do apply.
//
void
cb_tweet_row_set_tweet (CbTweetRow *self,
                        CbTweet    *tweet)
{
  char *text;

  /* If we get here, create_ui() should've already been called. */
  g_assert (self->avatar_widget != NULL);

  if (tweet == self->tweet)
    return;

  if (self->tweet != NULL)
    {
      g_assert (self->tweet_state_changed_id != 0);
      g_signal_handler_disconnect (self->tweet, self->tweet_state_changed_id);
    }
  g_set_object (&self->tweet, tweet);
  self->tweet_state_changed_id = g_signal_connect (tweet,
                                                   "state-changed",
                                                   G_CALLBACK (tweet_state_changed_cb),
                                                   self);


  /* First, set the values on all the widgets that always exist */
  avatar_widget_set_verified (AVATAR_WIDGET (self->avatar_widget),
                              cb_tweet_is_flag_set (self->tweet, CB_TWEET_STATE_VERIFIED));

  avatar_widget_set_texture ((AvatarWidget *)self->avatar_widget, NULL);

  if (self->tweet->avatar_url != NULL)
    {
      const int scale_factor = gtk_widget_get_scale_factor ((GtkWidget *)self);

      // TODO: Fix this
      if (0 && scale_factor >= 2)
        {
          char *url = g_strdup (self->tweet->avatar_url);
          char *suffix_start = strstr (url, "_normal");

          /* HIdpi, we load the _bigger version.
           * Replace '_normal' at the end with '_bigger'. file ending is either png,jpg or gif */
#ifdef DEBUG
          g_assert (strlen (url) > strlen ("_bigger.png"));
          g_assert (strstr (url, "_normal") != NULL);
#endif
          /* Only replace 'normal' by 'bigger', not the file suffix! Also, not all of them have a file suffix */
          memcpy (suffix_start, "_bigger", strlen ("_bigger"));

          twitter_get_avatar (twitter_get (), cb_tweet_get_user_id (self->tweet), url,
                              (AvatarWidget *)self->avatar_widget, 48 * scale_factor , FALSE, NULL, NULL);

          g_free (url);
        }
      else
        {
          /* Default avatar sizes, 48×48px and url with _normal suffix */
          twitter_get_avatar (twitter_get (), cb_tweet_get_user_id (self->tweet), self->tweet->avatar_url,
                              (AvatarWidget *)self->avatar_widget, 48, FALSE, NULL, NULL);
        }
    }

  cb_text_button_set_text (self->name_button, cb_tweet_get_user_name (self->tweet));

  text = g_strdup_printf ("@%s", cb_tweet_get_screen_name (self->tweet));
  gtk_label_set_label (GTK_LABEL (self->screen_name_label), text);
  g_free (text);

  text = cb_tweet_get_trimmed_text (self->tweet, settings_get_text_transform_flags ());
  gtk_label_set_label (GTK_LABEL (self->text_label), text);
  gtk_widget_set_visible (self->text_label, strlen (text) > 0);
  g_free (text);

  /* Reply label */
  if (self->tweet->source_tweet.reply_id != 0 ||
      (self->tweet->retweeted_tweet != NULL && self->tweet->retweeted_tweet->reply_id != 0))
    {
      GString *str = g_string_new (NULL);

      if (self->tweet->retweeted_tweet != NULL)
        cb_utils_write_reply_text (self->tweet->retweeted_tweet, str);
      else
        cb_utils_write_reply_text (&self->tweet->source_tweet, str);

      if (self->reply_label == NULL)
        {
          self->reply_label = gtk_label_new (NULL);
          gtk_label_set_xalign (GTK_LABEL (self->reply_label), 0.0f);
          gtk_label_set_yalign (GTK_LABEL (self->reply_label), 0.0f);
          gtk_label_set_use_markup (GTK_LABEL (self->reply_label), TRUE);
          gtk_label_set_wrap (GTK_LABEL (self->reply_label), TRUE);
          gtk_label_set_wrap_mode (GTK_LABEL (self->reply_label), PANGO_WRAP_WORD_CHAR);
          gtk_style_context_add_class (gtk_widget_get_style_context (self->reply_label),
                                       "dim-label");
          gtk_style_context_add_class (gtk_widget_get_style_context (self->reply_label),
                                       "invisible-links");
          gtk_widget_set_parent (self->reply_label, (GtkWidget *)self);
          g_signal_connect (self->reply_label, "activate-link", G_CALLBACK (link_activated_cb), self);
        }

      gtk_label_set_label (GTK_LABEL (self->reply_label), str->str);

      g_string_free (str, TRUE);
    }
  else if (self->reply_label != NULL)
    {
      gtk_widget_unparent (self->reply_label);
      self->reply_label = NULL;
    }

  /* Retweet Indicators */
  if (self->tweet->retweeted_tweet != NULL)
    {
      GString *user_str = g_string_new (NULL);

      if (self->rt_image == NULL)
        {
          self->rt_image = gtk_image_new_from_icon_name ("corebird-retweet-symbolic");
          gtk_style_context_add_class (gtk_widget_get_style_context (self->rt_image),
                                       "rt-icon");
          gtk_style_context_add_class (gtk_widget_get_style_context (self->rt_image),
                                       "dim-label");
          gtk_widget_set_parent (self->rt_image, (GtkWidget *)self);

          self->rt_label = gtk_label_new (NULL);

          gtk_label_set_use_markup (GTK_LABEL (self->rt_label), TRUE);
          gtk_style_context_add_class (gtk_widget_get_style_context (self->rt_label),
                                       "rt-label");
          gtk_style_context_add_class (gtk_widget_get_style_context (self->rt_label),
                                       "dim-label");
          gtk_style_context_add_class (gtk_widget_get_style_context (self->rt_label),
                                       "invisible-links");
          gtk_widget_set_halign (self->rt_label, GTK_ALIGN_START);
          gtk_widget_set_parent (self->rt_label, (GtkWidget *)self);

          g_signal_connect (self->rt_label, "activate-link", G_CALLBACK (link_activated_cb), self);
        }

      // TODO(Perf): We create a bunch of GString* here, maybe just unconditionally create one?
      cb_utils_linkify_user_name (&self->tweet->source_tweet.author, user_str);
      gtk_label_set_label (GTK_LABEL (self->rt_label), user_str->str);

      g_string_free (user_str, TRUE);
    }
  else if (self->rt_label != NULL)
    {
      g_assert (self->rt_image != NULL);
      gtk_widget_unparent (self->rt_label);
      gtk_widget_unparent (self->rt_image);
      self->rt_label = NULL;
      self->rt_image = NULL;
    }

  /* Quotes */
  if (self->tweet->quoted_tweet != NULL)
    {
      if (self->quote_box == NULL)
        {
          g_assert (self->quote_widget == NULL);

          self->quote_box = gtk_box_new (GTK_ORIENTATION_VERTICAL, 0);
          self->quote_widget = cb_quote_tweet_widget_new ();
          gtk_box_append (GTK_BOX (self->quote_box), self->quote_widget);

          gtk_style_context_add_class (gtk_widget_get_style_context (self->quote_box), "quote");
          gtk_widget_set_parent (self->quote_box, (GtkWidget *)self);
        }

      cb_quote_tweet_widget_set_tweet (CB_QUOTE_TWEET_WIDGET (self->quote_widget), self->tweet->quoted_tweet);
    }
  else if (self->quote_box != NULL)
    {
      /* mm_widget might be a child of quote_box */
      if (self->mm_widget != NULL && gtk_widget_get_parent (self->mm_widget) == self->quote_box)
        self->mm_widget = NULL;

      gtk_widget_unparent (self->quote_box);
      self->quote_widget = NULL;
      self->quote_box = NULL;
    }

  /* Inline Media */
  if (cb_tweet_has_inline_media (self->tweet))
    {
      int n_medias;
      CbMedia **medias = cb_tweet_get_medias (self->tweet, &n_medias);

      if (self->mm_widget == NULL)
        {
          self->mm_widget = (GtkWidget *)multi_media_widget_new ();

          if (self->quote_box != NULL)
            gtk_box_append (GTK_BOX (self->quote_box), self->mm_widget);
          else
            gtk_widget_set_parent (self->mm_widget, (GtkWidget *)self);

          g_signal_connect (self->mm_widget, "media-clicked", G_CALLBACK (media_clicked_cb), self);
        }
      else
        {
          /* Maybe re-arrange mm_widget */
          g_object_ref ((GObject *)self->mm_widget);

          if (self->quote_box != NULL && gtk_widget_get_parent (self->mm_widget) != self->quote_box)
            {
              g_assert (gtk_widget_get_parent (self->mm_widget) == (GtkWidget *)self);
              gtk_widget_unparent (self->mm_widget);
              gtk_box_append (GTK_BOX (self->quote_box), self->mm_widget);
            }
          else
            {
              /*g_assert (gtk_widget_get_parent (self->mm_widget) == self->quote_box);*/

              /*gtk_container_remove (*/

            }

          g_object_unref ((GObject *)self->mm_widget);
        }

      multi_media_widget_set_all_media ((MultiMediaWidget *)self->mm_widget, medias, n_medias);

      // TODO: Care about NSFW-ness
    }
  else if (self->mm_widget != NULL)
    {
      if (gtk_widget_get_parent (self->mm_widget) == self->quote_box)
        gtk_box_remove (GTK_BOX (self->quote_box), self->mm_widget);
      else
        gtk_widget_unparent (self->mm_widget);

      self->mm_widget = NULL;
    }

  /* New tweet, so update time delta */
  cb_tweet_row_update_time_delta (CB_TWITTER_ITEM (self), NULL);
}

gboolean
cb_tweet_row_shows_actions (CbTweetRow *self)
{
  return FALSE;
}

void
cb_tweet_row_toggle_mode (CbTweetRow *self)
{

}

void
cb_tweet_row_set_read_only (CbTweetRow *self)
{

}

void
cb_tweet_row_set_avatar (CbTweetRow   *self,
                         GdkPaintable *avatar)
{
  if (avatar == NULL)
    return;

  avatar_widget_set_texture (AVATAR_WIDGET (self->avatar_widget), avatar);
}

