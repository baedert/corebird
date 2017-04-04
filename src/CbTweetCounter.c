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

gsize
cb_tweet_counter_count_chars (const char *text)
{
  gsize text_length = 0;
  gunichar current_char;
  gsize current_pos = 0;
  const char *p = text;

  g_return_val_if_fail (text != NULL, 0);

  /* Character at the beginning of @text */
  current_char = g_utf8_get_char (p);

  while (current_char != '\0')
    {
      text_length ++;

      p = g_utf8_next_char (p);
      current_char = g_utf8_get_char (p);
    }

  return text_length;
}
