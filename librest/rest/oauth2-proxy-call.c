/*
 * librest - RESTful web services access
 * Copyright (c) 2008, 2009, Intel Corporation.
 *
 * Authors: Rob Bradford <rob@linux.intel.com>
 *          Ross Burton <ross@linux.intel.com>
 *          Jonathon Jongsma <jonathon.jongsma@collabora.co.uk>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU Lesser General Public License,
 * version 2.1, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
 * more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

#include <string.h>
#include <libsoup/soup.h>
#include <rest/rest-proxy-call.h>
#include "oauth2-proxy-call.h"
#include "oauth2-proxy-private.h"
#include "sha1.h"

G_DEFINE_TYPE (OAuth2ProxyCall, oauth2_proxy_call, REST_TYPE_PROXY_CALL)

static gboolean
_prepare (RestProxyCall *call, GError **error)
{
  OAuth2Proxy *proxy = NULL;
  gboolean result = TRUE;

  g_object_get (call, "proxy", &proxy, NULL);

  if (!proxy->priv->access_token) {
    g_set_error (error,
                 REST_PROXY_CALL_ERROR,
                 REST_PROXY_CALL_FAILED,
                 "Missing access token, web service not properly authenticated");
    result = FALSE;
  } else {
    rest_proxy_call_add_param (call, "access_token", proxy->priv->access_token);
  }

  g_object_unref (proxy);

  return result;
}

static void
oauth2_proxy_call_class_init (OAuth2ProxyCallClass *klass)
{
  RestProxyCallClass *call_class = REST_PROXY_CALL_CLASS (klass);

  call_class->prepare = _prepare;
}

static void
oauth2_proxy_call_init (OAuth2ProxyCall *self)
{
}

