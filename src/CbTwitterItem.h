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

#ifndef TWITTER_ITEM_H
#define TWITTER_ITEM_H

#include <glib-object.h>

#define CB_TYPE_TWITTER_ITEM (cb_twitter_item_get_type())

G_DECLARE_INTERFACE (CbTwitterItem, cb_twitter_item, CB, TWITTER_ITEM, GObject)

struct _CbTwitterItemInterface
{
  GTypeInterface base_iface;

  gint64 (*get_sort_factor) (CbTwitterItem *self);

  int    (*update_time_delta) (CbTwitterItem *self,
                               GDateTime     *now);

  gint64 (*get_timestamp) (CbTwitterItem *self);

  void   (*set_last_set_timediff) (CbTwitterItem *self,
                                   GTimeSpan      span);

  GTimeSpan (*get_last_set_timediff) (CbTwitterItem *self);
};

gint64 cb_twitter_item_get_sort_factor (CbTwitterItem *self);

int    cb_twitter_item_update_time_delta (CbTwitterItem *self,
                                          GDateTime     *now);

gint64 cb_twitter_item_get_timestamp (CbTwitterItem *self);

/* Basically just for CbDeltaUpdater */
void   cb_twitter_item_set_last_set_timediff (CbTwitterItem *self,
                                              GTimeSpan      span);
GTimeSpan cb_twitter_item_get_last_set_timediff (CbTwitterItem *self);



#endif
