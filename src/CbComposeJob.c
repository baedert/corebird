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

#include <string.h>
#include "CbComposeJob.h"
#include "CbUtils.h"

G_DEFINE_TYPE (CbComposeJob, cb_compose_job, G_TYPE_OBJECT);

#define MAX_UPLOADS         4
#define MEDIA_SEGMENT_BYTES (256 * 1024)  // 256kb segments

static void do_send (CbComposeJob *self);

enum {
  IMAGE_UPLOAD_PROGRESS,
  IMAGE_UPLOAD_FINISHED,
  LAST_SIGNAL
};
static guint compose_job_signals[LAST_SIGNAL] = { 0 };

static void
image_upload_free (MediaUpload *u)
{
  g_clear_pointer (&u->filename, g_free);
  g_clear_pointer (&u->contents, g_free);
  g_clear_object (&u->cancellable);
}

static void
fail_upload (MediaUpload  *upload,
             const GError *error)
{
  if (error->code != G_IO_ERROR_CANCELLED &&
      upload->filename != NULL)
    {
      g_signal_emit (upload->job,
                     compose_job_signals[IMAGE_UPLOAD_FINISHED], 0,
                     upload->filename, error->message);
    }

  upload->status = MEDIA_FAILED;
}

static guint
cb_compose_job_get_n_unfinished_uploads (CbComposeJob *self)
{
  guint i;
  guint n = 0;

  for (i = 0; i < MAX_UPLOADS; i ++)
    {
      const MediaUpload *upload = &self->uploads[i];

      if (upload->filename != NULL &&
          upload->status != MEDIA_UPLOADED &&
          upload->status != MEDIA_FAILED)
        n ++;
    }

  return n;
}

/* If we call send_async but we still have to wait for some uploads to complete, we instead do nothing
 * and for every upload that is finished, we check whether it's the last one to finish.
 * If so, we also make sure we set self->send_task, which indicates that a premature send() has been
 * scheduled. */
static void
maybe_do_send (CbComposeJob *self)
{
  if (self->send_task != NULL)
    {
      g_assert (self->send_call != NULL);

      if (cb_compose_job_get_n_unfinished_uploads (self) == 0)
        {
          /* Obviously, this was the last image to be uploaded before we could start
           * sending the actual tweet, so do that now... */
          do_send (self);
        }
    }
}

static char *
build_image_id_string (CbComposeJob *self)
{
  const MediaUpload *uploads[MAX_UPLOADS];
  guint n_uploads = 0;
  guint n_unfinished_uploads = 0;
  GString *str;
  guint i;

  for (i = 0; i < MAX_UPLOADS; i ++)
    {
      const MediaUpload *upload = &self->uploads[i];

      if (upload->status != MEDIA_UPLOADED)
        continue;

      uploads[n_uploads] = upload;
      n_uploads ++;

      if (upload->id == 0)
        n_unfinished_uploads ++;
    }

  g_assert (n_unfinished_uploads == 0);
  g_assert (n_uploads <= MAX_UPLOADS);

  if (n_uploads == 0)
    return NULL;

  str = g_string_new (NULL);

  /* n_uploads is at least 1 at this point */
  g_string_append_printf (str, "%" G_GINT64_FORMAT, uploads[0]->id);

  for (i = 1; i < n_uploads; i ++)
    {
      g_assert (uploads[i]->id != 0);

      g_string_append_printf (str, ",%" G_GINT64_FORMAT, uploads[i]->id);
    }

  return g_string_free (str, FALSE);
}

static void
cancelled_cb (GCancellable *cancellable,
              gpointer      user_data)
{
  CbComposeJob *self = user_data;

  cb_compose_job_abort_all_uploads (self);
}

static void
cb_compose_job_finalize (GObject *object)
{
  CbComposeJob *self = CB_COMPOSE_JOB (object);
  guint i;

  for (i = 0; i < MAX_UPLOADS; i ++)
    {
      MediaUpload *upload = &self->uploads[i];

      if (upload->filename == NULL)
        continue;

      image_upload_free (upload);
    }

  g_clear_object (&self->account_proxy);
  g_clear_object (&self->upload_proxy);
  g_clear_object (&self->cancellable);
  g_clear_object (&self->send_call);

  g_free (self->text);

  G_OBJECT_CLASS (cb_compose_job_parent_class)->finalize (object);
}

static void
cb_compose_job_class_init (CbComposeJobClass *class)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (class);

  gobject_class->finalize = cb_compose_job_finalize;

  compose_job_signals[IMAGE_UPLOAD_PROGRESS] = g_signal_new ("image-upload-progress",
                                                             G_OBJECT_CLASS_TYPE (gobject_class),
                                                             G_SIGNAL_RUN_FIRST,
                                                             0,
                                                             NULL, NULL,
                                                             NULL, G_TYPE_NONE,
                                                             2, G_TYPE_STRING, G_TYPE_DOUBLE);

  compose_job_signals[IMAGE_UPLOAD_FINISHED] = g_signal_new ("image-upload-finished",
                                                             G_OBJECT_CLASS_TYPE (gobject_class),
                                                             G_SIGNAL_RUN_FIRST,
                                                             0,
                                                             NULL, NULL,
                                                             NULL, G_TYPE_NONE,
                                                             2, G_TYPE_STRING, G_TYPE_STRING);
}

static void
cb_compose_job_init (CbComposeJob *self)
{
}

CbComposeJob *
cb_compose_job_new (RestProxy    *account_proxy,
                    RestProxy    *upload_proxy,
                    GCancellable *cancellable)
{
  CbComposeJob *self = CB_COMPOSE_JOB (g_object_new (CB_TYPE_COMPOSE_JOB, NULL));

  g_set_object (&self->account_proxy, account_proxy);
  g_set_object (&self->upload_proxy, upload_proxy);
  g_set_object (&self->cancellable, cancellable);

  g_signal_connect (cancellable, "cancelled", G_CALLBACK (cancelled_cb), self);

  return self;
}

static void
media_finalized (GObject      *object,
                 GAsyncResult *result,
                 gpointer      user_data)
{
  RestProxyCall *call = REST_PROXY_CALL (object);
  MediaUpload *upload = user_data;
  GError *error = NULL;

  /* Aborted? */
  if (upload->filename == NULL)
    return;

  rest_proxy_call_invoke_finish (call, result, &error);
  if (error != NULL)
    {
      g_warning ("%s: %s. Payload:\n%s", __FUNCTION__, error->message,
                 rest_proxy_call_get_payload (call));

      fail_upload (upload, error);
      return;
    }

  {
    JsonParser *parser = json_parser_new ();
    GError *json_error = NULL;
    JsonObject *root_object;

    json_parser_load_from_data (parser, rest_proxy_call_get_payload (call), -1, &json_error);
    if (error != NULL)
      {
        g_warning ("%s: %s. Payload:\n%s", __FUNCTION__, json_error->message,
                   rest_proxy_call_get_payload (call));

        fail_upload (upload, json_error);
        g_object_unref (parser);
        return;
      }

    root_object = json_node_get_object (json_parser_get_root (parser));

    if (json_object_has_member (root_object, "processing_info"))
      {
        /* We need to wait for this one... */
        upload->status = MEDIA_PENDING;

        g_error ("%s: %s", __FUNCTION__, rest_proxy_call_get_payload (call));
      }
    else
      {
        upload->status = MEDIA_UPLOADED;
      }

    g_object_unref (parser);
  }

  /* If the FINALIZE call didn't fail, we are REALLY done with this media. */
  maybe_do_send (upload->job);
}

static void append_done (GObject      *object,
                         GAsyncResult *result,
                         gpointer      user_data);
static void
upload_next_media_segment (RestProxy   *proxy,
                           MediaUpload *upload)
{
  RestProxyCall *segment_call = rest_proxy_new_call (proxy);
  RestParam *data_param;
  gsize n_bytes;

  /* Aborted? */
  if (upload->filename == NULL)
    return;

  rest_proxy_call_set_function (segment_call, "1.1/media/upload.json");
  rest_proxy_call_set_method (segment_call, "POST");
  rest_proxy_call_add_param (segment_call, "command", "APPEND");
  rest_proxy_call_take_param (segment_call, "media_id", g_strdup_printf ("%" G_GINT64_FORMAT,
                                                                         upload->id));

  /* All segments have full size except for the last one. Maybe. */
  if (upload->n_uploaded_segments == upload->n_segments - 1)
    n_bytes = upload->contents_length - ((upload->n_segments - 1) * MEDIA_SEGMENT_BYTES);
  else
    n_bytes = MEDIA_SEGMENT_BYTES;

  data_param = rest_param_new_full ("media",
                                    REST_MEMORY_STATIC,
                                    upload->contents + (upload->n_uploaded_segments * MEDIA_SEGMENT_BYTES),
                                    n_bytes,
                                    "multipart/form-data",
                                    upload->filename);
  rest_proxy_call_add_param_full (segment_call, data_param);
  rest_proxy_call_take_param (segment_call, "segment_index",
                              g_strdup_printf ("%u", upload->n_uploaded_segments));

  rest_proxy_call_invoke_async (segment_call, upload->cancellable, append_done, upload);
}

static void
append_done (GObject      *object,
             GAsyncResult *result,
             gpointer      user_data)
{
  RestProxyCall *call = REST_PROXY_CALL (object);
  MediaUpload *upload = user_data;
  GError *error = NULL;
  goffset payload_length = rest_proxy_call_get_payload_length (call);
  double percent;

  rest_proxy_call_invoke_finish (call, result, &error);
  if (error != NULL)
    {
      if (error->code != G_IO_ERROR_CANCELLED)
        g_warning ("%s: %s. Payload: \n%s", __FUNCTION__, error->message,
                   rest_proxy_call_get_payload (call));

      fail_upload (upload, error);
      return;
    }

  /* Aborted? */
  if (upload->filename == NULL)
    return;

  /* Successfull calls don't return anything */
  if (payload_length > 0)
    {
      GError *error;
      g_warning ("%s: Expected media segment APPEND call to return no payload, but it returned:\n%s",
                 __FUNCTION__,
                 rest_proxy_call_get_payload (call));

      error = g_error_new_literal (0, 0, "APPEND failed");

      fail_upload (upload, error);
      g_error_free (error);
      return;
    }

  /* SUCCESS! */
  upload->n_uploaded_segments ++;
  percent = (double)upload->n_uploaded_segments / (double)upload->n_segments;
  g_signal_emit (upload->job, compose_job_signals[IMAGE_UPLOAD_PROGRESS], 0, upload->filename, percent);
  g_debug ("Successfully uploaded segment %u of %u!", upload->n_uploaded_segments, upload->n_segments);

  /* If Finished, issue a FINALIZE command to the twitter server. */
  if (upload->n_uploaded_segments == upload->n_segments)
    {
      RestProxy *upload_proxy = rest_proxy_call_get_proxy (call);
      RestProxyCall *finalize_call = rest_proxy_new_call (upload_proxy);

      rest_proxy_call_set_function (finalize_call, "1.1/media/upload.json");
      rest_proxy_call_set_method (finalize_call, "POST");
      rest_proxy_call_add_param (finalize_call, "command", "FINALIZE");
      rest_proxy_call_take_param (finalize_call, "media_id", g_strdup_printf ("%" G_GINT64_FORMAT, upload->id));

      g_debug ("Sending FINALIZE call for media %s", upload->filename);
      rest_proxy_call_invoke_async (finalize_call, upload->cancellable, media_finalized, upload);
      return;
    }

  /* Upload next segment */
  upload_next_media_segment (rest_proxy_call_get_proxy (call),
                             upload);
}

static void
media_upload_inited (GObject      *object,
                     GAsyncResult *result,
                     gpointer      user_data)
{
  RestProxyCall *call = REST_PROXY_CALL (object);
  MediaUpload *upload = user_data;
  GError *error = NULL;
  gint64 media_id;

  /* Aborted? */
  if (upload->filename == NULL)
    return;

  /* Just making sure */
  g_assert_cmpint (upload->id, ==, 0);

  rest_proxy_call_invoke_finish (call, result, &error);
  if (error != NULL)
    {
      if (error->code != G_IO_ERROR_CANCELLED)
        g_warning ("%s: %s", __FUNCTION__, error->message);

      fail_upload (upload, error);
      return;
    }

  /* Parse response json */
  {
    JsonParser *parser = json_parser_new ();
    GError *json_error = NULL;
    JsonObject *root_object;

    json_parser_load_from_data (parser, rest_proxy_call_get_payload (call), -1, &json_error);
    if (json_error != NULL)
      {
        if (error->code != G_IO_ERROR_CANCELLED)
          g_warning ("%s: %s. Payload:\n%s", __FUNCTION__, json_error->message,
                     rest_proxy_call_get_payload (call));

        fail_upload (upload, json_error);
        g_object_unref (parser);
        return;
      }

    root_object = json_node_get_object (json_parser_get_root (parser));
    media_id = json_object_get_int_member (root_object, "media_id");

    g_object_unref (parser);
  }

  g_debug ("Media ID: %" G_GINT64_FORMAT, media_id);
  upload->id = media_id;

  /* Now that we know the media ID for the upload, we can start sending segments using that Id.
   * We already computed the amount of segments we need before sending the INIT command. */
  g_debug ("Starting to send %u segments of %s...", upload->n_segments, upload->filename);

  upload_next_media_segment (rest_proxy_call_get_proxy (call),
                             upload);
}

void
cb_compose_job_upload_image_async (CbComposeJob *self,
                                   const char   *image_path)
{
  MediaUpload *upload = NULL;
  RestProxyCall *call;
  GFile *file;
  GFileInfo *file_info;
  const char *content_type;
  char *mime_type;
  char *contents;
  gsize contents_length;
  guint i;

  for (i = 0; i < MAX_UPLOADS; i ++)
    {
      MediaUpload *u = &self->uploads[i];

      if (u->filename == NULL)
        {
          upload = u;
          break;
        }
    }

  g_assert (upload != NULL);

  /*file = g_file_new_for_path ("/home/baedert/test.mp4");*/
  file = g_file_new_for_path ("/home/baedert/test2.webm");
  /*file = g_file_new_for_path ("/home/baedert/rollo.png");*/
  /*file = g_file_new_for_path (image_path);*/
  file_info = g_file_query_info (file,
                                G_FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE,
                                G_FILE_QUERY_INFO_NONE,
                                NULL, NULL);
  /* TODO: Error checking? */
  g_file_load_contents (file, NULL, &contents, &contents_length, NULL, NULL);
  g_object_unref (file);

  upload->job = g_object_ref (self); /* XXX Circular reference? */
  upload->filename = g_strdup (image_path);
  upload->cancellable = g_cancellable_new ();
  upload->contents = contents;
  upload->contents_length = contents_length;
  upload->n_segments = (contents_length / MEDIA_SEGMENT_BYTES) + 1;

  g_assert_cmpint (upload->n_segments, >=, 1);

  call = rest_proxy_new_call (self->upload_proxy);
  rest_proxy_call_set_function (call, "1.1/media/upload.json");
  rest_proxy_call_set_method (call, "POST");
  rest_proxy_call_add_param (call, "command", "INIT");
  rest_proxy_call_take_param (call, "total_bytes", g_strdup_printf ("%"G_GINT64_FORMAT, contents_length));
  /* media_type is the mime-type of the file. */
  content_type = g_file_info_get_content_type (file_info);
  mime_type = g_content_type_get_mime_type (content_type);

  /* XXX: We don't set the media_category paramter above. The docs are very vague about what it's used for. */
  if (mime_type)
    rest_proxy_call_take_param (call, "media_type", g_steal_pointer (&mime_type));
  else
    rest_proxy_call_add_param (call, "media_type", content_type);

#ifdef DEBUG
  {
    char *s = cb_utils_rest_proxy_call_to_string (call);

    g_debug ("%s: %s", G_STRLOC, s);
    g_free (s);
  }
#endif

  rest_proxy_call_invoke_async (call, upload->cancellable, media_upload_inited, upload);

  g_object_unref (file_info);
  g_object_unref (call);
}

void
cb_compose_job_abort_image_upload (CbComposeJob *self,
                                   const char   *image_path)
{
  guint i;

  g_debug ("%s: Aborting %s", __FUNCTION__, image_path);

  for (i = 0; i < MAX_UPLOADS; i ++)
    {
      MediaUpload *upload = &self->uploads[i];

      if (upload->filename != NULL &&
          strcmp (upload->filename, image_path) == 0)
        {
          g_cancellable_cancel (upload->cancellable);
          image_upload_free (upload);
          g_clear_object (&upload->job);
          break;
        }
    }
}

void
cb_compose_job_abort_all_uploads (CbComposeJob *self)
{
  guint i;

  g_debug ("%s", __FUNCTION__);

  for (i = 0; i < MAX_UPLOADS; i ++)
    {
      MediaUpload *upload = &self->uploads[i];

      if (upload->filename != NULL)
        {
          g_cancellable_cancel (upload->cancellable);
          image_upload_free (upload);
          g_clear_object (&upload->job);
          break;
        }
    }
}

void
cb_compose_job_set_reply_id (CbComposeJob *self,
                             gint64        reply_id)
{
  self->reply_id = reply_id;
}

void
cb_compose_job_set_quoted_tweet (CbComposeJob *self,
                                 CbTweet      *quoted_tweet)
{
  g_set_object (&self->quoted_tweet, quoted_tweet);
}

void
cb_compose_job_set_text (CbComposeJob *self,
                         const char   *text)
{
  self->text = g_strdup (text);
}

static void
send_tweet_call_completed_cb (GObject      *source_object,
                              GAsyncResult *result,
                              gpointer      user_data)
{
  RestProxyCall *call = REST_PROXY_CALL (source_object);
  GTask *send_task = user_data;
  GError *error = NULL;

  rest_proxy_call_invoke_finish (call, result, &error);
  if (error)
    {
      g_warning ("Could not send tweet: %s", error->message);
      g_task_return_error (send_task, error);
    }
  else
    {
      g_task_return_boolean (send_task, TRUE);
    }

  g_object_unref (send_task);
}

static void
do_send (CbComposeJob *self)
{
  char *media_ids = build_image_id_string (self);

  g_assert (cb_compose_job_get_n_unfinished_uploads (self) == 0);
  g_assert (self->send_call != NULL);
  g_assert (self->send_task != NULL);

  if (media_ids)
    rest_proxy_call_take_param (self->send_call, "media_ids", media_ids);

#ifdef DEBUG
  {
    char *s = cb_utils_rest_proxy_call_to_string (self->send_call);

    g_debug ("%s: %s", G_STRLOC, s);
    g_free (s);
  }
#endif

  rest_proxy_call_invoke_async (self->send_call,
                                self->cancellable,
                                send_tweet_call_completed_cb,
                                self->send_task);
}

void
cb_compose_job_send_async (CbComposeJob        *self,
                           GCancellable        *cancellable,
                           GAsyncReadyCallback  callback,
                           gpointer             user_data)
{
  GTask *task;
  RestProxyCall *call;

  g_assert (self->send_task == NULL);

  task = g_task_new (self, cancellable, callback, user_data);

  call = rest_proxy_new_call (self->account_proxy);
  rest_proxy_call_set_function (call, "1.1/statuses/update.json");
  rest_proxy_call_set_method (call, "POST");
  rest_proxy_call_add_param (call, "auto_populate_reply_metadata", "true");

  if (self->reply_id != 0)
    {
      char *id_str = g_strdup_printf ("%" G_GINT64_FORMAT, self->reply_id);

      g_assert (self->quoted_tweet == NULL);

      rest_proxy_call_take_param (call, "in_reply_to_status_id", id_str);
    }
  else if (self->quoted_tweet != NULL)
    {
      const CbMiniTweet *mt = self->quoted_tweet->retweeted_tweet != NULL ?
                              self->quoted_tweet->retweeted_tweet :
                              &self->quoted_tweet->source_tweet;
      char *quoted_url = g_strdup_printf ("https://twitter.com/%s/status/%" G_GINT64_FORMAT,
                                          mt->author.screen_name, mt->id);

      g_assert (self->reply_id == 0);

      rest_proxy_call_take_param (call, "attachment_url", quoted_url);
    }

  rest_proxy_call_take_param (call, "status", g_steal_pointer (&self->text));


  self->send_call = call;
  self->send_task = task;
  if (cb_compose_job_get_n_unfinished_uploads (self) > 0)
    {
      /* In this case, we need to wait until ALL uploads are complete and successful. */
    }
  else
    {
      do_send (self);
    }
}

gboolean
cb_compose_job_send_finish (CbComposeJob  *self,
                            GAsyncResult  *result,
                            GError       **error)
{
  return g_task_propagate_boolean (G_TASK (result), error);
}
