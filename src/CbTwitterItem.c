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

#include "CbTwitterItem.h"


G_DEFINE_INTERFACE (CbTwitterItem, cb_twitter_item, G_TYPE_OBJECT);


static int
default_update_time_delta (CbTwitterItem *self,
                           GDateTime              *now)
{
  /* NOPE */
  return 0;
}

static void
cb_twitter_item_default_init (CbTwitterItemInterface *self)
{
  self->get_sort_factor       = NULL;
  self->update_time_delta     = default_update_time_delta;
  self->get_timestamp         = NULL;
  self->set_last_set_timediff = NULL;
  self->get_last_set_timediff = NULL;
}

gint64
cb_twitter_item_get_sort_factor (CbTwitterItem *self)
{
  CbTwitterItemInterface *iface;

  g_return_val_if_fail (CB_IS_TWITTER_ITEM (self), 0);

  iface = CB_TWITTER_ITEM_GET_IFACE (self);

  return iface->get_sort_factor (self);
}

int
cb_twitter_item_update_time_delta (CbTwitterItem *self,
                                   GDateTime     *now)
{
  CbTwitterItemInterface *iface;

  g_return_val_if_fail (CB_IS_TWITTER_ITEM (self), 0);

  iface = CB_TWITTER_ITEM_GET_IFACE (self);

  return iface->update_time_delta (self, now);
}

gint64
cb_twitter_item_get_timestamp (CbTwitterItem *self)
{
  CbTwitterItemInterface *iface;

  g_return_val_if_fail (CB_IS_TWITTER_ITEM (self), 0);

  iface = CB_TWITTER_ITEM_GET_IFACE (self);

  return iface->get_timestamp (self);
}

void
cb_twitter_item_set_last_set_timediff (CbTwitterItem *self,
                                       GTimeSpan      span)
{
  CbTwitterItemInterface *iface;

  g_return_if_fail (CB_IS_TWITTER_ITEM (self));

  iface = CB_TWITTER_ITEM_GET_IFACE (self);

  iface->set_last_set_timediff (self, span);
}

GTimeSpan
cb_twitter_item_get_last_set_timediff (CbTwitterItem *self)
{
  CbTwitterItemInterface *iface;

  g_return_val_if_fail (CB_IS_TWITTER_ITEM (self), 0);

  iface = CB_TWITTER_ITEM_GET_IFACE (self);

  return iface->get_last_set_timediff (self);
}
