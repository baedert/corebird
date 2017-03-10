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

#include "CbDeltaUpdater.h"

G_DEFINE_TYPE(CbDeltaUpdater, cb_delta_updater, G_TYPE_OBJECT)


static gboolean
minutely_cb (gpointer user_data)
{
  CbDeltaUpdater *self = user_data;
  GDateTime *now;
  GList *widgets;
  GList *l;

  if (!GTK_IS_WIDGET (self->listbox))
    return G_SOURCE_CONTINUE;

  widgets = gtk_container_get_children (GTK_CONTAINER (self->listbox));
  now = g_date_time_new_now_local ();

  for (l = widgets; l != NULL; l = l->next)
    {
      GtkWidget *row = GTK_WIDGET (l->data);

      if (CB_IS_TWITTER_ITEM (row))
        {
          CbTwitterItem *item = CB_TWITTER_ITEM (row);
          gint64 timestamp = cb_twitter_item_get_timestamp (item);
          gint64 last_set_timediff = cb_twitter_item_get_last_set_timediff (item);
          GDateTime *item_time = g_date_time_new_from_unix_local (timestamp);
          GTimeSpan time_diff = g_date_time_difference (now, item_time);
          int seconds = time_diff / 1000 / 1000;


          if (last_set_timediff < 60)
            {
              /* New minute */
              cb_twitter_item_update_time_delta (item, now);
              cb_twitter_item_set_last_set_timediff (item, seconds / 60);
            }
          else if (seconds > last_set_timediff + 60)
            {
              /* New hour */
              cb_twitter_item_update_time_delta (item, now);
              cb_twitter_item_set_last_set_timediff (item, seconds / 60);
            }

          g_date_time_unref (item_time);
        }
    }


  g_date_time_unref (now);
  g_list_free (widgets);

  return G_SOURCE_CONTINUE;
}

static void
cb_delta_updater_finalize (GObject *object)
{
  CbDeltaUpdater *self = CB_DELTA_UPDATER (object);

  if (self->minutely_id != 0)
    g_source_remove (self->minutely_id);

  G_OBJECT_CLASS (cb_delta_updater_parent_class)->finalize (object);
}

static void
cb_delta_updater_init (CbDeltaUpdater *self)
{
  self->minutely_id = g_timeout_add (1000 * 60, minutely_cb, self);
}

static void
cb_delta_updater_class_init (CbDeltaUpdaterClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_delta_updater_finalize;
}

CbDeltaUpdater *
cb_delta_updater_new (GtkWidget *listbox)
{
  CbDeltaUpdater *self = g_object_new (CB_TYPE_DELTA_UPDATER, NULL);

  g_return_val_if_fail (GTK_IS_LIST_BOX (listbox), self);

  self->listbox = listbox;

  return self;
}
