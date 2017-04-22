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

#ifndef BUNDLE_H
#define BUNDLE_H

#include <glib-object.h>

/*
 * TODO:
 * Make every CbBundle instance take a fixed amount of data instead
 * of keeping two GArrays around. The keys are already required to be
 * integers, so just also require them to be subsequent integers starting
 * from 0 and just them as indeces into an array.
 */

struct _CbBundle
{
  GObject parent_instance;

  GArray *values;
  GArray *keys;
};

typedef struct _CbBundle CbBundle;

#define CB_TYPE_BUNDLE cb_bundle_get_type ()
G_DECLARE_FINAL_TYPE (CbBundle, cb_bundle, CB, BUNDLE, GObject);



GType cb_bundle_get_type (void) G_GNUC_CONST;

CbBundle *cb_bundle_new (void);

gboolean cb_bundle_equals (CbBundle *self, CbBundle *other);

void        cb_bundle_put_string (CbBundle *self, int key, const char *val);
const char *cb_bundle_get_string (CbBundle *self, int key);

void cb_bundle_put_int (CbBundle *self, int key, int val);
int  cb_bundle_get_int (CbBundle *self, int key);

void   cb_bundle_put_int64 (CbBundle *self, int key, gint64 val);
gint64 cb_bundle_get_int64 (CbBundle *self, int key);

void     cb_bundle_put_bool (CbBundle *self, int key, gboolean val);
gboolean cb_bundle_get_bool (CbBundle *self, int key);

void     cb_bundle_put_object (CbBundle *self, int key, GObject *object);
GObject *cb_bundle_get_object (CbBundle *self, int key);


#endif
