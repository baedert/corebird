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

#include "CbMediaVideoWidget.h"
#include "CbGtkCompat.h"


G_DEFINE_TYPE(CbMediaVideoWidget, cb_media_video_widget, GTK_TYPE_STACK)

static void
cb_media_video_widget_show_error (CbMediaVideoWidget *self,
                                  const char         *error_message)
{
  gtk_stack_set_visible_child (GTK_STACK (self), self->error_label);
  gtk_label_set_label (GTK_LABEL (self->error_label), error_message);
}

static void
cb_media_video_widget_start_video (CbMediaVideoWidget *self)
{
#ifdef VIDEO
  g_assert (self->media_url != NULL);
  g_object_set (self->src, "uri", self->media_url, NULL);
  /* Will set to PLAYING once we get the ASYNC_DONE message */
  gst_element_set_state (self->src, GST_STATE_PAUSED);
#endif
}

static void
cb_media_video_widget_stop_video (CbMediaVideoWidget *self)
{
#ifdef VIDEO
  gst_element_set_state (self->src, GST_STATE_NULL);
#endif

  if (self->video_progress_id != 0)
    {
      g_source_remove (self->video_progress_id);
      self->video_progress_id = 0;
    }

  g_cancellable_cancel (self->cancellable);
}

static void
soup_message_received_cb (SoupSession *session,
                          SoupMessage *message,
                          gpointer     user_data)
{
  CbMediaVideoWidget *self = user_data;
  GRegex *regex;
  GMatchInfo *match_info;
  char *match = NULL;

  if (message->status_code != SOUP_STATUS_OK)
    {
      if (message->status_code != SOUP_STATUS_CANCELLED)
        {
          char *msg = g_strdup_printf ("%u %s", message->status_code,
                                       soup_status_get_phrase (message->status_code));

          cb_media_video_widget_show_error (self, msg);

          g_free (msg);
        }

      return;
    }

  regex = g_regex_new ("<source video-src=\"(.*?)\" type=\"video/mp4\"", 0, 0, NULL);
  g_regex_match (regex, (const gchar *)message->response_body->data, 0, &match_info);
  match = g_match_info_fetch (match_info, 1);
  g_debug ("Real url: %s", match);

  if (match == NULL)
    {
      cb_media_video_widget_show_error (self, "Error: Could not get real URL");
      goto out;
    }
  else
    {
      self->media_url = match;
      cb_media_video_widget_start_video (self);
    }

out:
  g_regex_unref (regex);
}

static void
cancelled_cb (GCancellable *cancellable,
              gpointer      user_data)
{
  CbMediaVideoWidget *self = user_data;

  if (self->session != NULL &&
      self->message != NULL)
    {
      soup_session_cancel_message (self->session, self->message, SOUP_STATUS_CANCELLED);
    }
}

static void
fetch_real_url (CbMediaVideoWidget *self,
                const char         *first_url)
{
  self->session = soup_session_new ();
  self->message = soup_message_new ("GET", first_url);

  g_signal_connect (self->cancellable, "cancelled", G_CALLBACK (cancelled_cb), self);

  soup_session_queue_message (self->session, self->message, soup_message_received_cb, self);
}

static gboolean
video_progress_timeout_cb (gpointer user_data)
{
  CbMediaVideoWidget *self = user_data;
  gint64 duration_ns;
  gint64 position_ns;

#ifdef VIDEO
  gst_element_query_duration (self->src, GST_FORMAT_TIME, &duration_ns);
  if (duration_ns > 0)
    {
      double fraction;

      gst_element_query_position (self->src, GST_FORMAT_TIME, &position_ns);
      fraction = (double)position_ns / (double)duration_ns;
      gtk_progress_bar_set_fraction (GTK_PROGRESS_BAR (self->video_progress), fraction);
    }
#endif

  return G_SOURCE_CONTINUE;
}

#ifdef VIDEO
static gboolean
watch_cb (GstBus     *bus,
          GstMessage *message,
          gpointer    user_data)
{
  CbMediaVideoWidget *self = user_data;

  switch (message->type)
    {
      case GST_MESSAGE_BUFFERING:
        {
          int percent;
          CbSurfaceProgress *sp = CB_SURFACE_PROGRESS (self->surface_progress);

          gst_message_parse_buffering (message, &percent);
          cb_surface_progress_set_progress (sp, MAX (cb_surface_progress_get_progress (sp),
                                                     percent / 100.0));
          g_debug ("Buffering: %d", percent);
        }
      break;

      case GST_MESSAGE_EOS:
        {
          /* Loop */
          gst_element_seek (self->src,
                            1.0, GST_FORMAT_TIME,
                            GST_SEEK_FLAG_FLUSH,
                            GST_SEEK_TYPE_SET, 0,
                            GST_SEEK_TYPE_NONE, GST_CLOCK_TIME_NONE);
        }
      break;

      case GST_MESSAGE_ASYNC_DONE:
        {
          g_debug ("ASYNC DONE");
          gtk_stack_set_visible_child_name (GTK_STACK (self), "video");
          gst_element_set_state (self->src, GST_STATE_PLAYING);
          if (self->video_progress_id == 0)
            self->video_progress_id = g_timeout_add (50, video_progress_timeout_cb, self);
        }
      break;

      case GST_MESSAGE_ERROR:
        {
          GError *error;
          char *msg;

          gst_message_parse_error (message, &error, &msg);
          g_critical ("%s", msg);
          cb_media_video_widget_show_error (self, msg);
          g_free (msg);
          g_error_free (error);
        }
      break;

      default: {}
    }

  return TRUE;
}
#endif

static void
cb_media_video_widget_destroy (GtkWidget *widget)
{
  CbMediaVideoWidget *self = CB_MEDIA_VIDEO_WIDGET (widget);

  cb_media_video_widget_stop_video (self);
  GTK_WIDGET_CLASS (cb_media_video_widget_parent_class)->destroy (widget);
}

static gboolean
cb_media_video_widget_key_press_event (GtkWidget   *widget,
                                       GdkEventKey *event)
{
  CbMediaVideoWidget *self = CB_MEDIA_VIDEO_WIDGET (widget);

  cb_media_video_widget_stop_video (self);

  return GDK_EVENT_PROPAGATE;
}

static void
cb_media_video_widget_finalize (GObject *object)
{
  CbMediaVideoWidget *self = CB_MEDIA_VIDEO_WIDGET (object);

  g_object_unref (self->cancellable);

  if (self->session)
    g_object_unref (self->session);

  if (self->message)
    g_object_unref (self->message);

  g_free (self->media_url);

  G_OBJECT_CLASS (cb_media_video_widget_parent_class)->finalize (object);
}

static void
cb_media_video_widget_init (CbMediaVideoWidget *self)
{
#ifdef VIDEO
  GstBus *bus;
#endif
  GtkWidget *box;
  guint flags;

  self->error_label = gtk_label_new ("");
  gtk_label_set_line_wrap (GTK_LABEL (self->error_label), TRUE);
  gtk_label_set_selectable (GTK_LABEL (self->error_label), TRUE);
  gtk_widget_set_halign (self->error_label, GTK_ALIGN_CENTER);
  gtk_widget_set_valign (self->error_label, GTK_ALIGN_CENTER);
  gtk_widget_show (self->error_label);
  self->video_progress = gtk_progress_bar_new ();
  gtk_widget_show (self->video_progress);
  self->surface_progress = cb_surface_progress_new ();
  gtk_widget_show (self->surface_progress);

  gtk_container_add (GTK_CONTAINER (self), self->surface_progress);
  gtk_container_add (GTK_CONTAINER (self), self->error_label);

  self->cancellable = g_cancellable_new ();


  gtk_stack_set_visible_child (GTK_STACK (self),
                               self->surface_progress);

  /* Init gstreamer stuff */
#ifdef VIDEO
  self->src = gst_element_factory_make ("playbin", "video");
  self->sink = gst_element_factory_make ("gtksink", "gtksink");

  if (self->sink == NULL)
    {
      cb_media_video_widget_show_error (self, "Could not create gtksink. Need gst-plugins-bad >= 1.6");
      return;
    }
  g_object_get (self->sink, "widget", &self->area, NULL);
  gtk_widget_set_hexpand (self->area, TRUE);
  gtk_widget_set_vexpand (self->area, TRUE);

  /* We will switch to the "video" child later after getting
     an ASYNC_DONE message from gstreamer */

  bus = gst_element_get_bus (self->src);
  gst_bus_add_watch (bus, watch_cb, self);

  g_object_set (self->src,
                "video-sink", self->sink,
                "ring-buffer-max-size", (10 * 1024 * 1024),
                NULL);
  g_object_get (self->src, "flags", &flags, NULL);
  g_object_set (self->src, "flags", flags | (1 << 7) /* DOWNLOAD */, NULL);
#endif


  box = gtk_box_new (GTK_ORIENTATION_VERTICAL, 0);
  gtk_container_add (GTK_CONTAINER (box), self->area);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->video_progress),
                               "embedded-progress");
  gtk_container_add (GTK_CONTAINER (box), self->video_progress);

  gtk_stack_add_named (GTK_STACK (self), box, "video");
}

static void
cb_media_video_widget_class_init (CbMediaVideoWidgetClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_media_video_widget_finalize;

  widget_class->destroy = cb_media_video_widget_destroy;
  widget_class->key_press_event = cb_media_video_widget_key_press_event;
}

CbMediaVideoWidget *
cb_media_video_widget_new (CbMedia *media)
{
  int h;
  int width;
  int height;
  int monitor_width;
  int monitor_height;
  double scale, scale_x = 1.0, scale_y = 1.0;

  CbMediaVideoWidget *self = CB_MEDIA_VIDEO_WIDGET (g_object_new (CB_TYPE_MEDIA_VIDEO_WIDGET, NULL));

  g_return_val_if_fail (CB_IS_MEDIA (media), self);
  g_return_val_if_fail (media->surface != NULL, self);
  g_return_val_if_fail (media->url != NULL, self);

  cb_surface_progress_set_surface (CB_SURFACE_PROGRESS (self->surface_progress),
                                   media->surface);

  gtk_widget_measure (self->video_progress, GTK_ORIENTATION_VERTICAL, -1,
                      &h, NULL, NULL, NULL);

  /* TODO: Replace GdkScreen usage */

  width = cairo_image_surface_get_width (media->surface);
  height = cairo_image_surface_get_height (media->surface) + h;

  monitor_width = 800;
  monitor_height = 600;

  if (width > monitor_width * 0.9)
    scale_x = (monitor_width * 0.9) / width;

  if (height > monitor_height * 0.9)
    scale_y = (monitor_height * 0.9) / height;

  scale = MIN (scale_x, scale_y);

  gtk_widget_set_size_request (GTK_WIDGET (self),
                               (int)(width * scale),
                               (int)(height * scale));

  switch (media->type)
    {
      case CB_MEDIA_TYPE_TWITTER_VIDEO:
      case CB_MEDIA_TYPE_INSTAGRAM_VIDEO:
        self->media_url = g_strdup (media->url);
        break;

      case CB_MEDIA_TYPE_ANIMATED_GIF:
        fetch_real_url (self, media->url);
        break;

      default:
        g_warn_if_reached ();
    }

  return self;
}

void
cb_media_video_widget_start (CbMediaVideoWidget *self)
{
  g_assert (gtk_widget_get_parent (GTK_WIDGET (self)) != NULL);

  /* We can only do this now, since the GtkDrawingArea from gstreamer needs to have a
   * parent set when the video starts, otherwise it will create its own GtkWindow. */
  if (self->media_url != NULL)
    cb_media_video_widget_start_video (self);
  else
    g_debug ("Retrieving real URL first...");
}
