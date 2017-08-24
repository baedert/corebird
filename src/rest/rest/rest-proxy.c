/*
 * librest - RESTful web services access
 * Copyright (c) 2008, 2009, Intel Corporation.
 *
 * Authors: Rob Bradford <rob@linux.intel.com>
 *          Ross Burton <ross@linux.intel.com>
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
#include <string.h>

#include <libsoup/soup.h>

#include "rest-proxy.h"
#include "rest-private.h"


#define GET_PRIVATE(o) rest_proxy_get_instance_private(REST_PROXY(o))

typedef struct _RestProxyPrivate RestProxyPrivate;

struct _RestProxyPrivate {
  gchar *url_format;
  gchar *url;
  gboolean binding_required;
  SoupSession *session;
  gboolean disable_cookies;
  char *ssl_ca_file;
};


G_DEFINE_TYPE_WITH_PRIVATE (RestProxy, rest_proxy, G_TYPE_OBJECT)

enum
{
  PROP0 = 0,
  PROP_URL_FORMAT,
  PROP_BINDING_REQUIRED,
  PROP_DISABLE_COOKIES,
  PROP_SSL_STRICT,
  PROP_SSL_CA_FILE
};

static RestProxyCall *_rest_proxy_new_call (RestProxy *proxy);

GQuark
rest_proxy_error_quark (void)
{
  return g_quark_from_static_string ("rest-proxy-error-quark");
}

static void
rest_proxy_get_property (GObject   *object,
                         guint      property_id,
                         GValue     *value,
                         GParamSpec *pspec)
{
  RestProxyPrivate *priv = GET_PRIVATE (object);

  switch (property_id) {
    case PROP_URL_FORMAT:
      g_value_set_string (value, priv->url_format);
      break;
    case PROP_BINDING_REQUIRED:
      g_value_set_boolean (value, priv->binding_required);
      break;
    case PROP_DISABLE_COOKIES:
      g_value_set_boolean (value, priv->disable_cookies);
      break;
    case PROP_SSL_STRICT: {
      gboolean ssl_strict;
      g_object_get (G_OBJECT(priv->session),
                    "ssl-strict", &ssl_strict,
                    NULL);
      g_value_set_boolean (value, ssl_strict);
      break;
    }
    case PROP_SSL_CA_FILE:
      g_value_set_string (value, priv->ssl_ca_file);
      break;

  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
rest_proxy_set_property (GObject      *object,
                         guint         property_id,
                         const GValue *value,
                         GParamSpec   *pspec)
{
  RestProxyPrivate *priv = GET_PRIVATE (object);

  switch (property_id) {
    case PROP_URL_FORMAT:
      g_free (priv->url_format);
      priv->url_format = g_value_dup_string (value);

      /* Clear the cached url */
      g_free (priv->url);
      priv->url = NULL;
      break;
    case PROP_BINDING_REQUIRED:
      priv->binding_required = g_value_get_boolean (value);

      /* Clear cached url */
      g_free (priv->url);
      priv->url = NULL;
      break;
    case PROP_DISABLE_COOKIES:
      priv->disable_cookies = g_value_get_boolean (value);
      break;
    case PROP_SSL_STRICT:
      g_object_set (G_OBJECT(priv->session),
                    "ssl-strict", g_value_get_boolean (value),
                    NULL);
      break;
    case PROP_SSL_CA_FILE:
      g_free(priv->ssl_ca_file);
      priv->ssl_ca_file = g_value_dup_string (value);
      break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
rest_proxy_dispose (GObject *object)
{
  RestProxyPrivate *priv = GET_PRIVATE (object);

  g_clear_object (&priv->session);

  G_OBJECT_CLASS (rest_proxy_parent_class)->dispose (object);
}

static void
rest_proxy_constructed (GObject *object)
{
  RestProxyPrivate *priv = GET_PRIVATE (object);

  if (!priv->disable_cookies) {
    SoupSessionFeature *cookie_jar =
      (SoupSessionFeature *)soup_cookie_jar_new ();
    soup_session_add_feature (priv->session, cookie_jar);
    g_object_unref (cookie_jar);
  }

  if (REST_DEBUG_ENABLED(PROXY)) {
    SoupSessionFeature *logger = (SoupSessionFeature*)soup_logger_new (SOUP_LOGGER_LOG_BODY, 0);
    soup_session_add_feature (priv->session, logger);
    g_object_unref (logger);
  }
}

static void
rest_proxy_finalize (GObject *object)
{
  RestProxyPrivate *priv = GET_PRIVATE (object);

  g_free (priv->url);
  g_free (priv->url_format);
  g_free (priv->ssl_ca_file);

  G_OBJECT_CLASS (rest_proxy_parent_class)->finalize (object);
}

static void
rest_proxy_class_init (RestProxyClass *klass)
{
  GParamSpec *pspec;
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  RestProxyClass *proxy_class = REST_PROXY_CLASS (klass);

  _rest_setup_debugging ();

  object_class->get_property = rest_proxy_get_property;
  object_class->set_property = rest_proxy_set_property;
  object_class->dispose = rest_proxy_dispose;
  object_class->constructed = rest_proxy_constructed;
  object_class->finalize = rest_proxy_finalize;

  proxy_class->new_call = _rest_proxy_new_call;

  pspec = g_param_spec_string ("url-format", 
                               "url-format",
                               "Format string for the RESTful url",
                               NULL,
                               G_PARAM_READWRITE);
  g_object_class_install_property (object_class, 
                                   PROP_URL_FORMAT,
                                   pspec);

  pspec = g_param_spec_boolean ("binding-required",
                                "binding-required",
                                "Whether the URL format requires binding",
                                FALSE,
                                G_PARAM_READWRITE);
  g_object_class_install_property (object_class,
                                   PROP_BINDING_REQUIRED,
                                   pspec);

  pspec = g_param_spec_boolean ("disable-cookies",
                                "disable-cookies",
                                "Whether to disable cookie support",
                                FALSE,
                                G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY);
  g_object_class_install_property (object_class,
                                   PROP_DISABLE_COOKIES,
                                   pspec);

  pspec = g_param_spec_boolean ("ssl-strict",
                                "Strictly validate SSL certificates",
                                "Whether certificate errors should be considered a connection error",
                                TRUE,
                                G_PARAM_READWRITE);
  g_object_class_install_property (object_class,
                                   PROP_SSL_STRICT,
                                   pspec);

  pspec = g_param_spec_string ("ssl-ca-file",
                               "SSL CA file",
                               "File containing SSL CA certificates.",
                               NULL,
                               G_PARAM_READWRITE);
  g_object_class_install_property (object_class,
                                   PROP_SSL_CA_FILE,
                                   pspec);
}

static void
rest_proxy_init (RestProxy *self)
{
  RestProxyPrivate *priv = GET_PRIVATE (self);

  priv->session = soup_session_new ();

#ifdef REST_SYSTEM_CA_FILE
  /* with ssl-strict (defaults TRUE) setting ssl-ca-file forces all
   * certificates to be trusted */
  g_object_set (priv->session,
                "ssl-ca-file", REST_SYSTEM_CA_FILE,
                NULL);
#endif
  g_object_bind_property (self, "ssl-ca-file",
                          priv->session, "ssl-ca-file",
                          G_BINDING_BIDIRECTIONAL);
}

/**
 * rest_proxy_new:
 * @url_format: the endpoint URL
 * @binding_required: whether the URL needs to be bound before calling
 *
 * Create a new #RestProxy for the specified endpoint @url_format, using the
 * "GET" method.
 *
 * Set @binding_required to %TRUE if the URL contains string formatting
 * operations (for example "http://foo.com/%<!-- -->s".  These must be expanded
 * using rest_proxy_bind() before invoking the proxy.
 *
 * Returns: A new #RestProxy.
 */
RestProxy *
rest_proxy_new (const gchar *url_format,
                gboolean     binding_required)
{
  g_return_val_if_fail (url_format != NULL, NULL);

  return g_object_new (REST_TYPE_PROXY,
                       "url-format", url_format,
                       "binding-required", binding_required,
                       NULL);
}

/**
 * rest_proxy_add_soup_feature:
 * @proxy: The #RestProxy
 * @feature: A #SoupSessionFeature
 *
 * This method can be used to add specific features to the #SoupSession objects
 * that are used by librest for its HTTP connections. For example, if one needs
 * extensive control over the cookies which are used for the REST HTTP
 * communication, it's possible to get full access to libsoup cookie API by
 * using
 *
 *   <programlisting>
 *   RestProxy *proxy = g_object_new(REST_TYPE_PROXY,
 *                                   "url-format", url,
 *                                   "disable-cookies", TRUE,
 *                                   NULL);
 *   SoupSessionFeature *cookie_jar = SOUP_SESSION_FEATURE(soup_cookie_jar_new ());
 *   rest_proxy_add_soup_feature(proxy, cookie_jar);
 *   </programlisting>
 *
 * Since: 0.7.92
 */
void
rest_proxy_add_soup_feature (RestProxy *proxy, SoupSessionFeature *feature)
{
  RestProxyPrivate *priv = GET_PRIVATE (proxy);

  g_return_if_fail (REST_IS_PROXY(proxy));
  g_return_if_fail (feature != NULL);
  g_return_if_fail (priv->session != NULL);

  soup_session_add_feature (priv->session, feature);
}

static RestProxyCall *
_rest_proxy_new_call (RestProxy *proxy)
{
  RestProxyCall *call;

  call = g_object_new (REST_TYPE_PROXY_CALL,
                       "proxy", proxy,
                       NULL);

  return call;
}

/**
 * rest_proxy_new_call:
 * @proxy: the #RestProxy
 *
 * Create a new #RestProxyCall for making a call to the web service.  This call
 * is one-shot and should not be re-used for making multiple calls.
 *
 * Returns: (transfer full): a new #RestProxyCall.
 */
RestProxyCall *
rest_proxy_new_call (RestProxy *proxy)
{
  RestProxyClass *proxy_class;

  g_return_val_if_fail (REST_IS_PROXY (proxy), NULL);

  proxy_class = REST_PROXY_GET_CLASS (proxy);
  return proxy_class->new_call (proxy);
}

gboolean
_rest_proxy_get_binding_required (RestProxy *proxy)
{
  RestProxyPrivate *priv = GET_PRIVATE (proxy);

  g_return_val_if_fail (REST_IS_PROXY (proxy), FALSE);

  return priv->binding_required;
}

const gchar *
_rest_proxy_get_bound_url (RestProxy *proxy)
{
  RestProxyPrivate *priv = GET_PRIVATE (proxy);

  g_return_val_if_fail (REST_IS_PROXY (proxy), NULL);

  if (!priv->url && !priv->binding_required)
  {
    priv->url = g_strdup (priv->url_format);
  }

  return priv->url;
}

void
_rest_proxy_queue_message (RestProxy   *proxy,
                           SoupMessage *message,
                           SoupSessionCallback callback,
                           gpointer user_data)
{
  RestProxyPrivate *priv = GET_PRIVATE (proxy);

  g_return_if_fail (REST_IS_PROXY (proxy));
  g_return_if_fail (SOUP_IS_MESSAGE (message));

  soup_session_queue_message (priv->session,
                              message,
                              callback,
                              user_data);
}

void
_rest_proxy_cancel_message (RestProxy   *proxy,
                            SoupMessage *message)
{
  RestProxyPrivate *priv = GET_PRIVATE (proxy);

  g_return_if_fail (REST_IS_PROXY (proxy));
  g_return_if_fail (SOUP_IS_MESSAGE (message));

  soup_session_cancel_message (priv->session,
                               message,
                               SOUP_STATUS_CANCELLED);
}
