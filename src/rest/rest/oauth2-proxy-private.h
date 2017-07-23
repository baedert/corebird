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
#ifndef _OAUTH2_PROXY_PRIVATE
#define _OAUTH2_PROXY_PRIVATE

#include "oauth2-proxy.h"

struct _OAuth2ProxyPrivate {
  char *client_id;
  char *auth_endpoint;
  char *access_token;
};

#endif /* _OAUTH2_PROXY_PRIVATE */
