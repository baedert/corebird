/*
 * librest - RESTful web services access
 * Copyright (c) 2008, 2009, Intel Corporation.
 *
 * Authors: Ross Burton <ross@linux.intel.com>
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

#include <string.h>
#include <glib.h>
#include "sha1.h"

#define SHA1_LENGTH 20

/*
 * hmac_sha1:
 * @key: The key
 * @message: The message
 *
 * Given the key and message, compute the HMAC-SHA1 hash and return the base-64
 * encoding of it.  This is very geared towards OAuth, and as such both key and
 * message must be NULL-terminated strings, and the result is base-64 encoded.
 */
char *
hmac_sha1 (const char *key, const char *message)
{
  GHmac *hmac;
  gsize digest_length = SHA1_LENGTH;
  guchar digest[digest_length];

  hmac = g_hmac_new (G_CHECKSUM_SHA1, (guchar *)key, strlen (key));
  g_hmac_update (hmac, (guchar *)message, -1);

  g_hmac_get_digest (hmac, digest, &digest_length);

  g_hmac_unref (hmac);

  return g_base64_encode (digest, digest_length);
}
