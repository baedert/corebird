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

#ifndef __CB_BUNDLE_HISTORY_H__
#define __CB_BUNDLE_HISTORY_H__

#include <glib-object.h>
#include "CbBundle.h"

#define HISTORY_SIZE 10

struct _CbBundleHistory
{
  GObject parent_instance;

  int pos;
  int elements[HISTORY_SIZE];
  CbBundle *bundles[HISTORY_SIZE];
};

typedef struct _CbBundleHistory CbBundleHistory;

#define CB_TYPE_BUNDLE_HISTORY cb_bundle_history_get_type ()
G_DECLARE_FINAL_TYPE (CbBundleHistory, cb_bundle_history, CB, BUNDLE_HISTORY, GObject);


CbBundleHistory * cb_bundle_history_new                (void);
void              cb_bundle_history_push               (CbBundleHistory *self,
                                                        int              v,
                                                        CbBundle        *bundle);
int               cb_bundle_history_back               (CbBundleHistory *self);
int               cb_bundle_history_forward            (CbBundleHistory *self);
gboolean          cb_bundle_history_at_start           (CbBundleHistory *self);
gboolean          cb_bundle_history_at_end             (CbBundleHistory *self);
void              cb_bundle_history_remove_current     (CbBundleHistory *self);
int               cb_bundle_history_get_current        (CbBundleHistory *self);
CbBundle *        cb_bundle_history_get_current_bundle (CbBundleHistory *self);

#endif
