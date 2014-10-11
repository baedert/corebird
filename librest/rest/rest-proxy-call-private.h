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

#ifndef _REST_PROXY_CALL_PRIVATE
#define _REST_PROXY_CALL_PRIVATE

#include <rest/rest-proxy.h>
#include <rest/rest-proxy-call.h>
#include <rest/rest-params.h>

G_BEGIN_DECLS

const char *rest_proxy_call_get_url (RestProxyCall *call);

G_END_DECLS

#endif /* _REST_PROXY_CALL_PRIVATE */
