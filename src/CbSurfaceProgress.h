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
#ifndef CB_SURFACE_PROGRESS_H
#define CB_SURFACE_PROGRESS_H

#include <gtk/gtk.h>

typedef struct _CbSurfaceProgress      CbSurfaceProgress;
typedef struct _CbSurfaceProgressClass CbSurfaceProgressClass;

#define CB_TYPE_SURFACE_PROGRESS           (cb_surface_progress_get_type ())
#define CB_SURFACE_PROGRESS(obj)           (G_TYPE_CHECK_INSTANCE_CAST(obj, CB_TYPE_SURFACE_PROGRESS, CbSurfaceProgress))
#define CB_SURFACE_PROGRESS_CLASS(cls)     (G_TYPE_CHECK_CLASS_CAST(cls, CB_TYPE_SURFACE_PROGRESS, CbSurfaceProgressClass))
#define CB_IS_SURFACE_PROGRESS(obj)        (G_TYPE_CHECK_INSTANCE_TYPE(obj, CB_TYPE_SURFACE_PROGRESS))
#define CB_IS_SURFACE_PROGRESS_CLASS(cls)   (G_TYPE_CHECK_CLASS_TYPE(cls, CB_TYPE_SURFACE_PROGRESS))
#define CB_SURFACE_PROGRESS_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS(obj, CB_TYPE_SURFACE_PROGRESS, CbSurfaceProgressClass))

struct _CbSurfaceProgress
{
  GtkWidget parent_instance;

  cairo_surface_t *surface;
  double progress;

};

struct _CbSurfaceProgressClass
{
  GtkWidgetClass parent_class;
};

GType cb_surface_progress_get_type (void) G_GNUC_CONST;

GtkWidget *cb_surface_progress_new (void);

double cb_surface_progress_get_progress (CbSurfaceProgress *self);
void   cb_surface_progress_set_progress (CbSurfaceProgress *self,
                                         double             progress);

cairo_surface_t *cb_surface_progress_get_surface (CbSurfaceProgress *self);
void             cb_surface_progress_set_surface (CbSurfaceProgress *self,
                                                  cairo_surface_t   *surface);

#endif
