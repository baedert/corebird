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

#include "CbUserStream.h"

G_DEFINE_TYPE (CbUserStream, cb_user_stream, G_TYPE_OBJECT);


static void
cb_user_stream_finalize (GObject *o)
{

  G_OBJECT_CLASS (cb_user_stream_parent_class)->finalize (o);
}

static void
cb_user_stream_init (CbUserStream *self)
{
  self->receivers = g_ptr_array_new ();
}

static void
cb_user_stream_class_init (CbUserStreamClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_user_stream_finalize;
}

CbUserStream *
cb_user_stream_new (const char *account_name)
{
  CbUserStream *self = CB_USER_STREAM (g_object_new (CB_TYPE_USER_STREAM, NULL));

  // TODO: Set account name
  return self;
}

void
cb_user_stream_set_proxy_data (CbUserStream *self,
                               const char   *token,
                               const char   *token_secret)
{

}
