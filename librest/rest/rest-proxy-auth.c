/*
 * librest - RESTful web services access
 * Copyright (c) 2012, Red Hat, Inc.
 *
 * Authors: Christophe Fergeau <cfergeau@redhat.com>
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
#include <config.h>

#include <rest/rest-proxy-auth.h>
#include <rest/rest-proxy-auth-private.h>
#include "rest-private.h"

G_DEFINE_TYPE (RestProxyAuth, rest_proxy_auth, G_TYPE_OBJECT)

#define REST_PROXY_AUTH_GET_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), REST_TYPE_PROXY_AUTH, RestProxyAuthPrivate))

struct _RestProxyAuthPrivate {
  /* used to hold state during async authentication */
  RestProxy *proxy;
  SoupSession *session;
  SoupMessage *message;
  SoupAuth *auth;
  gboolean paused;
};

static void
rest_proxy_auth_dispose (GObject *object)
{
  RestProxyAuthPrivate *priv = ((RestProxyAuth*)object)->priv;

  g_clear_object (&priv->proxy);
  g_clear_object (&priv->session);
  g_clear_object (&priv->message);
  g_clear_object (&priv->auth);

  G_OBJECT_CLASS (rest_proxy_auth_parent_class)->dispose (object);
}

static void
rest_proxy_auth_class_init (RestProxyAuthClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (RestProxyAuthPrivate));

  object_class->dispose = rest_proxy_auth_dispose;
}

static void
rest_proxy_auth_init (RestProxyAuth *proxy)
{
  proxy->priv = REST_PROXY_AUTH_GET_PRIVATE (proxy);
}

G_GNUC_INTERNAL RestProxyAuth*
rest_proxy_auth_new (RestProxy *proxy,
                     SoupSession *session,
                     SoupMessage *message,
                     SoupAuth *soup_auth)
{
  RestProxyAuth *rest_auth;

  g_return_val_if_fail (REST_IS_PROXY (proxy), NULL);
  g_return_val_if_fail (SOUP_IS_SESSION (session), NULL);
  g_return_val_if_fail (SOUP_IS_MESSAGE (message), NULL);
  g_return_val_if_fail (SOUP_IS_AUTH (soup_auth), NULL);

  rest_auth = REST_PROXY_AUTH (g_object_new (REST_TYPE_PROXY_AUTH, NULL));
  rest_auth->priv->proxy = g_object_ref(proxy);
  rest_auth->priv->session = g_object_ref(session);
  rest_auth->priv->message = g_object_ref(message);
  rest_auth->priv->auth = g_object_ref(soup_auth);

  return rest_auth;
}

/**
 * rest_proxy_auth_pause:
 * @auth: a #RestProxyAuth
 *
 * Pauses @auth.
 *
 * If @auth is already paused, this function does not
 * do anything.
 */
void
rest_proxy_auth_pause (RestProxyAuth *auth)
{
  g_return_if_fail (REST_IS_PROXY_AUTH (auth));

  if (auth->priv->paused)
      return;

  auth->priv->paused = TRUE;
  soup_session_pause_message (auth->priv->session, auth->priv->message);
}

/**
 * rest_proxy_auth_unpause:
 * @auth: a paused #RestProxyAuth
 *
 * Unpauses a paused #RestProxyAuth instance.
 */
void
rest_proxy_auth_unpause (RestProxyAuth *auth)
{
  RestProxy *proxy;
  gchar *username;
  gchar *password;

  g_return_if_fail (REST_IS_PROXY_AUTH (auth));
  g_return_if_fail (auth->priv->paused);

  proxy = REST_PROXY (auth->priv->proxy);
  g_object_get (G_OBJECT (proxy), "username", &username, "password", &password, NULL);
  soup_auth_authenticate (auth->priv->auth, username, password);
  g_free (username);
  g_free (password);
  soup_session_unpause_message (auth->priv->session, auth->priv->message);
  auth->priv->paused = FALSE;
}

G_GNUC_INTERNAL gboolean rest_proxy_auth_is_paused (RestProxyAuth *auth)
{
  g_return_val_if_fail (REST_IS_PROXY_AUTH (auth), FALSE);

  return auth->priv->paused;
}
