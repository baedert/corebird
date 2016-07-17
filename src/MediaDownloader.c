/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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

#include "MediaDownloader.h"
#include <libsoup/soup.h>
#include <gdk/gdk.h>
#include <string.h>

G_DEFINE_TYPE (CbMediaDownloader, cb_media_downloader, G_TYPE_OBJECT);

CbMediaDownloader *
cb_media_downloader_get_default (void)
{
  static CbMediaDownloader *d = NULL;

  if (G_UNLIKELY (d == NULL))
    {
      d = CB_MEDIA_DOWNLOADER (g_object_new (CB_TYPE_MEDIA_DOWNLOADER, NULL));
    }

  return d;
}

static void
mark_invalid (CbMedia *media)
{
  media->invalid = TRUE;
  media->loaded  = TRUE;
  cb_media_loading_finished (media);
}

static const char *
canonicalize_url (const char *url)
{
  int ret = 0;

  if (g_str_has_prefix (url,"http://"))
    ret += 7;
  else if (g_str_has_prefix (url, "https://"))
    ret += 8;

  if (g_str_has_prefix(url + ret, "www."))
    ret += 4;

  return url + ret;
}

static void
load_animation (GInputStream *input_stream,
                CbMedia      *media)
{
  GdkPixbufAnimation *animation;
  GdkPixbuf *frame;
  GError *error = NULL;

  animation = gdk_pixbuf_animation_new_from_stream (input_stream, NULL, &error);
  if (error)
    {
      g_warning ("Couldn't load pixbuf: %s", error->message);
      mark_invalid (media);
      g_error_free (error);
      goto out;
    }
  frame = gdk_pixbuf_animation_get_static_image (animation);

  if (!gdk_pixbuf_animation_is_static_image (animation))
    media->animation = animation; /* Takes ref */
  else
    media->animation = NULL;

  media->surface = gdk_cairo_surface_create_from_pixbuf (frame, 1, NULL);

  if (media->surface == NULL)
    {
      g_warning ("Surface of %p is null", media);
      mark_invalid (media);
      goto out;
    }

  media->width   = gdk_pixbuf_get_width (frame);
  media->height  = gdk_pixbuf_get_height (frame);
  media->loaded  = TRUE;
  media->invalid = FALSE;

out:
  if (media->animation == NULL)
    g_object_unref (animation);

  cb_media_loading_finished (media);
}

static void
cb_media_downloader_get_instagram_url (CbMediaDownloader *downloader,
                                       CbMedia           *media)
{
  SoupMessage *msg = soup_message_new ("GET", media->url);
  GRegex      *medium_regex;
  GRegex      *url_regex;
  GMatchInfo  *match_info;

  soup_session_send_message (downloader->soup_session, msg);
  if (msg->status_code != SOUP_STATUS_OK)
    {
      g_object_unref (msg);
      media->url = NULL;
      return;
    }

  medium_regex = g_regex_new ("<media name=\"medium\" content=\"video\" />", 0, 0, NULL);
  g_regex_match (medium_regex, (const char *)msg->response_body->data, 0, &match_info);

  if (g_match_info_get_match_count (match_info) > 0)
    {
      g_match_info_free (match_info);
      g_regex_unref (url_regex);

      /* Video! */
      url_regex = g_regex_new ("<meta property=\"og:video\" content=\"(.*?)\"", 0, 0, NULL);
      g_regex_match (url_regex, (const char *)msg->response_body->data, 0, &match_info);
      media->url = g_match_info_fetch (match_info, 1);
      g_regex_unref (url_regex);
    }

  g_match_info_free (match_info);

  url_regex = g_regex_new ("<meta property=\"og:image\" content=\"(.*?)\"", 0, 0, NULL);
  g_regex_match (url_regex, (const char*)msg->response_body->data, 0, &match_info);

  media->thumb_url = g_match_info_fetch (match_info, 1);

  g_regex_unref (url_regex);
  g_regex_unref (medium_regex);
  g_match_info_free (match_info);
  g_object_unref (msg);
}

static void
cb_media_downloader_load_twitter_video (CbMediaDownloader *downloader,
                                        CbMedia           *media)
{
  SoupMessage *msg = soup_message_new ("GET", media->url);
  GRegex      *regex;
  GMatchInfo  *match_info;

  soup_session_send_message (downloader->soup_session, msg);
  if (msg->status_code != SOUP_STATUS_OK)
    {
      mark_invalid (media);
      g_object_unref (msg);
      return;
    }

  regex = g_regex_new ("<img src=\"(.*?)\" class=\"animated-gif-thumbnail", 0, 0, NULL);
  g_regex_match (regex, (const char *)msg->response_body->data, 0, &match_info);

  if (g_match_info_get_match_count (match_info) > 0)
    {
      g_assert (media->type == CB_MEDIA_TYPE_ANIMATED_GIF);
      media->url = g_match_info_fetch (match_info, 1);

      g_regex_unref (regex);
      g_match_info_free (match_info);
      g_object_unref (msg);
      return;
    }
  else
    {
      g_regex_unref (regex);
      g_match_info_free (match_info);

      regex = g_regex_new ("<source video-src=\"(.*?)\"", 0, 0, NULL);
      g_regex_match (regex, (const char *)msg->response_body->data, 0, &match_info);
      media->url = g_match_info_fetch (match_info, 1);
      media->type = CB_MEDIA_TYPE_TWITTER_VIDEO;
    }

  g_regex_unref (regex);
  g_match_info_free (match_info);

  regex = g_regex_new ("poster=\"(.*?)\"", 0, 0, NULL);
  g_regex_match (regex, (const char *)msg->response_body->data, 0, &match_info);
  media->thumb_url = g_match_info_fetch (match_info, 1);

  g_regex_unref (regex);
  g_match_info_free (match_info);
  g_object_unref (msg);
}

static void
cb_media_downloader_load_real_url (CbMediaDownloader *downloader,
                                   CbMedia           *media,
                                   const char        *regex_str1,
                                   int                match_index1)
{
  SoupMessage *msg = soup_message_new ("GET", media->url);
  GRegex *regex;
  GMatchInfo *match_info;

  soup_session_send_message (downloader->soup_session, msg);
  if (msg->status_code != SOUP_STATUS_OK)
    {
      /* Will mark it invalid later */
      media->url = NULL;
      g_object_unref (msg);
      return;
    }

  regex = g_regex_new (regex_str1, 0, 0, NULL);
  g_regex_match (regex, (const char *)msg->response_body->data, 0, &match_info);
  media->thumb_url = g_match_info_fetch (match_info, match_index1);

  g_regex_unref (regex);
  g_match_info_free (match_info);
  g_object_unref (msg);
}

static void
update_media_progress (SoupMessage *msg,
                       SoupBuffer  *chunk,
                       gpointer     user_data)
{
  CbMedia *media = user_data;

  if (msg->response_headers == NULL) return;

  int chunk_percent = MAX (chunk->length /soup_message_headers_get_content_length (msg->response_headers),
                           1);

  cb_media_update_progress (media, media->percent_loaded + chunk_percent);
}

static void
cb_media_downloader_load_threaded (CbMediaDownloader *downloader,
                                   CbMedia           *media)
{
  const char *url;
  SoupMessage *msg;
  GInputStream *input_stream;

  g_return_if_fail (CB_IS_MEDIA_DOWNLOADER (downloader));
  g_return_if_fail (CB_IS_MEDIA (media));
  g_return_if_fail (media->url != NULL);


  url = canonicalize_url (media->url);

  /* For these, we first need to download some html and get the real
     URL of the image we want to display */
  if (g_str_has_prefix (url, "instagr.am") ||
      g_str_has_prefix (url, "instagram.com/p/"))
    {
      cb_media_downloader_get_instagram_url (downloader, media);
    }
  else if (g_str_has_prefix (url, "ow.ly/i/") ||
           g_str_has_prefix (url, "flickr.com/photos/") ||
           g_str_has_prefix (url, "flic.kr/p/") ||
           g_str_has_prefix (url, "flic.kr/s/") ||
           g_str_has_prefix (url, "vine.co/v/"))
    {
      cb_media_downloader_load_real_url (downloader, media,
                                         "<meta property=\"og:image\" content=\"(.*?)\"", 1);
    }
  else if (g_str_has_prefix (url, "twitpic.com/"))
    {
      cb_media_downloader_load_real_url (downloader, media,
                                         "<meta name=\"twitter:image\" value=\"(.*?)\"", 1);
    }
  else if (g_str_has_suffix (url, "/photo/1"))
    {
      cb_media_downloader_load_twitter_video (downloader, media);
    }
  else if (g_str_has_prefix (url, "d.pr/i/"))
    {
      cb_media_downloader_load_real_url (downloader, media,
                                         "<meta property=\"og:image\"\\s+content=\"(.*?)\"", 1);
    }

  if (media->url == NULL)
    {
      g_warning ("Media is invalid.");
      mark_invalid (media);
      return;
    }


  msg = soup_message_new ("GET", media->thumb_url ? media->thumb_url : media->url);
  g_signal_connect (msg, "got-chunk", G_CALLBACK (update_media_progress), media);
  soup_session_send_message (downloader->soup_session, msg);

  if (msg->status_code != SOUP_STATUS_OK)
    {
      g_debug ("Request on '%s' returned status '%s'",
               media->thumb_url,
               soup_status_get_phrase (msg->status_code));

      mark_invalid (media);
      g_object_unref (msg);
      return;
    }

  input_stream = g_memory_input_stream_new_from_data (msg->response_body->data,
                                                      msg->response_body->length,
                                                      NULL);

  load_animation (input_stream, media);
  g_input_stream_close (input_stream, NULL, NULL);
  g_object_unref (input_stream);
  g_object_unref (msg);
}

void
load_in_thread (GTask        *task,
                gpointer      source_object,
                gpointer      task_data,
                GCancellable *cancellable)
{
  CbMediaDownloader *downloader = source_object;
  CbMedia *media = task_data;

  cb_media_downloader_load_threaded (downloader, media);

  g_task_return_boolean (task, TRUE);
}

void
cb_media_downloader_load_async (CbMediaDownloader   *downloader,
                                CbMedia             *media,
                                GAsyncReadyCallback  callback,
                                gpointer             user_data)
{
  GTask *task;

  g_return_if_fail (CB_IS_MEDIA_DOWNLOADER (downloader));
  g_return_if_fail (CB_IS_MEDIA (media));

  task = g_task_new (downloader, NULL, callback, user_data);
  g_task_set_task_data (task, media, NULL);

  g_task_run_in_thread (task, load_in_thread);
  g_object_unref (task);
}

gboolean
cb_media_downloader_load_finish (CbMediaDownloader  *downloader,
                                 GAsyncResult       *result,
                                 GError            **error)
{
  g_return_val_if_fail (g_task_is_valid (result, downloader), FALSE);

  return g_task_propagate_boolean (G_TASK (result), error);
}

void
cb_media_downloader_load_all (CbMediaDownloader  *downloader,
                              CbMiniTweet        *t)
{
  guint i;
  g_return_if_fail (CB_IS_MEDIA_DOWNLOADER (downloader));

  for (i = 0; i < t->n_medias; i ++)
    cb_media_downloader_load_async (downloader, t->medias[i], NULL, NULL);
}

gboolean
is_media_candidate (const char *url)
{
  url = canonicalize_url (url);

  return g_str_has_prefix (url, "instagr.am") ||
         g_str_has_prefix (url, "instagram.com/p/") ||
        (g_str_has_prefix (url, "i.imgur.com") && !g_str_has_suffix (url, "gifv")) ||
         g_str_has_prefix (url, "d.pr/i/") ||
         g_str_has_prefix (url, "ow.ly/i/") ||
         g_str_has_prefix (url, "flickr.com/photos/") ||
         g_str_has_prefix (url, "flic.kr/p/") ||
         g_str_has_prefix (url, "flic.kr/s/") ||
#ifdef VIDEO
         g_str_has_prefix (url, "vine.co/v/") ||
         g_str_has_prefix (url, "/photo/1/") ||
         g_str_has_prefix (url, "video.twimg.com/ext_tw_video") ||
#endif
         g_str_has_prefix (url, "pbs.twimg.com/media/") ||
         g_str_has_prefix (url, "twitpic.com")
   ;

}

static void
cb_media_downloader_init (CbMediaDownloader *downloader)
{
  downloader->soup_session = soup_session_new ();
}

static void
cb_media_downloader_class_init (CbMediaDownloaderClass *class)
{
}
