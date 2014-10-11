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
#if WITH_GNOME
#include <libsoup/soup-gnome.h>
#endif

#include "rest-marshal.h"
#include "rest-proxy-auth-private.h"
#include "rest-proxy.h"
#include "rest-private.h"

G_DEFINE_TYPE (RestProxy, rest_proxy, G_TYPE_OBJECT)

#define GET_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), REST_TYPE_PROXY, RestProxyPrivate))

typedef struct _RestProxyPrivate RestProxyPrivate;

struct _RestProxyPrivate {
  gchar *url_format;
  gchar *url;
  gchar *user_agent;
  gchar *username;
  gchar *password;
  gboolean binding_required;
  SoupSession *session;
  SoupSession *session_sync;
  gboolean disable_cookies;
  char *ssl_ca_file;
};

enum
{
  PROP0 = 0,
  PROP_URL_FORMAT,
  PROP_BINDING_REQUIRED,
  PROP_USER_AGENT,
  PROP_DISABLE_COOKIES,
  PROP_USERNAME,
  PROP_PASSWORD,
  PROP_SSL_STRICT,
  PROP_SSL_CA_FILE
};

enum {
  AUTHENTICATE,
  LAST_SIGNAL
};

static guint signals[LAST_SIGNAL] = { 0 };


static gboolean _rest_proxy_simple_run_valist (RestProxy *proxy, 
                                               char     **payload, 
                                               goffset   *len,
                                               GError   **error,
                                               va_list    params);

static RestProxyCall *_rest_proxy_new_call (RestProxy *proxy);

static gboolean _rest_proxy_bind_valist (RestProxy *proxy,
                                         va_list    params);

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
    case PROP_USER_AGENT:
      g_value_set_string (value, priv->user_agent);
      break;
    case PROP_DISABLE_COOKIES:
      g_value_set_boolean (value, priv->disable_cookies);
      break;
    case PROP_USERNAME:
      g_value_set_string (value, priv->username);
      break;
    case PROP_PASSWORD:
      g_value_set_string (value, priv->password);
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
    case PROP_USER_AGENT:
      g_free (priv->user_agent);
      priv->user_agent = g_value_dup_string (value);
      break;
    case PROP_DISABLE_COOKIES:
      priv->disable_cookies = g_value_get_boolean (value);
      break;
    case PROP_USERNAME:
      g_free (priv->username);
      priv->username = g_value_dup_string (value);
      break;
    case PROP_PASSWORD:
      g_free (priv->password);
      priv->password = g_value_dup_string (value);
      break;
    case PROP_SSL_STRICT:
      g_object_set (G_OBJECT(priv->session),
                    "ssl-strict", g_value_get_boolean (value),
                    NULL);
      g_object_set (G_OBJECT(priv->session_sync),
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

  if (priv->session)
  {
    g_object_unref (priv->session);
    priv->session = NULL;
  }

  if (priv->session_sync)
  {
    g_object_unref (priv->session_sync);
    priv->session_sync = NULL;
  }

  G_OBJECT_CLASS (rest_proxy_parent_class)->dispose (object);
}

static gboolean
default_authenticate_cb (RestProxy *self,
                         G_GNUC_UNUSED RestProxyAuth *auth,
                         gboolean retrying)
{
  /* We only want to try the credentials once, otherwise we get in an
   * infinite loop with failed credentials, retrying the same invalid
   * ones again and again
   */
  return !retrying;
}

static void
authenticate (RestProxy   *self,
              SoupMessage *msg,
              SoupAuth    *soup_auth,
              gboolean     retrying,
              SoupSession *session)
{
  RestProxyPrivate *priv = GET_PRIVATE (self);
  RestProxyAuth *rest_auth;
  gboolean try_auth;

  rest_auth = rest_proxy_auth_new (self, session, msg, soup_auth);
  g_signal_emit(self, signals[AUTHENTICATE], 0, rest_auth, retrying, &try_auth);
  if (try_auth && !rest_proxy_auth_is_paused (rest_auth))
    soup_auth_authenticate (soup_auth, priv->username, priv->password);
  g_object_unref (G_OBJECT (rest_auth));
}

static void
rest_proxy_constructed (GObject *object)
{
  RestProxyPrivate *priv = GET_PRIVATE (object);

  if (!priv->disable_cookies) {
    SoupSessionFeature *cookie_jar =
      (SoupSessionFeature *)soup_cookie_jar_new ();
    soup_session_add_feature (priv->session, cookie_jar);
    soup_session_add_feature (priv->session_sync, cookie_jar);
    g_object_unref (cookie_jar);
  }

  if (REST_DEBUG_ENABLED(PROXY)) {
    SoupSessionFeature *logger = (SoupSessionFeature*)soup_logger_new (SOUP_LOGGER_LOG_BODY, 0);
    soup_session_add_feature (priv->session, logger);
    g_object_unref (logger);

    logger = (SoupSessionFeature*)soup_logger_new (SOUP_LOGGER_LOG_BODY, 0);
    soup_session_add_feature (priv->session_sync, logger);
    g_object_unref (logger);
  }

  /* session lifetime is same as self, no need to keep signalid */
  g_signal_connect_swapped (priv->session, "authenticate",
                            G_CALLBACK(authenticate), object);
  g_signal_connect_swapped (priv->session_sync, "authenticate",
                            G_CALLBACK(authenticate), object);
}

static void
rest_proxy_finalize (GObject *object)
{
  RestProxyPrivate *priv = GET_PRIVATE (object);

  g_free (priv->url);
  g_free (priv->url_format);
  g_free (priv->user_agent);
  g_free (priv->username);
  g_free (priv->password);
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

  g_type_class_add_private (klass, sizeof (RestProxyPrivate));

  object_class->get_property = rest_proxy_get_property;
  object_class->set_property = rest_proxy_set_property;
  object_class->dispose = rest_proxy_dispose;
  object_class->constructed = rest_proxy_constructed;
  object_class->finalize = rest_proxy_finalize;

  proxy_class->simple_run_valist = _rest_proxy_simple_run_valist;
  proxy_class->new_call = _rest_proxy_new_call;
  proxy_class->bind_valist = _rest_proxy_bind_valist;

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

  pspec = g_param_spec_string ("user-agent",
                               "user-agent",
                               "The User-Agent of the client",
                               NULL,
                               G_PARAM_READWRITE);
  g_object_class_install_property (object_class,
                                   PROP_USER_AGENT,
                                   pspec);

  pspec = g_param_spec_boolean ("disable-cookies",
                                "disable-cookies",
                                "Whether to disable cookie support",
                                FALSE,
                                G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY);
  g_object_class_install_property (object_class,
                                   PROP_DISABLE_COOKIES,
                                   pspec);

  pspec = g_param_spec_string ("username",
                               "username",
                               "The username for authentication",
                               NULL,
                               G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_USERNAME,
                                   pspec);

  pspec = g_param_spec_string ("password",
                               "password",
                               "The password for authentication",
                               NULL,
                               G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_PASSWORD,
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

  /**
   * RestProxy::authenticate:
   * @proxy: the proxy
   * @auth: authentication state
   * @retrying: %TRUE if this is the second (or later) attempt
   *
   * Emitted when the proxy requires authentication. If
   * credentials are available, set the 'username' and 'password'
   * properties on @proxy and return %TRUE from the callback.
   * This will cause the signal emission to stop, and librest will
   * try to connect with these credentials
   * If these credentials fail, the signal will be
   * emitted again, with @retrying set to %TRUE, which will
   * continue until %FALSE is returned from the callback.
   *
   * If you call rest_proxy_auth_pause() on @auth before
   * returning, then you can the authentication credentials on
   * the #RestProxy object asynchronously. You have to make sure
   * that @auth does not get destroyed with g_object_ref().
   * You can then unpause the authentication with
   * rest_proxy_auth_unpause() when everything is ready for it
   * to continue.
   **/
  signals[AUTHENTICATE] =
      g_signal_new ("authenticate",
                    G_OBJECT_CLASS_TYPE (object_class),
                    G_SIGNAL_RUN_LAST,
                    G_STRUCT_OFFSET (RestProxyClass, authenticate),
                    g_signal_accumulator_true_handled, NULL,
                    g_cclosure_user_marshal_BOOLEAN__OBJECT_BOOLEAN,
                    G_TYPE_BOOLEAN, 2,
                    REST_TYPE_PROXY_AUTH,
                    G_TYPE_BOOLEAN);

  proxy_class->authenticate = default_authenticate_cb;
}

static void
rest_proxy_init (RestProxy *self)
{
  RestProxyPrivate *priv = GET_PRIVATE (self);

  priv->session = soup_session_async_new ();
  priv->session_sync = soup_session_sync_new ();

#ifdef REST_SYSTEM_CA_FILE
  /* with ssl-strict (defaults TRUE) setting ssl-ca-file forces all
   * certificates to be trusted */
  g_object_set (priv->session,
                "ssl-ca-file", REST_SYSTEM_CA_FILE,
                NULL);
  g_object_set (priv->session_sync,
                "ssl-ca-file", REST_SYSTEM_CA_FILE,
                NULL);
#endif
  g_object_bind_property (self, "ssl-ca-file",
                          priv->session, "ssl-ca-file",
                          G_BINDING_BIDIRECTIONAL);
  g_object_bind_property (self, "ssl-ca-file",
                          priv->session_sync, "ssl-ca-file",
                          G_BINDING_BIDIRECTIONAL);

#if WITH_GNOME
  soup_session_add_feature_by_type (priv->session,
                                    SOUP_TYPE_PROXY_RESOLVER_GNOME);
  soup_session_add_feature_by_type (priv->session_sync,
                                    SOUP_TYPE_PROXY_RESOLVER_GNOME);
#endif
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
  return g_object_new (REST_TYPE_PROXY,
                       "url-format", url_format,
                       "binding-required", binding_required,
                       NULL);
}

/**
 * rest_proxy_new_with_authentication:
 * @url_format: the endpoint URL
 * @binding_required: whether the URL needs to be bound before calling
 * @username: the username provided by the user or client
 * @password: the password provided by the user or client
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
rest_proxy_new_with_authentication (const gchar *url_format,
                                    gboolean     binding_required,
                                    const gchar *username,
                                    const gchar *password)
{
  return g_object_new (REST_TYPE_PROXY,
                       "url-format", url_format,
                       "binding-required", binding_required,
                       "username", username,
                       "password", password,
                       NULL);
}

static gboolean
_rest_proxy_bind_valist (RestProxy *proxy,
                         va_list    params)
{
  RestProxyPrivate *priv = GET_PRIVATE (proxy);

  g_return_val_if_fail (proxy != NULL, FALSE);
  g_return_val_if_fail (priv->url_format != NULL, FALSE);
  g_return_val_if_fail (priv->binding_required == TRUE, FALSE);

  g_free (priv->url);

  priv->url = g_strdup_vprintf (priv->url_format, params);

  return TRUE;
}


gboolean
rest_proxy_bind_valist (RestProxy *proxy,
                        va_list    params)
{
  RestProxyClass *proxy_class = REST_PROXY_GET_CLASS (proxy);

  return proxy_class->bind_valist (proxy, params);
}

gboolean
rest_proxy_bind (RestProxy *proxy, ...)
{
  g_return_val_if_fail (REST_IS_PROXY (proxy), FALSE);

  gboolean res;
  va_list params;

  va_start (params, proxy);
  res = rest_proxy_bind_valist (proxy, params);
  va_end (params);

  return res;
}

void
rest_proxy_set_user_agent (RestProxy  *proxy,
                           const char *user_agent)
{
  g_return_if_fail (REST_IS_PROXY (proxy));

  g_object_set (proxy, "user-agent", user_agent, NULL);
}

const gchar *
rest_proxy_get_user_agent (RestProxy *proxy)
{
  RestProxyPrivate *priv;

  g_return_val_if_fail (REST_IS_PROXY (proxy), NULL);

  priv = GET_PRIVATE (proxy);

  return priv->user_agent;
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
  RestProxyPrivate *priv;

  g_return_if_fail (REST_IS_PROXY(proxy));
  priv = GET_PRIVATE (proxy);
  g_return_if_fail (priv->session != NULL);
  g_return_if_fail (priv->session_sync != NULL);

  soup_session_add_feature (priv->session, feature);
  soup_session_add_feature (priv->session_sync, feature);
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
  RestProxyClass *proxy_class = REST_PROXY_GET_CLASS (proxy);
  return proxy_class->new_call (proxy);
}

gboolean
_rest_proxy_get_binding_required (RestProxy *proxy)
{
  RestProxyPrivate *priv;

  g_return_val_if_fail (REST_IS_PROXY (proxy), FALSE);

  priv = GET_PRIVATE (proxy);

  return priv->binding_required;
}

const gchar *
_rest_proxy_get_bound_url (RestProxy *proxy)
{
  RestProxyPrivate *priv;

  g_return_val_if_fail (REST_IS_PROXY (proxy), NULL);

  priv = GET_PRIVATE (proxy);

  if (!priv->url && !priv->binding_required)
  {
    priv->url = g_strdup (priv->url_format);
  }

  return priv->url;
}

static gboolean
_rest_proxy_simple_run_valist (RestProxy *proxy, 
                               gchar     **payload, 
                               goffset   *len,
                               GError   **error,
                               va_list    params)
{
  RestProxyCall *call;
  gboolean ret;

  g_return_val_if_fail (REST_IS_PROXY (proxy), FALSE);
  g_return_val_if_fail (payload, FALSE);

  call = rest_proxy_new_call (proxy);

  rest_proxy_call_add_params_from_valist (call, params);

  ret = rest_proxy_call_run (call, NULL, error);
  if (ret) {
    *payload = g_strdup (rest_proxy_call_get_payload (call));
    if (len) *len = rest_proxy_call_get_payload_length (call);
  } else {
    *payload = NULL;
    if (len) *len = 0;
  }
 
  g_object_unref (call);

  return ret;
}

gboolean
rest_proxy_simple_run_valist (RestProxy *proxy, 
                              char     **payload, 
                              goffset   *len,
                              GError   **error,
                              va_list    params)
{
  RestProxyClass *proxy_class = REST_PROXY_GET_CLASS (proxy);
  return proxy_class->simple_run_valist (proxy, payload, len, error, params);
}

gboolean
rest_proxy_simple_run (RestProxy *proxy, 
                       gchar    **payload,
                       goffset   *len,
                       GError   **error,
                       ...)
{
  va_list params;
  gboolean ret;

  g_return_val_if_fail (REST_IS_PROXY (proxy), FALSE);
  g_return_val_if_fail (payload, FALSE);

  va_start (params, error);
  ret = rest_proxy_simple_run_valist (proxy,
                                      payload,
                                      len,
                                      error,
                                      params);
  va_end (params);

  return ret;
}

void
_rest_proxy_queue_message (RestProxy   *proxy,
                           SoupMessage *message,
                           SoupSessionCallback callback,
                           gpointer user_data)
{
  RestProxyPrivate *priv;

  g_return_if_fail (REST_IS_PROXY (proxy));
  g_return_if_fail (SOUP_IS_MESSAGE (message));

  priv = GET_PRIVATE (proxy);

  soup_session_queue_message (priv->session,
                              message,
                              callback,
                              user_data);
}

void
_rest_proxy_cancel_message (RestProxy   *proxy,
                            SoupMessage *message)
{
  RestProxyPrivate *priv;

  g_return_if_fail (REST_IS_PROXY (proxy));
  g_return_if_fail (SOUP_IS_MESSAGE (message));

  priv = GET_PRIVATE (proxy);
  soup_session_cancel_message (priv->session,
                               message,
                               SOUP_STATUS_CANCELLED);
}

guint
_rest_proxy_send_message (RestProxy   *proxy,
                          SoupMessage *message)
{
  RestProxyPrivate *priv;

  g_return_val_if_fail (REST_IS_PROXY (proxy), 0);
  g_return_val_if_fail (SOUP_IS_MESSAGE (message), 0);

  priv = GET_PRIVATE (proxy);

  return soup_session_send_message (priv->session_sync, message);
}
