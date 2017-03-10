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

#ifndef DELTA_UPDATER_H
#define DELTA_UPDATER_H

#include <glib-object.h>
#include <gtk/gtk.h>
#include "CbTwitterItem.h"

typedef struct _CbDeltaUpdater      CbDeltaUpdater;
typedef struct _CbDeltaUpdaterClass CbDeltaUpdaterClass;

#define CB_TYPE_DELTA_UPDATER           (cb_delta_updater_get_type ())
#define CB_DELTA_UPDATER(obj)           (G_TYPE_CHECK_INSTANCE_CAST(obj, CB_TYPE_DELTA_UPDATER, CbDeltaUpdater))
#define CB_DELTA_UPDATER_CLASS(cls)     (G_TYPE_CHECK_CLASS_CAST(cls, CB_TYPE_DELTA_UPDATER, CbDeltaUpdaterClass))
#define CB_IS_DELTA_UPDATER(obj)        (G_TYPE_CHECK_INSTANCE_TYPE(obj, CB_TYPE_DELTA_UPDATER))
#define CB_IS_DELTA_UPDATER_CLASS(cls)   (G_TYPE_CHECK_CLASS_TYPE(cls, CB_TYPE_DELTA_UPDATER))
#define CB_DELTA_UPDATER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS(obj, CB_TYPE_DELTA_UPDATER, CbDeltaUpdaterClass))

struct _CbDeltaUpdater
{
  GObject parent_instance;

  GtkWidget *listbox;
  guint minutely_id;
};

struct _CbDeltaUpdaterClass
{
  GObjectClass parent_class;
};

GType            cb_delta_updater_get_type (void) G_GNUC_CONST;

CbDeltaUpdater * cb_delta_updater_new (GtkWidget *listbox);

#endif
