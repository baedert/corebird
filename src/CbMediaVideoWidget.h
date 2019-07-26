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
#ifndef _CB_MEDIA_VIDEO_WIDGET_H_
#define _CB_MEDIA_VIDEO_WIDGET_H_

#ifdef VIDEO
#include <gst/gst.h>
#endif
#include <gtk/gtk.h>
#include <libsoup/soup.h>
#include "CbMedia.h"
#include "CbSurfaceProgress.h"

#define CB_TYPE_MEDIA_VIDEO_WIDGET cb_media_video_widget_get_type ()
G_DECLARE_FINAL_TYPE (CbMediaVideoWidget, cb_media_video_widget, CB, MEDIA_VIDEO_WIDGET, GtkWidget);

struct _CbMediaVideoWidget
{
  GtkWidget parent_instance;


#ifdef VIDEO
  GstElement *src;
  GstElement *sink;
#endif

  SoupSession *session;
  SoupMessage *message;

  GtkWidget *stack;
  GtkWidget *area;
  GtkWidget *surface_progress;
  GtkWidget *video_progress;
  GtkWidget *error_label;

  GCancellable *cancellable;
  guint video_progress_id;
  char *media_url;
};
typedef struct _CbMediaVideoWidget CbMediaVideoWidget;

CbMediaVideoWidget * cb_media_video_widget_new   (CbMedia *media);
void                 cb_media_video_widget_start (CbMediaVideoWidget *self);

#endif
