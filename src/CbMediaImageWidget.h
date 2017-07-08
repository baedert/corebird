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

#ifndef CB_MEDIA_IMAGE_WIDGET_H
#define CB_MEDIA_IMAGE_WIDGET_H

#include <gtk/gtk.h>

#include "CbMedia.h"

typedef struct _CbMediaImageWidget      CbMediaImageWidget;
typedef struct _CbMediaImageWidgetClass CbMediaImageWidgetClass;

#define CB_TYPE_MEDIA_IMAGE_WIDGET           (cb_media_image_widget_get_type ())
#define CB_MEDIA_IMAGE_WIDGET(obj)           (G_TYPE_CHECK_INSTANCE_CAST(obj, CB_TYPE_MEDIA_IMAGE_WIDGET, CbMediaImageWidget))
#define CB_MEDIA_IMAGE_WIDGET_CLASS(cls)     (G_TYPE_CHECK_CLASS_CAST(cls, CB_TYPE_MEDIA_IMAGE_WIDGET, CbMediaImageWidgetClass))
#define CB_IS_MEDIA_IMAGE_WIDGET(obj)        (G_TYPE_CHECK_INSTANCE_TYPE(obj, CB_TYPE_MEDIA_IMAGE_WIDGET))
#define CB_IS_MEDIA_IMAGE_WIDGET_CLASS(cls)   (G_TYPE_CHECK_CLASS_TYPE(cls, CB_TYPE_MEDIA_IMAGE_WIDGET))
#define CB_MEDIA_IMAGE_WIDGET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS(obj, CB_TYPE_MEDIA_IMAGE_WIDGET, CbMediaImageWidgetClass))

struct _CbMediaImageWidget
{
  GtkScrolledWindow parent_instance;

  GtkWidget *image;
  GtkGesture *drag_gesture;

  double drag_start_hvalue;
  double drag_start_vvalue;

  double initial_scroll_x;
  double initial_scroll_y;

  gulong hadj_changed_id;
  gulong vadj_changed_id;
};

struct _CbMediaImageWidgetClass
{
  GtkScrolledWindowClass parent_class;
};

GType cb_media_image_widget_get_type (void) G_GNUC_CONST;

GtkWidget *cb_media_image_widget_new (CbMedia *media);

void       cb_media_image_widget_scroll_to (CbMediaImageWidget *self,
                                            double              px,
                                            double              py);

#endif
