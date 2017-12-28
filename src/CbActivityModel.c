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

#include "CbActivityModel.h"
#include "CbMessageReceiver.h"


static void cb_activity_model_iface_init (GListModelInterface *iface);
static void cb_activity_model_receiver_iface_init (CbMessageReceiverInterface *iface);

G_DEFINE_TYPE_WITH_CODE (CbActivityModel, cb_activity_model, G_TYPE_OBJECT,
                         G_IMPLEMENT_INTERFACE (G_TYPE_LIST_MODEL, cb_activity_model_iface_init)
                         G_IMPLEMENT_INTERFACE (CB_TYPE_MESSAGE_RECEIVER, cb_activity_model_receiver_iface_init));


static guint
get_n_items (GListModel *m)
{
  CbActivityModel *self = (CbActivityModel *)m;

  return 0;
}

static gpointer
get_item (GListModel *m,
          guint       _i)
{
  return NULL;
}

static GType
get_item_type (GListModel *m)
{
  return G_TYPE_NONE;
}


static void
cb_activity_model_iface_init (GListModelInterface *iface)
{
  iface->get_item_type = get_item_type;
  iface->get_n_items = get_n_items;
  iface->get_item = get_item;
}

static void
cb_activity_model_receiver_iface_init (CbMessageReceiverInterface *iface)
{
  iface->stream_message_received = NULL;
}

static void
cb_activity_model_finalize (GObject *o)
{
  CbActivityModel *self = CB_ACTIVITY_MODEL (o);

  g_array_unref (self->activities);

  G_OBJECT_CLASS (cb_activity_model_parent_class)->finalize (o);
}

static void
cb_activity_model_class_init (CbActivityModelClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_activity_model_finalize;
}

static void
cb_activity_model_init (CbActivityModel *self)
{
  self->activities = g_array_new (FALSE, TRUE, sizeof (CbActivity));
}

CbActivityModel *
cb_activity_model_new (void)
{
  return CB_ACTIVITY_MODEL (g_object_new (CB_TYPE_ACTIVITY_MODEL, NULL));
}

void
cb_activity_model_poll (CbActivityModel *self)
{

}
