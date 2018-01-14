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

#ifndef _CB_MEDIA_IMAGE_WIDGET_H_
#define _CB_MEDIA_IMAGE_WIDGET_H_

#include <gtk/gtk.h>
#include "CbMedia.h"

#define CB_TYPE_MEDIA_IMAGE_WIDGET cb_media_image_widget_get_type ()
G_DECLARE_FINAL_TYPE (CbMediaImageWidget, cb_media_image_widget, CB, MEDIA_IMAGE_WIDGET, GtkScrolledWindow);

struct _CbMediaImageWidget
{
  GtkScrolledWindow parent_instance;

  GtkWidget *image;
  GtkGesture *drag_gesture;

  double drag_start_hvalue;
  double drag_start_vvalue;

  double initial_scroll_x;
  double initial_scroll_y;

  int img_width;
  int img_height;

  gulong hadj_changed_id;
  gulong vadj_changed_id;
};
typedef struct _CbMediaImageWidget CbMediaImageWidget;

GtkWidget * cb_media_image_widget_new       (CbMedia *media);
void        cb_media_image_widget_scroll_to (CbMediaImageWidget *self,
                                             double              px,
                                             double              py);
void        cb_media_image_widget_calc_size (CbMediaImageWidget *self);

#endif
