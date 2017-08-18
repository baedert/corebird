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

#ifndef __CB_COMPOSE_JOB_H__
#define __CB_COMPOSE_JOB_H__

#include <glib-object.h>
#include "CbTweet.h"
#include "rest/rest-proxy.h"

G_BEGIN_DECLS
typedef struct _CbComposeJob CbComposeJob;

#define CB_TYPE_COMPOSE_JOB (cb_compose_job_get_type ())
G_DECLARE_FINAL_TYPE (CbComposeJob, cb_compose_job, CB, COMPOSE_JOB, GObject);

typedef struct {
  GCancellable *cancellable;
  char *filename;
  gint64 id; /* 0 when not uploaded yet */
} ImageUpload;

struct _CbComposeJob
{
  GObject parent_instance;

  ImageUpload image_uploads[4];
  RestProxy *account_proxy;
  RestProxy *upload_proxy;
  gint64 reply_id;
  CbTweet *quoted_tweet;
  char *text;
  GCancellable *cancellable;

  RestProxyCall *send_call;
  GTask *send_task;
};


CbComposeJob *cb_compose_job_new                (RestProxy            *account_proxy,
                                                 RestProxy            *upload_proxy,
                                                 GCancellable         *cancellable);
void          cb_compose_job_upload_image_async (CbComposeJob         *self,
                                                 const char           *image_path);
void          cb_compose_job_abort_image_upload (CbComposeJob         *self,
                                                 const char           *image_path);
void          cb_compose_job_set_reply_id       (CbComposeJob         *self,
                                                 gint64                reply_id);
void          cb_compose_job_set_quoted_tweet   (CbComposeJob         *self,
                                                 CbTweet              *quoted_tweet);
void          cb_compose_job_set_text           (CbComposeJob         *self,
                                                 const char           *text);
void          cb_compose_job_send_async         (CbComposeJob         *self,
                                                 GCancellable         *cancellable,
                                                 GAsyncReadyCallback   callback,
                                                 gpointer              user_data);
gboolean      cb_compose_job_send_finish        (CbComposeJob          *self,
                                                 GAsyncResult          *result,
                                                 GError               **error);

G_END_DECLS

#endif
