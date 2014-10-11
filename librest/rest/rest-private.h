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

#ifndef _REST_PRIVATE
#define _REST_PRIVATE

#include <glib.h>
#include <rest/rest-proxy.h>
#include <rest/rest-proxy-call.h>
#include <rest/rest-xml-node.h>
#include <libsoup/soup.h>
#include "glib-compat.h"

G_BEGIN_DECLS

typedef enum
{
  REST_DEBUG_XML_PARSER = 1 << 0,
  REST_DEBUG_PROXY = 1 << 1,
  REST_DEBUG_ALL = REST_DEBUG_XML_PARSER | REST_DEBUG_PROXY
} RestDebugFlags;

extern guint rest_debug_flags;

#define REST_DEBUG_ENABLED(category) (rest_debug_flags & REST_DEBUG_##category)

#define REST_DEBUG(category,x,a...)             G_STMT_START {      \
    if (REST_DEBUG_ENABLED(category))                               \
          { g_message ("[" #category "] " G_STRLOC ": " x, ##a); }  \
                                                } G_STMT_END

void _rest_setup_debugging (void);

gboolean _rest_proxy_get_binding_required (RestProxy *proxy);
const gchar *_rest_proxy_get_bound_url (RestProxy *proxy);
void _rest_proxy_queue_message (RestProxy   *proxy,
                                SoupMessage *message,
                                SoupSessionCallback callback,
                                gpointer user_data);
void _rest_proxy_cancel_message (RestProxy   *proxy,
                                 SoupMessage *message);
guint _rest_proxy_send_message (RestProxy   *proxy,
                                SoupMessage *message);

RestXmlNode *_rest_xml_node_new (void);
void         _rest_xml_node_reverse_children_siblings (RestXmlNode *node);
RestXmlNode *_rest_xml_node_prepend (RestXmlNode *cur_node,
                                     RestXmlNode *new_node);

G_END_DECLS
#endif /* _REST_PRIVATE */
