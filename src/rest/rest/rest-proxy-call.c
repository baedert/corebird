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
#include "rest-proxy-call.h"
#include "rest-params.h"
#include <libsoup/soup.h>

#include "rest-private.h"
#include "rest-proxy-call-private.h"


struct _RestProxyCallAsyncClosure {
  RestProxyCall *call;
  RestProxyCallAsyncCallback callback;
  GObject *weak_object;
  gpointer userdata;
  SoupMessage *message;
};
typedef struct _RestProxyCallAsyncClosure RestProxyCallAsyncClosure;

struct _RestProxyCallContinuousClosure {
  RestProxyCall *call;
  RestProxyCallContinuousCallback callback;
  GObject *weak_object;
  gpointer userdata;
  SoupMessage *message;
};
typedef struct _RestProxyCallContinuousClosure RestProxyCallContinuousClosure;

struct _RestProxyCallUploadClosure {
  RestProxyCall *call;
  RestProxyCallUploadCallback callback;
  GObject *weak_object;
  gpointer userdata;
  SoupMessage *message;
  gssize uploaded;
};
typedef struct _RestProxyCallUploadClosure RestProxyCallUploadClosure;



#define GET_PRIVATE(o) ((RestProxyCallPrivate*)(rest_proxy_call_get_instance_private (REST_PROXY_CALL(o))))

struct _RestProxyCallPrivate {
  gchar *method;
  gchar *function;
  GHashTable *headers;
  RestParams *params;
  /* The real URL we're about to invoke */
  gchar *url;

  GHashTable *response_headers;
  goffset length;
  gchar *payload;

  GCancellable *cancellable;
  gulong cancel_sig;

  RestProxy *proxy;

  RestProxyCallAsyncClosure *cur_call_closure;
};
typedef struct _RestProxyCallPrivate RestProxyCallPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (RestProxyCall, rest_proxy_call, G_TYPE_OBJECT)


enum
{
  PROP_0 = 0,
  PROP_PROXY
};

GQuark
rest_proxy_call_error_quark (void)
{
  return g_quark_from_static_string ("rest-proxy-call-error-quark");
}

static void
rest_proxy_call_get_property (GObject    *object,
                              guint       property_id,
                              GValue     *value,
                              GParamSpec *pspec)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (object);

  switch (property_id) {
    case PROP_PROXY:
      g_value_set_object (value, priv->proxy);
      break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
rest_proxy_call_set_property (GObject      *object,
                              guint         property_id,
                              const GValue *value,
                              GParamSpec   *pspec)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (object);

  switch (property_id) {
    case PROP_PROXY:
      priv->proxy = g_value_dup_object (value);
      break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
rest_proxy_call_dispose (GObject *object)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (object);

  if (priv->cancellable)
    {
      g_signal_handler_disconnect (priv->cancellable, priv->cancel_sig);
      g_clear_object (&priv->cancellable);
    }

  g_clear_pointer (&priv->params, rest_params_free);
  g_clear_pointer (&priv->headers, g_hash_table_unref);
  g_clear_pointer (&priv->response_headers, g_hash_table_unref);
  g_clear_object (&priv->proxy);

  G_OBJECT_CLASS (rest_proxy_call_parent_class)->dispose (object);
}

static void
rest_proxy_call_finalize (GObject *object)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (object);

  g_free (priv->method);
  g_free (priv->function);

  g_free (priv->payload);

  g_free (priv->url);

  G_OBJECT_CLASS (rest_proxy_call_parent_class)->finalize (object);
}

static void
rest_proxy_call_class_init (RestProxyCallClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *pspec;

  object_class->get_property = rest_proxy_call_get_property;
  object_class->set_property = rest_proxy_call_set_property;
  object_class->dispose = rest_proxy_call_dispose;
  object_class->finalize = rest_proxy_call_finalize;

  pspec = g_param_spec_object ("proxy",
                               "proxy",
                               "Proxy for this call",
                               REST_TYPE_PROXY,
                               G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE);
  g_object_class_install_property (object_class, PROP_PROXY, pspec);
}

static void
rest_proxy_call_init (RestProxyCall *self)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (self);

  priv->method = g_strdup ("GET");

  priv->params = rest_params_new ();

  priv->headers = g_hash_table_new_full (g_str_hash,
                                         g_str_equal,
                                         g_free,
                                         g_free);
  priv->response_headers = g_hash_table_new_full (g_str_hash,
                                                  g_str_equal,
                                                  g_free,
                                                  g_free);
}

/**
 * rest_proxy_call_set_method:
 * @call: The #RestProxyCall
 * @method: The HTTP method to use
 *
 * Set the HTTP method to use when making the call, for example GET or POST.
 */
void
rest_proxy_call_set_method (RestProxyCall *call,
                            const gchar   *method)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);

  g_return_if_fail (REST_IS_PROXY_CALL (call));

  g_free (priv->method);

  if (method)
    priv->method = g_strdup (method);
  else
    priv->method = g_strdup ("GET");
}

/**
 * rest_proxy_call_get_method:
 * @call: The #RestProxyCall
 *
 * Get the HTTP method to use when making the call, for example GET or POST.
 */
const char *
rest_proxy_call_get_method (RestProxyCall *call)
{
  g_return_val_if_fail (REST_IS_PROXY_CALL (call), NULL);

  return GET_PRIVATE (call)->method;
}

/**
 * rest_proxy_call_set_function:
 * @call: The #RestProxyCall
 * @function: The function to call
 *
 * Set the REST "function" to call on the proxy.  This is appended to the URL,
 * so that for example a proxy with the URL
 * <literal>http://www.example.com/</literal> and the function
 * <literal>test</literal> would actually access the URL
 * <literal>http://www.example.com/test</literal>
 */
void
rest_proxy_call_set_function (RestProxyCall *call,
                              const gchar   *function)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);

  g_return_if_fail (REST_IS_PROXY_CALL (call));

  g_free (priv->function);
  priv->function = g_strdup (function);
}

/**
 * rest_proxy_call_get_function:
 * @call: The #RestProxyCall
 *
 * Get the REST function that is going to be called on the proxy.
 *
 * Returns: The REST "function" for the current call, see also
 * rest_proxy_call_set_function(). This string is owned by the #RestProxyCall
 * and should not be freed.
 * Since: 0.7.92
 */
const char *
rest_proxy_call_get_function (RestProxyCall *call)
{
  g_return_val_if_fail (REST_IS_PROXY_CALL (call), NULL);

  return GET_PRIVATE (call)->function;
}


/**
 * rest_proxy_call_add_header:
 * @call: The #RestProxyCall
 * @header: The name of the header to set
 * @value: The value of the header
 *
 * Add a header called @header with the value @value to the call.  If a
 * header with this name already exists, the new value will replace the old.
 */
void
rest_proxy_call_add_header (RestProxyCall *call,
                            const gchar   *header,
                            const gchar   *value)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);

  g_return_if_fail (REST_IS_PROXY_CALL (call));

  g_hash_table_insert (priv->headers,
                       g_strdup (header),
                       g_strdup (value));

}

void
rest_proxy_call_take_header (RestProxyCall *call,
                             const gchar   *header,
                             gchar         *value)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);

  g_return_if_fail (REST_IS_PROXY_CALL (call));

  g_hash_table_insert (priv->headers,
                       g_strdup (header),
                       value);
}

/**
 * rest_proxy_call_lookup_header:
 * @call: The #RestProxyCall
 * @header: The header name
 *
 * Get the value of the header called @header.
 *
 * Returns: The header value, or %NULL if it does not exist. This string is
 * owned by the #RestProxyCall and should not be freed.
 */
const gchar *
rest_proxy_call_lookup_header (RestProxyCall *call,
                               const gchar   *header)
{
  g_return_val_if_fail (REST_IS_PROXY_CALL (call), NULL);

  return g_hash_table_lookup (GET_PRIVATE (call)->headers, header);
}

/**
 * rest_proxy_call_remove_header:
 * @call: The #RestProxyCall
 * @header: The header name
 *
 * Remove the header named @header from the call.
 */
void
rest_proxy_call_remove_header (RestProxyCall *call,
                               const gchar   *header)
{
  g_return_if_fail (REST_IS_PROXY_CALL (call));

  g_hash_table_remove (GET_PRIVATE (call)->headers, header);
}

/**
 * rest_proxy_call_add_param:
 * @call: The #RestProxyCall
 * @name: The name of the parameter to set
 * @value: The value of the parameter
 *
 * Add a query parameter called @param with the string value @value to the call.
 * If a parameter with this name already exists, the new value will replace the
 * old.
 */
void
rest_proxy_call_add_param (RestProxyCall *call,
                           const gchar   *name,
                           const gchar   *value)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);
  RestParam *param;

  g_return_if_fail (REST_IS_PROXY_CALL (call));

  param = rest_param_new_string (name, REST_MEMORY_COPY, value);
  rest_params_add (priv->params, param);
}

void
rest_proxy_call_take_param (RestProxyCall *call,
                            const char    *name,
                            char          *value)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);
  RestParam *param;

  g_return_if_fail (REST_IS_PROXY_CALL (call));

  param = rest_param_new_string (name, REST_MEMORY_TAKE, value);
  rest_params_add (priv->params, param);
}

void
rest_proxy_call_add_param_full (RestProxyCall *call, RestParam *param)
{
  g_return_if_fail (REST_IS_PROXY_CALL (call));
  g_return_if_fail (param);

  rest_params_add (GET_PRIVATE (call)->params, param);
}

/**
 * rest_proxy_call_lookup_param:
 * @call: The #RestProxyCall
 * @name: The parameter name
 *
 * Get the value of the parameter called @name.
 *
 * Returns: The parameter value, or %NULL if it does not exist. This string is
 * owned by the #RestProxyCall and should not be freed.
 */
RestParam *
rest_proxy_call_lookup_param (RestProxyCall *call,
                              const gchar   *name)
{
  g_return_val_if_fail (REST_IS_PROXY_CALL (call), NULL);

  return rest_params_get (GET_PRIVATE (call)->params, name);
}

/**
 * rest_proxy_call_remove_param:
 * @call: The #RestProxyCall
 * @name: The parameter name
 *
 * Remove the parameter named @name from the call.
 */
void
rest_proxy_call_remove_param (RestProxyCall *call,
                              const gchar   *name)
{
  g_return_if_fail (REST_IS_PROXY_CALL (call));

  rest_params_remove (GET_PRIVATE (call)->params, name);
}

/**
 * rest_proxy_call_get_params:
 * @call: The #RestProxyCall
 *
 * Get the parameters as a #RestParams of parameter names to values.  The
 * returned value is owned by the RestProxyCall instance and should not
 * be freed by the caller.
 *
 * Returns: (transfer none): A #RestParams.
 */
RestParams *
rest_proxy_call_get_params (RestProxyCall *call)
{
  g_return_val_if_fail (REST_IS_PROXY_CALL (call), NULL);

  return GET_PRIVATE (call)->params;
}



static void _call_async_weak_notify_cb (gpointer *data,
                                        GObject  *dead_object);

static void
_populate_headers_hash_table (const gchar *name,
                              const gchar *value,
                              gpointer     userdata)
{
  GHashTable *headers = (GHashTable *)userdata;

  g_hash_table_insert (headers, g_strdup (name), g_strdup (value));
}

/* I apologise for this macro, but it saves typing ;-) */
#define error_helper(x) g_set_error_literal(error, REST_PROXY_ERROR, x, message->reason_phrase)
static void
_handle_error_from_message (SoupMessage *message, GError **error)
{
  if (message->status_code < 100)
  {
    switch (message->status_code)
    {
      case SOUP_STATUS_CANCELLED:
        error_helper (REST_PROXY_ERROR_CANCELLED);
        break;
      case SOUP_STATUS_CANT_RESOLVE:
      case SOUP_STATUS_CANT_RESOLVE_PROXY:
        error_helper (REST_PROXY_ERROR_RESOLUTION);
        break;
      case SOUP_STATUS_CANT_CONNECT:
      case SOUP_STATUS_CANT_CONNECT_PROXY:
        error_helper (REST_PROXY_ERROR_CONNECTION);
        break;
      case SOUP_STATUS_SSL_FAILED:
        error_helper (REST_PROXY_ERROR_SSL);
        break;
      case SOUP_STATUS_IO_ERROR:
        error_helper (REST_PROXY_ERROR_IO);
        break;
      case SOUP_STATUS_MALFORMED:
      case SOUP_STATUS_TRY_AGAIN:
      default:
        error_helper (REST_PROXY_ERROR_FAILED);
        break;
    }
  }
  else if (message->status_code >= 200 && message->status_code < 300)
  {
    /* Good */
    return;
  }
  else
  {
    /* If we are here we must be in some kind of HTTP error, lets try */
    g_set_error_literal (error,
                         REST_PROXY_ERROR,
                         message->status_code,
                         message->reason_phrase);
  }
}

static void
finish_call (RestProxyCall *call, SoupMessage *message, GError **error)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);

  g_assert (call);
  g_assert (message);

  /* Convert the soup headers in to hash */
  /* FIXME: Eeek..are you allowed duplicate headers? ... */
  g_hash_table_remove_all (priv->response_headers);
  soup_message_headers_foreach (message->response_headers,
      (SoupMessageHeadersForeachFunc)_populate_headers_hash_table,
      priv->response_headers);

  priv->payload = g_memdup (message->response_body->data,
                            message->response_body->length + 1);
  priv->length = message->response_body->length;

  _handle_error_from_message (message, error);
}

static void
_continuous_call_message_completed_cb (SoupSession *session,
                                       SoupMessage *message,
                                       gpointer     userdata)
{
  RestProxyCallContinuousClosure *closure;
  RestProxyCall *call;
  RestProxyCallPrivate *priv;
  GError *error = NULL;

  closure = (RestProxyCallContinuousClosure *)userdata;
  call = closure->call;
  priv = GET_PRIVATE (call);

  _handle_error_from_message (message, &error);

  closure->callback (closure->call,
                     NULL,
                     0,
                     error,
                     closure->weak_object,
                     closure->userdata);

  g_clear_error (&error);

  /* Success. We don't need the weak reference any more */
  if (closure->weak_object)
  {
    g_object_weak_unref (closure->weak_object,
        (GWeakNotify)_call_async_weak_notify_cb,
        closure);
  }

  priv->cur_call_closure = NULL;
  g_object_unref (closure->call);
  g_slice_free (RestProxyCallContinuousClosure, closure);
}


static void
_call_async_weak_notify_cb (gpointer *data,
                            GObject  *dead_object)
{
  RestProxyCallAsyncClosure *closure;

  closure = (RestProxyCallAsyncClosure *)data;

  /* Will end up freeing the closure */
  rest_proxy_call_cancel (closure->call);
  closure->weak_object = NULL;
}

static void
set_header (gpointer key, gpointer value, gpointer user_data)
{
  const char *name = key;
  SoupMessageHeaders *headers = user_data;

  soup_message_headers_replace (headers, name, value);
}

static gboolean
set_url (RestProxyCall *call)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);
  const gchar *bound_url;

  bound_url =_rest_proxy_get_bound_url (priv->proxy);

  if (_rest_proxy_get_binding_required (priv->proxy) && !bound_url)
  {
    g_critical (G_STRLOC ": URL requires binding and is unbound");
    return FALSE;
  }

  g_free (priv->url);

  /* FIXME: Perhaps excessive memory duplication */
  if (priv->function)
  {
    if (g_str_has_suffix (bound_url, "/")
          || g_str_has_prefix (priv->function, "/"))
    {
      priv->url = g_strdup_printf ("%s%s", bound_url, priv->function);
    } else {
      priv->url = g_strdup_printf ("%s/%s", bound_url, priv->function);
    }
  } else {
    priv->url = g_strdup (bound_url);
  }

  return TRUE;
}

static SoupMessage *
prepare_message (RestProxyCall *call, GError **error_out)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);
  RestProxyCallClass *call_class;
  SoupMessage *message;
  GError *error = NULL;

  call_class = REST_PROXY_CALL_GET_CLASS (call);

  /* Emit a warning if the caller is re-using RestProxyCall objects */
  if (priv->url)
  {
    g_warning (G_STRLOC ": re-use of RestProxyCall %p, don't do this", call);
  }

  /* Allow an overrideable prepare function that is called before every
   * invocation so subclasses can do magic
   */
  if (call_class->prepare)
  {
    if (!call_class->prepare (call, &error))
    {
      g_propagate_error (error_out, error);
      return NULL;
    }
  }

  if (call_class->serialize_params) {
    gchar *content;
    gchar *content_type;
    gsize content_len;

    if (!call_class->serialize_params (call, &content_type,
                                       &content, &content_len, &error))
    {
      g_propagate_error (error_out, error);
      return NULL;
    }

    /* Reset priv->url as the serialize_params vcall may have called
     * rest_proxy_call_set_function()
     */
    if (!set_url (call))
    {
        g_free (content);
        g_free (content_type);
        g_set_error_literal (error_out,
                             REST_PROXY_ERROR,
                             REST_PROXY_ERROR_BINDING_REQUIRED,
                             "URL is unbound");
        return NULL;
    }

    message = soup_message_new (priv->method, priv->url);
    if (message == NULL) {
        g_free (content);
        g_free (content_type);
        g_set_error_literal (error_out,
                             REST_PROXY_ERROR,
                             REST_PROXY_ERROR_FAILED,
                             "Could not parse URI");
        return NULL;
    }
    soup_message_set_request (message, content_type,
                              SOUP_MEMORY_TAKE, content, content_len);

    g_free (content_type);
  } else if (rest_params_are_strings (priv->params)) {
    GHashTable *hash;

    if (!set_url (call))
    {
        g_set_error_literal (error_out,
                             REST_PROXY_ERROR,
                             REST_PROXY_ERROR_BINDING_REQUIRED,
                             "URL is unbound");
        return NULL;
    }

    hash = rest_params_as_string_hash_table (priv->params);

    message = soup_form_request_new_from_hash (priv->method,
                                               priv->url,
                                               hash);

    g_hash_table_unref (hash);

    if (!message) {
        g_set_error (error_out,
                     REST_PROXY_ERROR,
                     REST_PROXY_ERROR_URL_INVALID,
                     "URL '%s' is not valid",
                     priv->url);
        return NULL;
    }

  } else {
    SoupMultipart *mp;
    RestParamsIter iter;
    const char *name;
    RestParam *param;

    mp = soup_multipart_new (SOUP_FORM_MIME_TYPE_MULTIPART);

    rest_params_iter_init (&iter, priv->params);

    while (rest_params_iter_next (&iter, &name, &param)) {
      if (rest_param_is_string (param)) {
        soup_multipart_append_form_string (mp, name, rest_param_get_content (param));
      } else {
        SoupBuffer *sb;

        sb = soup_buffer_new_with_owner (rest_param_get_content (param),
                                         rest_param_get_content_length (param),
                                         rest_param_ref (param),
                                         (GDestroyNotify)rest_param_unref);

        soup_multipart_append_form_file (mp, name,
                                         rest_param_get_file_name (param),
                                         rest_param_get_content_type (param),
                                         sb);

        soup_buffer_free (sb);
      }
    }

    if (!set_url (call))
    {
        soup_multipart_free (mp);
        g_set_error_literal (error_out,
                             REST_PROXY_ERROR,
                             REST_PROXY_ERROR_BINDING_REQUIRED,
                             "URL is unbound");
        return NULL;
    }

    message = soup_form_request_new_from_multipart (priv->url, mp);

    soup_multipart_free (mp);
  }

  /* Set the headers */
  g_hash_table_foreach (priv->headers, set_header, message->request_headers);

  return message;
}

static void
_call_message_call_cancelled_cb (GCancellable  *cancellable,
                                 RestProxyCall *call)
{
  rest_proxy_call_cancel (call);
}

static void
_call_message_call_completed_cb (SoupSession *session,
                                 SoupMessage *message,
                                 gpointer     user_data)
{
  GTask *task = user_data;
  RestProxyCall *call;
  GError *error = NULL;

  call = REST_PROXY_CALL (g_task_get_source_object (task));

  finish_call (call, message, &error);

  if (error != NULL)
    g_task_return_error (task, error);
  else
    g_task_return_boolean (task, TRUE);

  g_object_unref (task);
}

/**
 * rest_proxy_call_invoke_async:
 * @call: a #RestProxyCall
 * @cancellable: (nullable): an optional #GCancellable that can be used to
 *   cancel the call, or %NULL
 * @callback: (scope async): callback to call when the async call is finished
 * @user_data: (closure): user data for the callback
 */
void
rest_proxy_call_invoke_async (RestProxyCall      *call,
                              GCancellable       *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer            user_data)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);
  GTask *task;
  SoupMessage *message;
  GError *error = NULL;

  g_return_if_fail (REST_IS_PROXY_CALL (call));
  g_return_if_fail (cancellable == NULL || G_IS_CANCELLABLE (cancellable));
  g_assert (priv->proxy);

  message = prepare_message (call, &error);
  task = g_task_new (call, cancellable, callback, user_data);
  if (message == NULL)
    {
      g_task_return_error (task, error);
      return;
    }

  if (cancellable != NULL)
    {
      priv->cancel_sig = g_signal_connect (cancellable, "cancelled",
          G_CALLBACK (_call_message_call_cancelled_cb), call);
      priv->cancellable = g_object_ref (cancellable);
    }

  _rest_proxy_queue_message (priv->proxy,
                             message,
                             _call_message_call_completed_cb,
                             task);
}

/**
 * rest_proxy_call_invoke_finish:
 * @call: a #RestProxyCall
 * @result: the result from the #GAsyncReadyCallback
 * @error: optional #GError
 *
 * Returns: %TRUE on success
 */
gboolean
rest_proxy_call_invoke_finish (RestProxyCall  *call,
                               GAsyncResult   *result,
                               GError        **error)
{
  g_return_val_if_fail (REST_IS_PROXY_CALL (call), FALSE);
  g_return_val_if_fail (g_task_is_valid (result, call), FALSE);

  return g_task_propagate_boolean (G_TASK (result), error);
}

static void
_continuous_call_message_got_chunk_cb (SoupMessage                    *msg,
                                       SoupBuffer                     *chunk,
                                       RestProxyCallContinuousClosure *closure)
{
  closure->callback (closure->call,
                     chunk->data,
                     chunk->length,
                     NULL,
                     closure->weak_object,
                     closure->userdata);
}


/**
 * rest_proxy_call_continuous: (skip)
 * @call: The #RestProxyCall
 * @callback: a #RestProxyCallContinuousCallback to invoke when data is available
 * @weak_object: The #GObject to weakly reference and tie the lifecycle to
 * @userdata: (closure): data to pass to @callback
 * @error: (out) (allow-none): a #GError, or %NULL
 *
 * Asynchronously invoke @call but expect a continuous stream of content. This
 * means that the body data will not be accumulated and thus you cannot use
 * rest_proxy_call_get_payload()
 *
 * When there is data @callback will be called and when the connection is
 * closed or the stream ends @callback will also be called.
 *
 * If @weak_object is disposed during the call then this call will be
 * cancelled. If the call is cancelled then the callback will be invoked with
 * an error state.
 *
 * You may unref the call after calling this function since there is an
 * internal reference, or you may unref in the callback.
 */
gboolean
rest_proxy_call_continuous (RestProxyCall                    *call,
                            RestProxyCallContinuousCallback   callback,
                            GObject                          *weak_object,
                            gpointer                          userdata,
                            GError                          **error)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);
  SoupMessage *message;
  RestProxyCallContinuousClosure *closure;

  g_return_val_if_fail (REST_IS_PROXY_CALL (call), FALSE);
  g_assert (priv->proxy);

  if (priv->cur_call_closure)
  {
    g_warning (G_STRLOC ": re-use of RestProxyCall %p, don't do this", call);
    return FALSE;
  }

  message = prepare_message (call, error);
  if (message == NULL)
    return FALSE;

  /* Must turn off accumulation */
  soup_message_body_set_accumulate (message->response_body, FALSE);

  closure = g_slice_new0 (RestProxyCallContinuousClosure);
  closure->call = g_object_ref (call);
  closure->callback = callback;
  closure->weak_object = weak_object;
  closure->message = message;
  closure->userdata = userdata;

  priv->cur_call_closure = (RestProxyCallAsyncClosure *)closure;

  /* Weakly reference this object. We remove our callback if it goes away. */
  if (closure->weak_object)
  {
    g_object_weak_ref (closure->weak_object,
        (GWeakNotify)_call_async_weak_notify_cb,
        closure);
  }

  g_signal_connect (message,
                    "got-chunk",
                    (GCallback)_continuous_call_message_got_chunk_cb,
                    closure);

  _rest_proxy_queue_message (priv->proxy,
                             message,
                             _continuous_call_message_completed_cb,
                             closure);
  return TRUE;
}

static void
_upload_call_message_completed_cb (SoupSession *session,
                                   SoupMessage *message,
                                   gpointer     user_data)
{
  RestProxyCall *call;
  RestProxyCallPrivate *priv;
  GError *error = NULL;
  RestProxyCallUploadClosure *closure;

  closure = (RestProxyCallUploadClosure *) user_data;
  call = closure->call;
  priv = GET_PRIVATE (call);

  finish_call (call, message, &error);

  closure->callback (closure->call,
                     closure->uploaded,
                     closure->uploaded,
                     error,
                     closure->weak_object,
                     closure->userdata);

  g_clear_error (&error);

  /* Success. We don't need the weak reference any more */
  if (closure->weak_object)
  {
    g_object_weak_unref (closure->weak_object,
        (GWeakNotify)_call_async_weak_notify_cb,
        closure);
  }

  priv->cur_call_closure = NULL;
  g_object_unref (closure->call);
  g_slice_free (RestProxyCallUploadClosure, closure);
}

static void
_upload_call_message_wrote_data_cb (SoupMessage                *msg,
                                    SoupBuffer                 *chunk,
                                    RestProxyCallUploadClosure *closure)
{
  closure->uploaded = closure->uploaded + chunk->length;

  if (closure->uploaded < msg->request_body->length)
    closure->callback (closure->call,
                       msg->request_body->length,
                       closure->uploaded,
                       NULL,
                       closure->weak_object,
                       closure->userdata);
}

/**
 * rest_proxy_call_upload:
 * @call: The #RestProxyCall
 * @callback: (scope async): a #RestProxyCallUploadCallback to invoke when a chunk
 *   of data was uploaded
 * @weak_object: The #GObject to weakly reference and tie the lifecycle to
 * @userdata: data to pass to @callback
 * @error: a #GError, or %NULL
 *
 * Asynchronously invoke @call but expect to have the callback invoked every time a
 * chunk of our request's body is written.
 *
 * When the callback is invoked with the uploaded byte count equaling the message
 * byte count, the call has completed.
 *
 * If @weak_object is disposed during the call then this call will be
 * cancelled. If the call is cancelled then the callback will be invoked with
 * an error state.
 *
 * You may unref the call after calling this function since there is an
 * internal reference, or you may unref in the callback.
 */
gboolean
rest_proxy_call_upload (RestProxyCall                *call,
                        RestProxyCallUploadCallback   callback,
                        GObject                      *weak_object,
                        GCancellable                 *cancellable,
                        gpointer                      userdata,
                        GError                      **error)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);
  SoupMessage *message;
  RestProxyCallUploadClosure *closure;

  g_return_val_if_fail (REST_IS_PROXY_CALL (call), FALSE);
  g_assert (priv->proxy);

  if (priv->cur_call_closure)
  {
    g_warning (G_STRLOC ": re-use of RestProxyCall %p, don't do this", call);
    return FALSE;
  }

  message = prepare_message (call, error);
  if (message == NULL)
    return FALSE;

  closure = g_slice_new0 (RestProxyCallUploadClosure);
  closure->call = g_object_ref (call);
  closure->callback = callback;
  closure->weak_object = weak_object;
  closure->message = message;
  closure->userdata = userdata;
  closure->uploaded = 0;

  priv->cur_call_closure = (RestProxyCallAsyncClosure *)closure;

  /* Weakly reference this object. We remove our callback if it goes away. */
  if (closure->weak_object)
  {
    g_object_weak_ref (closure->weak_object,
        (GWeakNotify)_call_async_weak_notify_cb,
        closure);
  }

  priv->cancel_sig = g_signal_connect (cancellable, "cancelled",
                                       G_CALLBACK (_call_message_call_cancelled_cb), call);
  priv->cancellable = g_object_ref (cancellable);

  g_signal_connect (message,
                    "wrote-body-data",
                    (GCallback) _upload_call_message_wrote_data_cb,
                    closure);

  _rest_proxy_queue_message (priv->proxy,
                             message,
                             _upload_call_message_completed_cb,
                             closure);
  return TRUE;
}

/**
 * rest_proxy_call_cancel: (skip)
 * @call: The #RestProxyCall
 *
 * Cancel this call.  It may be too late to not actually send the message, but
 * the callback will not be invoked.
 *
 * N.B. this method should only be used with rest_proxy_call_async() and NOT
 * rest_proxy_call_invoke_async().
 */
gboolean
rest_proxy_call_cancel (RestProxyCall *call)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);
  RestProxyCallAsyncClosure *closure;

  g_return_val_if_fail (REST_IS_PROXY_CALL (call), FALSE);

  closure = priv->cur_call_closure;

  if (priv->cancellable)
    {
      g_signal_handler_disconnect (priv->cancellable, priv->cancel_sig);
      g_clear_object (&priv->cancellable);
    }

  if (closure)
  {
    /* This will cause the _call_message_completed_cb to be fired which will
     * tidy up the closure and so forth */
    _rest_proxy_cancel_message (priv->proxy, closure->message);
  }

  return TRUE;
}

/**
 * rest_proxy_call_lookup_response_header:
 * @call: The #RestProxyCall
 * @header: The name of the header to lookup.
 *
 * Get the string value of the header @header or %NULL if that header is not
 * present or there are no headers.
 */
const gchar *
rest_proxy_call_lookup_response_header (RestProxyCall *call,
                                        const gchar   *header)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);

  g_return_val_if_fail (REST_IS_PROXY_CALL (call), NULL);

  if (!priv->response_headers)
  {
    return NULL;
  }

  return g_hash_table_lookup (priv->response_headers, header);
}

/**
 * rest_proxy_call_get_response_headers:
 * @call: The #RestProxyCall
 *
 * Returns: (transfer container): pointer to a hash table of
 * headers. This hash table must not be changed. You should call
 * g_hash_table_unref() when you have finished with it.
 */
GHashTable *
rest_proxy_call_get_response_headers (RestProxyCall *call)
{
  RestProxyCallPrivate *priv = GET_PRIVATE (call);

  g_return_val_if_fail (REST_IS_PROXY_CALL (call), NULL);

  if (!priv->response_headers)
  {
    return NULL;
  }

  return g_hash_table_ref (priv->response_headers);
}

/**
 * rest_proxy_call_get_payload_length:
 * @call: The #RestProxyCall
 *
 * Get the length of the return payload.
 *
 * Returns: the length of the payload in bytes.
 */
goffset
rest_proxy_call_get_payload_length (RestProxyCall *call)
{
  g_return_val_if_fail (REST_IS_PROXY_CALL (call), 0);

  return GET_PRIVATE (call)->length;
}

/**
 * rest_proxy_call_get_payload:
 * @call: The #RestProxyCall
 *
 * Get the return payload.
 *
 * Returns: A pointer to the payload. This is owned by #RestProxyCall and should
 * not be freed.
 */
const gchar *
rest_proxy_call_get_payload (RestProxyCall *call)
{
  g_return_val_if_fail (REST_IS_PROXY_CALL (call), NULL);

  return GET_PRIVATE (call)->payload;
}

char *
rest_proxy_call_take_payload (RestProxyCall *call)
{
  return g_steal_pointer (&GET_PRIVATE (call)->payload);
}

/**
 * rest_proxy_call_serialize_params:
 * @call: The #RestProxyCall
 * @content_type: (out): Content type of the payload
 * @content: (out): The payload
 * @content_len: (out): Length of the payload data
 * @error: a #GError, or %NULL
 *
 * Invoker for a virtual method to serialize the parameters for this
 * #RestProxyCall.
 *
 * Returns: TRUE if the serialization was successful, FALSE otherwise.
 */
gboolean
rest_proxy_call_serialize_params (RestProxyCall *call,
                                  gchar **content_type,
                                  gchar **content,
                                  gsize *content_len,
                                  GError **error)
{
  RestProxyCallClass *call_class;

  call_class = REST_PROXY_CALL_GET_CLASS (call);

  if (call_class->serialize_params)
  {
    return call_class->serialize_params (call, content_type,
                                         content, content_len, error);
  }

  return FALSE;
}

G_GNUC_INTERNAL const char *
rest_proxy_call_get_url (RestProxyCall *call)
{
  /* Ensure priv::url is current before returning it. This method is used
   * by OAuthProxyCall::_prepare which expects set_url() to have been called,
   * but this has been changed/broken by c66b6df
   */
  set_url(call);
  return GET_PRIVATE (call)->url;
}
