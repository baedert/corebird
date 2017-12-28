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

#ifndef __CB_ACTIVITY_MODEL_H__
#define __CB_ACTIVITY_MODEL_H__

#include <glib-object.h>
#include <gtk/gtk.h>

typedef enum
{
  CB_ACTIVITY_FAVORITE,

} CbActivityType;

typedef struct
{
  CbActivityType type;

} CbActivity;


struct _CbActivityModel
{
  GObject parent_instance;

  GArray *activities;
};

typedef struct _CbActivityModel CbActivityModel;

#define CB_TYPE_ACTIVITY_MODEL cb_activity_model_get_type ()
G_DECLARE_FINAL_TYPE (CbActivityModel, cb_activity_model, CB, ACTIVITY_MODEL, GObject);

CbActivityModel * cb_activity_model_new        (void            *account);
void              cb_activity_model_poll       (CbActivityModel *self);

#endif

