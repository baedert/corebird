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

#define SHA1_BLOCK_SIZE 64
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
  GChecksum *checksum;
  char *real_key;
  guchar ipad[SHA1_BLOCK_SIZE];
  guchar opad[SHA1_BLOCK_SIZE];
  guchar inner[SHA1_LENGTH];
  guchar digest[SHA1_LENGTH];
  gsize key_length, inner_length, digest_length;
  int i;

  g_return_val_if_fail (key, NULL);
  g_return_val_if_fail (message, NULL);

  checksum = g_checksum_new (G_CHECKSUM_SHA1);

  /* If the key is longer than the block size, hash it first */
  if (strlen (key) > SHA1_BLOCK_SIZE) {
    guchar new_key[SHA1_LENGTH];

    key_length = sizeof (new_key);

    g_checksum_update (checksum, (guchar*)key, strlen (key));
    g_checksum_get_digest (checksum, new_key, &key_length);
    g_checksum_reset (checksum);

    real_key = g_memdup (new_key, key_length);
  } else {
    real_key = g_strdup (key);
    key_length = strlen (key);
  }

  /* Sanity check the length */
  g_assert (key_length <= SHA1_BLOCK_SIZE);

  /* Protect against use of the provided key by NULLing it */
  key = NULL;

  /* Stage 1 */
  memset (ipad, 0, sizeof (ipad));
  memset (opad, 0, sizeof (opad));

  memcpy (ipad, real_key, key_length);
  memcpy (opad, real_key, key_length);

  /* Stage 2 and 5 */
  for (i = 0; i < sizeof (ipad); i++) {
    ipad[i] ^= 0x36;
    opad[i] ^= 0x5C;
  }

  /* Stage 3 and 4 */
  g_checksum_update (checksum, ipad, sizeof (ipad));
  g_checksum_update (checksum, (guchar*)message, strlen (message));
  inner_length = sizeof (inner);
  g_checksum_get_digest (checksum, inner, &inner_length);
  g_checksum_reset (checksum);

  /* Stage 6 and 7 */
  g_checksum_update (checksum, opad, sizeof (opad));
  g_checksum_update (checksum, inner, inner_length);

  digest_length = sizeof (digest);
  g_checksum_get_digest (checksum, digest, &digest_length);

  g_checksum_free (checksum);
  g_free (real_key);

  return g_base64_encode (digest, digest_length);
}
