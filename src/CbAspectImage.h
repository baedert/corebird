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

#ifndef __CB_ASPECT_IMAGE_H__
#define __CB_ASPECT_IMAGE_H__

#include <gtk/gtk.h>
#include "CbAnimation.h"

struct _CbAspectImage
{
  GtkWidget parent_instance;

  GdkTexture *texture;

  CbAnimation opacity_animation;
  double opacity;
};
typedef struct _CbAspectImage CbAspectImage;


#define CB_TYPE_ASPECT_IMAGE cb_aspect_image_get_type ()
G_DECLARE_FINAL_TYPE (CbAspectImage, cb_aspect_image, CB, ASPECT_IMAGE, GtkWidget);

GtkWidget * cb_aspect_image_new (void);

void        cb_aspect_image_set_pixbuf (CbAspectImage *self,
                                        GdkPixbuf     *pixbuf);

#endif
