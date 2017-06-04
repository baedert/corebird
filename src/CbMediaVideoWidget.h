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
#ifndef CB_MEDIA_VIDEO_WIDGET_H
#define CB_MEDIA_VIDEO_WIDGET_H

#ifdef VIDEO
#include <gst/gst.h>
#endif
#include <gtk/gtk.h>
#include <libsoup/soup.h>
#include "CbMedia.h"
#include "CbSurfaceProgress.h"

typedef struct _CbMediaVideoWidget      CbMediaVideoWidget;
typedef struct _CbMediaVideoWidgetClass CbMediaVideoWidgetClass;

#define CB_TYPE_MEDIA_VIDEO_WIDGET           (cb_media_video_widget_get_type ())
#define CB_MEDIA_VIDEO_WIDGET(obj)           (G_TYPE_CHECK_INSTANCE_CAST(obj, CB_TYPE_MEDIA_VIDEO_WIDGET, CbMediaVideoWidget))
#define CB_MEDIA_VIDEO_WIDGET_CLASS(cls)     (G_TYPE_CHECK_CLASS_CAST(cls, CB_TYPE_MEDIA_VIDEO_WIDGET, CbMediaVideoWidgetClass))
#define CB_IS_MEDIA_VIDEO_WIDGET(obj)        (G_TYPE_CHECK_INSTANCE_TYPE(obj, CB_TYPE_MEDIA_VIDEO_WIDGET))
#define CB_IS_MEDIA_VIDEO_WIDGET_CLASS(cls)   (G_TYPE_CHECK_CLASS_TYPE(cls, CB_TYPE_MEDIA_VIDEO_WIDGET))
#define CB_MEDIA_VIDEO_WIDGET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS(obj, CB_TYPE_MEDIA_VIDEO_WIDGET, CbMediaVideoWidgetClass))

struct _CbMediaVideoWidget
{
  GtkStack parent_instance;

#ifdef VIDEO
  GstElement *src;
  GstElement *sink;
#endif

  SoupSession *session;
  SoupMessage *message;

  GtkWidget *area;
  GtkWidget *surface_progress;
  GtkWidget *video_progress;
  GtkWidget *error_label;

  GCancellable *cancellable;
  guint video_progress_id;
  char *media_url;
};

struct _CbMediaVideoWidgetClass
{
  GtkStackClass parent_class;
};

GType cb_media_video_widget_get_type (void) G_GNUC_CONST;

CbMediaVideoWidget *cb_media_video_widget_new (CbMedia *media);
void cb_media_video_widget_start (CbMediaVideoWidget *self);

#endif
