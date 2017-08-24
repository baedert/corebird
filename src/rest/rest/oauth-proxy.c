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

#include "rest-proxy.h"
#include <libsoup/soup.h>
#include "oauth-proxy.h"
#include "oauth-proxy-private.h"
#include "oauth-proxy-call.h"

G_DEFINE_TYPE (OAuthProxy, oauth_proxy, REST_TYPE_PROXY)

enum {
  PROP_0,
  PROP_CONSUMER_KEY,
  PROP_CONSUMER_SECRET,
  PROP_TOKEN,
  PROP_TOKEN_SECRET,
  PROP_SIGNATURE_HOST,
  PROP_SIGNATURE_METHOD,
};

static RestProxyCall *
_new_call (RestProxy *proxy)
{
  RestProxyCall *call;

  call = g_object_new (OAUTH_TYPE_PROXY_CALL,
                       "proxy", proxy,
                       NULL);

  return call;
}

static void
oauth_proxy_get_property (GObject *object, guint property_id,
                              GValue *value, GParamSpec *pspec)
{
  OAuthProxyPrivate *priv = PROXY_GET_PRIVATE (object);

  switch (property_id) {
  case PROP_CONSUMER_KEY:
    g_value_set_string (value, priv->consumer_key);
    break;
  case PROP_CONSUMER_SECRET:
    g_value_set_string (value, priv->consumer_secret);
    break;
  case PROP_TOKEN:
    g_value_set_string (value, priv->token);
    break;
  case PROP_TOKEN_SECRET:
    g_value_set_string (value, priv->token_secret);
    break;
  case PROP_SIGNATURE_HOST:
    g_value_set_string (value, priv->signature_host);
    break;
  case PROP_SIGNATURE_METHOD:
    g_value_set_enum (value, priv->method);
    break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
oauth_proxy_set_property (GObject *object, guint property_id,
                              const GValue *value, GParamSpec *pspec)
{
  OAuthProxyPrivate *priv = PROXY_GET_PRIVATE (object);

  switch (property_id) {
  case PROP_CONSUMER_KEY:
    if (priv->consumer_key)
      g_free (priv->consumer_key);
    priv->consumer_key = g_value_dup_string (value);
    break;
  case PROP_CONSUMER_SECRET:
    if (priv->consumer_secret)
      g_free (priv->consumer_secret);
    priv->consumer_secret = g_value_dup_string (value);
    break;
  case PROP_TOKEN:
    if (priv->token)
      g_free (priv->token);
    priv->token = g_value_dup_string (value);
    break;
  case PROP_TOKEN_SECRET:
    if (priv->token_secret)
      g_free (priv->token_secret);
    priv->token_secret = g_value_dup_string (value);
    break;
  case PROP_SIGNATURE_HOST:
    if (priv->signature_host)
      g_free (priv->signature_host);
    priv->signature_host = g_value_dup_string (value);
    break;
  case PROP_SIGNATURE_METHOD:
    priv->method = g_value_get_enum (value);
    break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
oauth_proxy_finalize (GObject *object)
{
  OAuthProxyPrivate *priv = PROXY_GET_PRIVATE (object);

  g_free (priv->consumer_key);
  g_free (priv->consumer_secret);
  g_free (priv->token);
  g_free (priv->token_secret);
  g_free (priv->verifier);
  g_free (priv->service_url);

  G_OBJECT_CLASS (oauth_proxy_parent_class)->finalize (object);
}

#ifndef G_PARAM_STATIC_STRINGS
#define G_PARAM_STATIC_STRINGS (G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB)
#endif

static void
oauth_proxy_class_init (OAuthProxyClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  RestProxyClass *proxy_class = REST_PROXY_CLASS (klass);
  GParamSpec *pspec;

  g_type_class_add_private (klass, sizeof (OAuthProxyPrivate));

  object_class->get_property = oauth_proxy_get_property;
  object_class->set_property = oauth_proxy_set_property;
  object_class->finalize = oauth_proxy_finalize;

  proxy_class->new_call = _new_call;

  pspec = g_param_spec_string ("consumer-key",  "consumer-key",
                               "The consumer key", NULL,
                               G_PARAM_READWRITE|G_PARAM_CONSTRUCT_ONLY|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_CONSUMER_KEY,
                                   pspec);

  pspec = g_param_spec_string ("consumer-secret",  "consumer-secret",
                               "The consumer secret", NULL,
                               G_PARAM_READWRITE|G_PARAM_CONSTRUCT_ONLY|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_CONSUMER_SECRET,
                                   pspec);

  pspec = g_param_spec_string ("token",  "token",
                               "The request or access token", NULL,
                               G_PARAM_READWRITE|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_TOKEN,
                                   pspec);

  pspec = g_param_spec_string ("token-secret",  "token-secret",
                               "The request or access token secret", NULL,
                               G_PARAM_READWRITE|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_TOKEN_SECRET,
                                   pspec);

  pspec = g_param_spec_string ("signature-host",  "signature-host",
                               "The base URL used in the signature string",
                               NULL, G_PARAM_READWRITE|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_SIGNATURE_HOST,
                                   pspec);

  pspec = g_param_spec_enum ("signature-method", "signature-method",
                             "Signature method used",
                             OAUTH_TYPE_SIGNATURE_METHOD, HMAC_SHA1,
                             G_PARAM_READWRITE|G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
                                   PROP_SIGNATURE_METHOD,
                                   pspec);
}

static void
oauth_proxy_init (OAuthProxy *self)
{
  PROXY_GET_PRIVATE (self)->method = HMAC_SHA1;
}

/**
 * oauth_proxy_new:
 * @consumer_key: the Consumer Key
 * @consumer_secret: the Consumer Secret
 * @url_format: the endpoint URL
 * @binding_required: whether the URL needs to be bound before calling
 *
 * Create a new #OAuthProxy for the specified endpoint @url_format, using the
 * specified API key and secret.
 *
 * This proxy won't have the Token or Token Secret set so as such will be
 * unauthorised.  If the tokens are unknown then oauth_proxy_request_token() and
 * oauth_proxy_access_token() should be called to do the OAuth authorisation, or
 * the tokens should be set using oauth_proxy_set_token() and
 * oauth_proxy_set_token_secret().
 *
 * Set @binding_required to %TRUE if the URL contains string formatting
 * operations (for example "http://foo.com/%<!-- -->s".  These must be expanded
 * using rest_proxy_bind() before invoking the proxy.
 *
 * Returns: A new #OAuthProxy.
 */
RestProxy *
oauth_proxy_new (const char *consumer_key,
                 const char *consumer_secret,
                 const gchar *url_format,
                 gboolean binding_required)
{
  return g_object_new (OAUTH_TYPE_PROXY,
                       "consumer-key", consumer_key,
                       "consumer-secret", consumer_secret,
                       "url-format", url_format,
                       "binding-required", binding_required,
                       NULL);
}

/**
 * oauth_proxy_new_with_token:
 * @consumer_key: the Consumer Key
 * @consumer_secret: the Consumer Secret
 * @token: the Access Token
 * @token_secret: the Token Secret
 * @url_format: the endpoint URL
 * @binding_required: whether the URL needs to be bound before calling
 *
 * Create a new #OAuthProxy for the specified endpoint @url_format, using the
 * specified API key and secret.
 *
 * @token and @token_secret are used for the Access Token and Token Secret, so
 * if they are still valid then this proxy is authorised.
 *
 * Set @binding_required to %TRUE if the URL contains string formatting
 * operations (for example "http://foo.com/%<!-- -->s".  These must be expanded
 * using rest_proxy_bind() before invoking the proxy.
 *
 * Returns: A new #OAuthProxy.
 */
RestProxy *
oauth_proxy_new_with_token (const char *consumer_key,
                            const char *consumer_secret,
                            const char *token,
                            const char *token_secret,
                            const gchar *url_format,
                            gboolean binding_required)
{
  return g_object_new (OAUTH_TYPE_PROXY,
                       "consumer-key", consumer_key,
                       "consumer-secret", consumer_secret,
                       "token", token,
                       "token-secret", token_secret,
                       "url-format", url_format,
                       "binding-required", binding_required,
                       NULL);
}

static void
request_token_cb (GObject      *source_object,
                  GAsyncResult *result,
                  gpointer      user_data)
{
  GTask *task = G_TASK (user_data);
  RestProxyCall *call = REST_PROXY_CALL (source_object);
  GError *error = NULL;
  gboolean call_status;

  call_status = rest_proxy_call_invoke_finish (call, result, &error);

  if (error != NULL) {
    g_task_return_error (task, error);
  } else {
    oauth_proxy_call_parse_token_response (OAUTH_PROXY_CALL (call));
    g_task_return_boolean (task, call_status);
  }

  g_object_unref (task);
}

/**
 * oauth_proxy_request_token_async:
 * @proxy: an #OAuthProxy
 * @function: (nullable): the function name to invoke
 * @callback_uri: (nullable): the callback URI
 * @callback: (scope async): a #OAuthProxyAuthCallback to invoke on completion
 * @user_data: user data to pass to @callback
 *
 * Perform the Request Token phase of OAuth, invoking @function (defaulting to
 * "request_token" if @function is NULL).
 *
 * The value of @callback depends on whether you wish to use OAuth 1.0 or 1.0a.
 * If you wish to use 1.0 then callback must be NULL.  To use 1.0a then
 * @callback should either be your callback URI, or "oob" (out-of-band).
 *
 * This method will return once the method has been queued, @callback will be
 * invoked when it has completed.
 */
void
oauth_proxy_request_token_async (OAuthProxy          *proxy,
                                 const char          *function,
                                 const char          *callback_uri,
                                 GCancellable        *cancellable,
                                 GAsyncReadyCallback  callback,
                                 gpointer             user_data)
{
  RestProxyCall *call;
  GTask *task;

  call = rest_proxy_new_call (REST_PROXY (proxy));
  rest_proxy_call_set_function (call, function ? function : "request_token");
  rest_proxy_call_set_method (call, "POST");

  if (callback_uri)
    rest_proxy_call_add_param (call, "oauth_callback", callback_uri);

  task = g_task_new (proxy, cancellable, callback, user_data);

  rest_proxy_call_invoke_async (call, cancellable, request_token_cb, task);

  g_object_unref (call);
}

/**
 * oauth_proxy_request_token_finish:
 * @proxy: a #OAuthProxy
 * @result: a #GAsyncResult
 * @error: a #GError or %NULL
 *
 * Finishes an operation started with oauth_proxy_request_token_async()
 *
 * Returns: %TRUE on success, %FALSE if an error occurred, in which case
 *   @error will be set.
 */
gboolean
oauth_proxy_request_token_finish (OAuthProxy *proxy,
                                  GAsyncResult *result,
                                  GError **error)
{
  g_return_val_if_fail (OAUTH_IS_PROXY (proxy), FALSE);
  g_return_val_if_fail (g_task_is_valid (result, proxy), FALSE);

  return g_task_propagate_boolean (G_TASK (result), error);
}

static void
access_token_cb (GObject      *source_object,
                 GAsyncResult *result,
                 gpointer      user_data)
{
  GTask *task = G_TASK (user_data);
  RestProxyCall *call = REST_PROXY_CALL (source_object);
  GError *error = NULL;
  gboolean call_status;

  call_status = rest_proxy_call_invoke_finish (call, result, &error);

  if (error != NULL) {
    g_task_return_error (task, error);
  } else {
    oauth_proxy_call_parse_token_response (OAUTH_PROXY_CALL (call));
    g_task_return_boolean (task, call_status);
  }

  g_object_unref (task);
}

/**
 * oauth_proxy_access_token_async:
 * @proxy: an #OAuthProxy
 * @function: the function name to invoke
 * @verifier: the verifier
 * @callback: (scope async): a #OAuthProxyAuthCallback to invoke on completion
 * @user_data: user data to pass to @callback
 *
 * Perform the Access Token phase of OAuth, invoking @function (defaulting to
 * "access_token" if @function is NULL).
 *
 * @verifier is only used if you are using OAuth 1.0a.  This is either the
 * "oauth_verifier" parameter that was passed to your callback URI, or a string
 * that the user enters in some other manner (for example in a popup dialog) if
 * "oob" was passed to oauth_proxy_request_token().  For OAuth 1.0, pass %NULL.
 *
 * This method will return once the method has been queued, @callback will be
 * invoked when it has completed.
 */
void
oauth_proxy_access_token_async (OAuthProxy          *proxy,
                                const char          *function,
                                const char          *verifier,
                                GCancellable        *cancellable,
                                GAsyncReadyCallback  callback,
                                gpointer             user_data)
{
  RestProxyCall *call;
  GTask *task;

  call = rest_proxy_new_call (REST_PROXY (proxy));
  rest_proxy_call_set_function (call, function ? function : "access_token");
  rest_proxy_call_set_method (call, "POST");

  if (verifier)
    rest_proxy_call_add_param (call, "oauth_verifier", verifier);

  task = g_task_new (proxy, cancellable, callback, user_data);

  rest_proxy_call_invoke_async (call, cancellable, access_token_cb, task);
  g_object_unref (call);
}

gboolean
oauth_proxy_access_token_finish (OAuthProxy *proxy,
                                 GAsyncResult *result,
                                 GError **error)
{
  g_return_val_if_fail (OAUTH_IS_PROXY (proxy), FALSE);
  g_return_val_if_fail (g_task_is_valid (result, proxy), FALSE);

  return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * oauth_proxy_get_token:
 * @proxy: an #OAuthProxy
 *
 * Get the current request or access token.
 *
 * Returns: the token, or %NULL if there is no token yet.  This string is owned
 * by #OAuthProxy and should not be freed.
 */
const char *
oauth_proxy_get_token (OAuthProxy *proxy)
{
  OAuthProxyPrivate *priv = PROXY_GET_PRIVATE (proxy);
  return priv->token;
}

/**
 * oauth_proxy_set_token:
 * @proxy: an #OAuthProxy
 * @token: the access token
 *
 * Set the access token.
 */
void
oauth_proxy_set_token (OAuthProxy *proxy, const char *token)
{
  OAuthProxyPrivate *priv;

  g_return_if_fail (OAUTH_IS_PROXY (proxy));
  priv = PROXY_GET_PRIVATE (proxy);

  g_free (priv->token);
  priv->token = g_strdup (token);
}

/**
 * oauth_proxy_get_token_secret:
 * @proxy: an #OAuthProxy
 *
 * Get the current request or access token secret.
 *
 * Returns: the token secret, or %NULL if there is no token secret yet.  This
 * string is owned by #OAuthProxy and should not be freed.
 */
const char *
oauth_proxy_get_token_secret (OAuthProxy *proxy)
{
  OAuthProxyPrivate *priv = PROXY_GET_PRIVATE (proxy);
  return priv->token_secret;
}

/**
 * oauth_proxy_set_token_secret:
 * @proxy: an #OAuthProxy
 * @token_secret: the access token secret
 *
 * Set the access token secret.
 */
void
oauth_proxy_set_token_secret (OAuthProxy *proxy, const char *token_secret)
{
  OAuthProxyPrivate *priv;

  g_return_if_fail (OAUTH_IS_PROXY (proxy));
  priv = PROXY_GET_PRIVATE (proxy);

  if (priv->token_secret)
    g_free (priv->token_secret);

  priv->token_secret = g_strdup (token_secret);
}

/**
 * oauth_proxy_is_oauth10a:
 * @proxy: a valid #OAuthProxy
 *
 * Determines if the server supports OAuth 1.0a with this proxy. This is only
 * valid after oauth_proxy_request_token() or oauth_proxy_request_token_async()
 * has been called.
 *
 * Returns: %TRUE if the server supports OAuth 1.0a, %FALSE otherwise.
 */
gboolean
oauth_proxy_is_oauth10a (OAuthProxy *proxy)
{
  g_return_val_if_fail (OAUTH_IS_PROXY (proxy), FALSE);

  return PROXY_GET_PRIVATE (proxy)->oauth_10a;
}

/**
 * oauth_proxy_get_signature_host:
 * @proxy: an #OAuthProxy
 *
 * Get the signature hostname used when creating a signature base string.
 *
 * Returns: the signature hostname, or %NULL if there is none set.
 *  This string is owned by #OAuthProxy and should not be freed.
 */
const char *
oauth_proxy_get_signature_host (OAuthProxy *proxy)
{
  OAuthProxyPrivate *priv;

  g_return_val_if_fail (OAUTH_IS_PROXY (proxy), NULL);
  priv = PROXY_GET_PRIVATE (proxy);

  return priv->signature_host;
}

/**
 * oauth_proxy_set_signature_host:
 * @proxy: an #OAuthProxy
 * @signature_host: the signature host
 *
 * Set the signature hostname used when creating a signature base string.
 */
void
oauth_proxy_set_signature_host (OAuthProxy *proxy,
                                const char *signature_host)
{
  OAuthProxyPrivate *priv;

  g_return_if_fail (OAUTH_IS_PROXY (proxy));
  priv = PROXY_GET_PRIVATE (proxy);

  g_free (priv->signature_host);

  priv->signature_host = g_strdup (signature_host);
}

/**
 * oauth_proxy_new_echo_proxy:
 * @proxy: an #OAuthProxy
 * @service_url: the service URL
 * @url_format: the URL format
 * @binding_required: whether a binding is required
 *
 * Create a new <ulink
 * url="http://www.scribd.com/doc/26707268/OAuth-Echo-Identity-Veri%EF%AC%81cation-Delegation-Draft">OAuth
 * Echo</ulink> proxy.
 *
 * Returns: (transfer full): a new OAuth Echo proxy
 */
RestProxy *
oauth_proxy_new_echo_proxy (OAuthProxy  *proxy,
                            /* TODO: should this be a function on the base url? */
                            const char  *service_url,
                            const gchar *url_format,
                            gboolean     binding_required)
{
  OAuthProxy *echo_proxy;
  OAuthProxyPrivate *priv, *echo_priv;

  g_return_val_if_fail (OAUTH_IS_PROXY (proxy), NULL);
  g_return_val_if_fail (service_url, NULL);
  g_return_val_if_fail (url_format, NULL);

  priv = PROXY_GET_PRIVATE (proxy);

  echo_proxy = g_object_new (OAUTH_TYPE_PROXY,
                             "url-format", url_format,
                             "binding-required", binding_required,
                             "consumer-key", priv->consumer_key,
                             "consumer-secret", priv->consumer_secret,
                             "token", priv->token,
                             "token-secret", priv->token_secret,
                             NULL);
  echo_priv = PROXY_GET_PRIVATE (echo_proxy);

  echo_priv->oauth_echo = TRUE;
  echo_priv->service_url = g_strdup (service_url);

  return (RestProxy *)echo_proxy;
}

GType
oauth_signature_method_get_type (void)
{
  static GType enum_type_id = 0;
  if (G_UNLIKELY (!enum_type_id))
  {
    static const GEnumValue values[] =
    {
      { PLAINTEXT, "PLAINTEXT", "plaintext" },
      { HMAC_SHA1, "HMAC_SHA1", "hmac-sha1" },
      { 0, NULL, NULL }
    };
    enum_type_id = g_enum_register_static ("OAuthSignatureMethod", values);
  }
  return enum_type_id;
}

