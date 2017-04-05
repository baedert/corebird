/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2017 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "CbTweetCounter.h"
#include <string.h>
#include <ctype.h>

#define TWEET_URL_LENGTH 23

static inline gboolean
splits_word (gunichar c)
{
  switch (c)
    {
      case ':':
      case '[':
      case ']':
      case '(':
      case ')':
      case '/':
      case '.':
      case '?':
      case '\\':
      case ' ':
      case '\t':
      case '\n':
        return TRUE;

      default:
        return FALSE;
    }

  return FALSE;
}

static const char *
read_next_word (const char *from,
                gsize      *word_length,
                gunichar   *current_char)
{
  const char *ret = from;

  while (*current_char != '\0')
    {
      if (splits_word (*current_char))
        break;

      ret = g_utf8_next_char (ret);
      *current_char = g_utf8_get_char (ret);
      *word_length = *word_length + 1;
    }

  if (*word_length == 0)
    {
      /* If the current character already splits, the word is
       * still that one character long.
       */
      *word_length = 1;
    }

  return ret;
}

const char *
parse_link (const char *text,
            gsize      *link_size,
            gunichar   *current_char)
{
  const char *p;
  /* Link start with either 'http:' or 'https:'.
   * That is, if they have a protocol attached. http and https are the only
   * protocols Twitter considers.
   */
  g_assert (*current_char == ':');

  /* Links extend to the next whitespace character */

  p = text;
  *current_char = g_utf8_get_char (p);

  while (*current_char != '\0' &&
         !isspace (*current_char))
    {
      p = g_utf8_next_char (p);
      *current_char = g_utf8_get_char (p);

      *link_size = *link_size + 1;
    }

  return p;
}

gsize
cb_tweet_counter_count_chars (const char *text)
{
  gsize text_length = 0;
  gunichar current_char;
  const char *p = text;

  g_return_val_if_fail (text != NULL, 0);

  /* Character at the beginning of @text */
  current_char = g_utf8_get_char (p);

  while (current_char != '\0')
    {
      const char *word_end;
      gsize n_word_chars = 0;
      /*gsize word_byte_length;*/

      word_end = read_next_word (p, &n_word_chars, &current_char);

      /*word_byte_length = word_end - p + 1;*/

      /*g_message ("Word: '%.*s'", (int)word_byte_length, p);*/

      /* XXX This can read over the boundaries of p, right? */
      if (memcmp (p, "http:",  strlen ("http:"))  == 0 ||
          memcmp (p, "https:", strlen ("https:")) == 0)
        {
          /*const char *link_start = p;*/
          const char *link_end;
          gsize n_link_chars = 0;
          link_end = parse_link (p, &n_link_chars, &current_char);

          /*g_message ("Link: '%.*s'", (int)(link_end - link_start), link_start);*/

          p = link_end;
          text_length += TWEET_URL_LENGTH;
        }
      else
        {
          /* This was a normal word */
          text_length += n_word_chars;
          p = word_end;
        }

      if (current_char == '\0')
        break;

      /* Skip to the next character */
      p = g_utf8_next_char (p);
      current_char = g_utf8_get_char (p);
    }

  return text_length;
}
