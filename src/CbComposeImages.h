/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2018 Timm Bäder
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

#ifndef __CB_COMPOSE_IMAGES_H__
#define __CB_COMPOSE_IMAGES_H__

#include <gtk/gtk.h>
#include "CbAnimation.h"

typedef struct _CbComposeImages CbComposeImages;
struct _CbComposeImages
{
  GtkWidget parent_instance;

  GArray *images;
  CbAnimation delete_animation;
};

#define CB_TYPE_COMPOSE_IMAGES cb_compose_images_get_type ()
G_DECLARE_FINAL_TYPE (CbComposeImages, cb_compose_images, CB, COMPOSE_IMAGES, GtkWidget);

void      cb_compose_images_load_image            (CbComposeImages *self,
                                                   GFile           *file);
void      cb_compose_images_set_image_progress    (CbComposeImages *self,
                                                   const char      *image_path,
                                                   double           progress);
void      cb_compose_images_end_image_progress    (CbComposeImages *self,
                                                   const char      *image_path,
                                                   const char      *error_message);
int       cb_compose_images_get_n_images          (CbComposeImages *self);
gboolean  cb_compose_images_is_full               (CbComposeImages *self);
gboolean  cb_compose_images_has_gif               (CbComposeImages *self);

void      cb_compose_images_insensitivize_buttons (CbComposeImages *self);

#endif
