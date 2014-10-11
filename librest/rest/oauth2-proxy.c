/*
 * librest - RESTful web services access
 * Copyright (c) 2008, 2009, 2010 Intel Corporation.
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

#include <rest/rest-proxy.h>
#include <libsoup/soup.h>
#include "oauth2-proxy.h"
#include "oauth2-proxy-private.h"
#include "oauth2-proxy-call.h"

G_DEFINE_TYPE (OAuth2Proxy, oauth2_proxy, REST_TYPE_PROXY)

#define OAUTH2_PROXY_GET_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), OAUTH2_TYPE_PROXY, OAuth2ProxyPrivate))

GQuark
oauth2_proxy_error_quark (void)
{
    return g_quark_from_static_string ("rest-oauth2-proxy");
}

#define EXTRA_CHARS_ENCODE "!$&'()*+,;=@"

enum {
  PROP_0,
  PROP_CLIENT_ID,
  PROP_AUTH_ENDPOINT,
  PROP_ACCESS_TOKEN
};

static RestProxyCall *
_new_call (RestProxy *proxy)
{
  RestProxyCall *call;

  call = g_object_new (OAUTH2_TYPE_PROXY_CALL,
                       "proxy", proxy,
                       NULL);

  return call;
}

static void
oauth2_proxy_get_property (GObject *object, guint property_id,
                              GValue *value, GParamSpec *pspec)
{
  OAuth2ProxyPrivate *priv = ((OAuth2Proxy*)object)->priv;

  switch (property_id) {
  case PROP_CLIENT_ID:
    g_value_set_string (value, priv->client_id);
    break;
  case PROP_AUTH_ENDPOINT:
    g_value_set_string (value, priv->auth_endpoint);
    break;
  case PROP_ACCESS_TOKEN:
    g_value_set_string (value, priv->access_token);
    break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
oauth2_proxy_set_property (GObject *object, guint property_id,
                              const GValue *value, GParamSpec *pspec)
{
  OAuth2ProxyPrivate *priv = ((OAuth2Proxy*)object)->priv;

  switch (property_id) {
  case PROP_CLIENT_ID:
    if (priv->client_id)
      g_free (priv->client_id);
    priv->client_id = g_value_dup_string (value);
    break;
  case PROP_AUTH_ENDPOINT:
    if (priv->auth_endpoint)
      g_free (priv->auth_endpoint);
    priv->auth_endpoint = g_value_dup_string (value);
    break;
  case PROP_ACCESS_TOKEN:
    if (priv->access_token)
      g_free (priv->access_token);
    priv->access_token = g_value_dup_string (value);
    break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
oauth2_proxy_finalize (GObject *object)
{
  OAuth2ProxyPrivate *priv = ((OAuth2Proxy*)object)->priv;

  g_free (priv->client_id);
  g_free (priv->auth_endpoint);
  g_free (priv->access_token);

  G_OBJECT_CLASS (oauth2_proxy_parent_class)->finalize (object);
}

static void
oauth2_proxy_class_init (OAuth2ProxyClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  RestProxyClass *proxy_class = REST_PROXY_CLASS (klass);
  GParamSpec *pspec;

  g_type_class_add_private (klass, sizeof (OAuth2ProxyPrivate));

  object_class->get_property = oauth2_proxy_get_property;
  object_class->set_property = oauth2_proxy_set_property;
  object_class->finalize = oauth2_proxy_finalize;

  proxy_class->new_call = _new_call;

  pspec = g_param_spec_string ("client-id",  "client-id",
                               "The client (application) id", NULL,
                               G_PARAM_READWRITE|G_PARAM_CONSTRUCT_ONLY|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_CLIENT_ID,
                                   pspec);

  pspec = g_param_spec_string ("auth-endpoint",  "auth-endpoint",
                               "The authentication endpoint url", NULL,
                               G_PARAM_READWRITE|G_PARAM_CONSTRUCT_ONLY|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_AUTH_ENDPOINT,
                                   pspec);

  pspec = g_param_spec_string ("access-token",  "access-token",
                               "The request or access token", NULL,
                               G_PARAM_READWRITE|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_ACCESS_TOKEN,
                                   pspec);
}

static void
oauth2_proxy_init (OAuth2Proxy *proxy)
{
  proxy->priv = OAUTH2_PROXY_GET_PRIVATE (proxy);
}

/**
 * oauth2_proxy_new:
 * @client_id: the client (application) id
 * @auth_endpoint: the authentication endpoint URL
 * @url_format: the endpoint URL
 * @binding_required: whether the URL needs to be bound before calling
 *
 * Create a new #OAuth2Proxy for the specified endpoint @url_format, using the
 * specified API key and secret.
 *
 * This proxy won't have the Token set so will be unauthorised.  If the token is
 * unknown then the following steps should be taken to acquire an access token:
 * - Get the authentication url with oauth2_proxy_build_login_url()
 * - Display this url in an embedded browser widget
 * - wait for the browser widget to be redirected to the specified redirect_uri
 * - extract the token from the fragment of the redirected uri (using
 * convenience function oauth2_proxy_extract_access_token())
 * - set the token with oauth2_proxy_set_access_token()
 *
 * Set @binding_required to %TRUE if the URL contains string formatting
 * operations (for example "http://foo.com/%<!-- -->s".  These must be expanded
 * using rest_proxy_bind() before invoking the proxy.
 *
 * Returns: A new #OAuth2Proxy.
 */
RestProxy *
oauth2_proxy_new (const char *client_id,
                  const char *auth_endpoint,
                  const gchar *url_format,
                  gboolean binding_required)
{
  return g_object_new (OAUTH2_TYPE_PROXY,
                       "client-id", client_id,
                       "auth-endpoint", auth_endpoint,
                       "url-format", url_format,
                       "binding-required", binding_required,
                       NULL);
}

/**
 * oauth2_proxy_new_with_token:
 * @client_id: the client (application) id
 * @access_token: the Access Token
 * @auth_endpoint: the authentication endpoint URL
 * @url_format: the endpoint URL
 * @binding_required: whether the URL needs to be bound before calling
 *
 * Create a new #OAuth2Proxy for the specified endpoint @url_format, using the
 * specified client id
 *
 * @access_token is used for the Access Token, so if they are still valid then
 * this proxy is authorised.
 *
 * Set @binding_required to %TRUE if the URL contains string formatting
 * operations (for example "http://foo.com/%<!-- -->s".  These must be expanded
 * using rest_proxy_bind() before invoking the proxy.
 *
 * Returns: A new #OAuth2Proxy.
 */
RestProxy *
oauth2_proxy_new_with_token (const char *client_id,
                            const char *access_token,
                            const char *auth_endpoint,
                            const gchar *url_format,
                            gboolean binding_required)
{
  return g_object_new (OAUTH2_TYPE_PROXY,
                       "client-id", client_id,
                       "access-token", access_token,
                       "auth-endpoint", auth_endpoint,
                       "url-format", url_format,
                       "binding-required", binding_required,
                       NULL);
}

/* allocates a new string of the form "key=value" */
static void
append_query_param (gpointer key, gpointer value, gpointer user_data)
{
    GString *params = (GString*) user_data;
    char *encoded_val, *encoded_key;
    char *param;

    encoded_val = soup_uri_encode (value, EXTRA_CHARS_ENCODE);
    encoded_key = soup_uri_encode (key, EXTRA_CHARS_ENCODE);

    param = g_strdup_printf ("%s=%s", encoded_key, encoded_val);
    g_free (encoded_key);
    g_free (encoded_val);

    // if there's already a parameter in the string, we need to add a '&'
    // separator before adding the new param
    if (params->len)
        g_string_append_c (params, '&');
    g_string_append (params, param);
}

/**
 * oauth2_proxy_build_login_url_full:
 * @proxy: a OAuth2Proxy object
 * @redirect_uri: the uri to redirect to after the user authenticates
 * @extra_params: any extra parameters to add to the login url (e.g. facebook
 * uses 'scope=foo,bar' to request extended permissions).
 *
 * Builds a url at which the user can log in to the specified OAuth2-based web
 * service.  In general, this url should be displayed in an embedded browser
 * widget, and you should then intercept the browser's redirect to @redirect_uri
 * and extract the access token from the url fragment. After the access token
 * has been retrieved, call oauth2_proxy_set_access_token().  This must be done
 * before making any API calls to the service.
 *
 * See the oauth2 spec for more details about the "user-agent" authentication
 * flow.
 *
 * The @extra_params and @redirect_uri should not be uri-encoded, that will be
 * done automatically
 *
 * Returns: a newly allocated uri string
 */
char *
oauth2_proxy_build_login_url_full (OAuth2Proxy *proxy,
                                   const char* redirect_uri,
                                   GHashTable* extra_params)
{
    char *url;
    GString *params = 0;
    char *encoded_uri, *encoded_id;

    g_return_val_if_fail (proxy, NULL);
    g_return_val_if_fail (redirect_uri, NULL);

    if (extra_params && g_hash_table_size (extra_params) > 0) {
        params = g_string_new (NULL);
        g_hash_table_foreach (extra_params, append_query_param, params);
    }

    encoded_uri = soup_uri_encode (redirect_uri, EXTRA_CHARS_ENCODE);
    encoded_id = soup_uri_encode (proxy->priv->client_id, EXTRA_CHARS_ENCODE);

    url = g_strdup_printf ("%s?client_id=%s&redirect_uri=%s&type=user_agent",
                           proxy->priv->auth_endpoint, encoded_id,
                           encoded_uri);

    g_free (encoded_uri);
    g_free (encoded_id);

    if (params) {
        char * full_url = g_strdup_printf ("%s&%s", url, params->str);
        g_free (url);
        url = full_url;
        g_string_free (params, TRUE);
    }

    return url;
}

/**
 * oauth2_proxy_build_login_url:
 * @proxy: an OAuth2Proxy object
 * @redirect_uri: the uri to redirect to after the user authenticates
 *
 * Builds a url at which the user can log in to the specified OAuth2-based web
 * service.  See the documentation for oauth2_proxy_build_login_url_full() for
 * detailed information.
 *
 * Returns: a newly allocated uri string
 */
char *
oauth2_proxy_build_login_url (OAuth2Proxy *proxy,
                              const char* redirect_uri)
{
    return oauth2_proxy_build_login_url_full (proxy, redirect_uri, NULL);
}

/**
 * oauth2_proxy_get_access_token:
 * @proxy: an #OAuth2Proxy
 *
 * Get the current request or access token.
 *
 * Returns: the token, or %NULL if there is no token yet.  This string is owned
 * by #OAuth2Proxy and should not be freed.
 */
const char *
oauth2_proxy_get_access_token (OAuth2Proxy *proxy)
{
  return proxy->priv->access_token;
}

/**
 * oauth2_proxy_set_access_token:
 * @proxy: an #OAuth2Proxy
 * @access_token: the access token
 *
 * Set the access token.
 */
void
oauth2_proxy_set_access_token (OAuth2Proxy *proxy, const char *access_token)
{
  g_return_if_fail (OAUTH2_IS_PROXY (proxy));

  if (proxy->priv->access_token)
    g_free (proxy->priv->access_token);

  proxy->priv->access_token = g_strdup (access_token);
}

/**
 * oauth2_proxy_extract_access_token:
 * @url: the url which contains an access token in its fragment
 *
 * A utility function to extract the access token from the url that results from
 * the redirection after the user authenticates
 */
char *
oauth2_proxy_extract_access_token (const char *url)
{
  GHashTable *params;
  char *token = NULL;
  SoupURI *soupuri = soup_uri_new (url);

  if (soupuri->fragment != NULL) {
    params = soup_form_decode (soupuri->fragment);

    if (params) {
      char *encoded = g_hash_table_lookup (params, "access_token");
      if (encoded)
        token = soup_uri_decode (encoded);

      g_hash_table_destroy (params);
    }
  }

  return token;
}
