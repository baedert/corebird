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

#include "CbMessageReceiver.h"

G_DEFINE_INTERFACE (CbMessageReceiver, cb_message_receiver, G_TYPE_OBJECT);

static void
cb_message_receiver_default_init (CbMessageReceiverInterface *self)
{
  self->stream_message_received = NULL;
}

void
cb_message_receiver_stream_message_received (CbMessageReceiver   *self,
                                             CbStreamMessageType  type,
                                             JsonNode            *node)
{
  CbMessageReceiverInterface *iface;

  g_return_if_fail (CB_IS_MESSAGE_RECEIVER (self));

  iface = CB_MESSAGE_RECEIVER_GET_IFACE (self);

  return iface->stream_message_received (self, type, node);
}
