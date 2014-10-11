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

#ifndef _REST_PROXY_AUTH_PRIVATE
#define _REST_PROXY_AUTH_PRIVATE

#include <libsoup/soup.h>
#include <rest/rest-proxy.h>
#include <rest/rest-proxy-auth.h>

G_BEGIN_DECLS

RestProxyAuth* rest_proxy_auth_new (RestProxy *proxy,
                                    SoupSession *session,
                                    SoupMessage *message,
                                    SoupAuth *auth);
gboolean rest_proxy_auth_is_paused (RestProxyAuth *auth);

G_END_DECLS

#endif /* _REST_PROXY_AUTH_PRIVATE */
