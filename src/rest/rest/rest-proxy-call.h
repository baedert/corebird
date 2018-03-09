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

#ifndef __REST_PROXY_CALL_H__
#define __REST_PROXY_CALL_H__

#include <glib-object.h>
#include <gio/gio.h>
#include "rest-params.h"
#include "rest-proxy.h"

G_BEGIN_DECLS

typedef struct _RestProxy RestProxy;

#define REST_TYPE_PROXY_CALL rest_proxy_call_get_type()
G_DECLARE_DERIVABLE_TYPE (RestProxyCall, rest_proxy_call, REST, PROXY_CALL, GObject)

typedef void (*RestProxyCallAsyncCallback)      (RestProxyCall *call,
                                                 const GError  *error,
                                                 GObject       *weak_object,
                                                 gpointer       user_data);
typedef void (*RestProxyCallContinuousCallback) (RestProxyCall *call,
                                                 const gchar   *buf,
                                                 gsize          len,
                                                 const GError  *error,
                                                 GObject       *weak_object,
                                                 gpointer       user_data);
typedef void (*RestProxyCallUploadCallback)     (RestProxyCall *call,
                                                 gsize          total,
                                                 gsize          uploaded,
                                                 const GError  *error,
                                                 GObject       *weak_object,
                                                 gpointer       user_data);


/**
 * RestProxyCallClass:
 * @prepare: Virtual function called before making the request, This allows the
 * call to be modified, for example to add a signature.
 * parameters, for example when the API doesn't expect standard form content.
 *
 * Class structure for #RestProxyCall for subclasses to implement specialised
 * behaviour.
 */
struct _RestProxyCallClass {
  /*< private >*/
  GObjectClass parent_class;
  /*< public >*/
  gboolean (*prepare)(RestProxyCall *call, GError **error);
};

#define REST_PROXY_CALL_ERROR rest_proxy_call_error_quark ()

/**
 * RestProxyCallError:
 * @REST_PROXY_CALL_FAILED: the method call failed
 *
 * Error domain used when returning errors from #RestProxyCall.
 */
typedef enum {
  REST_PROXY_CALL_FAILED
} RestProxyCallError;

GQuark rest_proxy_call_error_quark (void);

GType         rest_proxy_call_get_type               (void);
void          rest_proxy_call_set_method             (RestProxyCall *call,
                                                      const char    *method);
const char *  rest_proxy_call_get_method             (RestProxyCall *call);
void          rest_proxy_call_set_function           (RestProxyCall *call,
                                                      const char    *function);
const char *  rest_proxy_call_get_function           (RestProxyCall *call);
void          rest_proxy_call_add_header             (RestProxyCall *call,
                                                      const char    *header,
                                                      const char    *value);
void          rest_proxy_call_take_header            (RestProxyCall *call,
                                                      const char    *header,
                                                      char          *value);
const char *  rest_proxy_call_lookup_header          (RestProxyCall *call,
                                                      const char    *header);
void          rest_proxy_call_remove_header          (RestProxyCall *call,
                                                      const char    *header);
void          rest_proxy_call_add_param              (RestProxyCall *call,
                                                      const char    *name,
                                                      const char    *value);
void          rest_proxy_call_take_param             (RestProxyCall *call,
                                                      const char    *name,
                                                      char          *value);
void          rest_proxy_call_add_param_full         (RestProxyCall *call,
                                                      RestParam     *param);
RestParam *   rest_proxy_call_lookup_param           (RestProxyCall *call,
                                                      const char    *name);
void          rest_proxy_call_remove_param           (RestProxyCall *call,
                                                      const char    *name);
RestParams *  rest_proxy_call_get_params             (RestProxyCall *call);
void          rest_proxy_call_invoke_async           (RestProxyCall       *call,
                                                      GCancellable        *cancellable,
                                                      GAsyncReadyCallback  callback,
                                                      gpointer             user_data);
gboolean      rest_proxy_call_invoke_finish          (RestProxyCall *call,
                                                      GAsyncResult  *result,
                                                      GError       **error);
gboolean      rest_proxy_call_continuous             (RestProxyCall                    *call,
                                                      RestProxyCallContinuousCallback   callback,
                                                      GObject                          *weak_object,
                                                      gpointer                          userdata,
                                                      GError                          **error);
gboolean      rest_proxy_call_upload                 (RestProxyCall                *call,
                                                      RestProxyCallUploadCallback   callback,
                                                      GObject                      *weak_object,
                                                      GCancellable                 *cancellable,
                                                      gpointer                      userdata,
                                                      GError                      **error);
gboolean      rest_proxy_call_cancel                 (RestProxyCall   *call);
const char *  rest_proxy_call_lookup_response_header (RestProxyCall   *call,
                                                     const gchar      *header);
GHashTable *  rest_proxy_call_get_response_headers   (RestProxyCall   *call);
goffset       rest_proxy_call_get_payload_length     (RestProxyCall   *call);
const char *  rest_proxy_call_get_payload            (RestProxyCall   *call);
char *        rest_proxy_call_take_payload           (RestProxyCall   *call);
void          rest_proxy_call_set_content            (RestProxyCall   *call,
                                                      const char      *content);
void          rest_proxy_call_take_content           (RestProxyCall   *call,
                                                      char            *content);
RestProxy *   rest_proxy_call_get_proxy              (RestProxyCall   *call);



G_END_DECLS

#endif /* _REST_PROXY_CALL */

