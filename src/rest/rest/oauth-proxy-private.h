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

#include "oauth-proxy.h"

#define PROXY_GET_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), OAUTH_TYPE_PROXY, OAuthProxyPrivate))

typedef struct {
  /* Application "consumer" keys */
  char *consumer_key;
  char *consumer_secret;
  /* Authorisation "user" tokens */
  char *token;
  char *token_secret;
  /* How we're signing */
  OAuthSignatureMethod method;
  /* OAuth 1.0a */
  gboolean oauth_10a;
  char *verifier;
  /* OAuth Echo */
  gboolean oauth_echo;
  char *service_url;
  /* URL to use for signatures */
  char *signature_host;
} OAuthProxyPrivate;
