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

#include "CbUtils.h"
#include <string.h>
#include <stdlib.h>

void
cb_utils_bind_model (GtkWidget                  *listbox,
                     GListModel                 *model,
                     GtkListBoxCreateWidgetFunc  func,
                     void                       *data)
{
  g_return_if_fail (GTK_IS_LIST_BOX (listbox));
  g_return_if_fail (G_IS_LIST_MODEL (model));

  /* This entire function is just a hack around valac ref'ing the listbox
   * in its own constructor when calling gtk_list_box_bind_model there */

  gtk_list_box_bind_model (GTK_LIST_BOX (listbox),
                           model,
                           func,
                           data,
                           NULL);
}

char *
cb_utils_escape_quotes (const char *in)
{
  gsize bytes = strlen (in);
  gsize n_quotes = 0;
  const char *p = in;
  gunichar c;
  char *result;
  const char *last;
  char *out_pos;

  c = g_utf8_get_char (p);
  while (c != '\0')
    {
      if (c == '"')
        n_quotes ++;

      p = g_utf8_next_char (p);
      c = g_utf8_get_char (p);
    }

  result = g_malloc (bytes + (n_quotes * 5) + 1);
  result[bytes + (n_quotes * 5)] = '\0';

  p = in;
  c = g_utf8_get_char (p);
  last = p;
  out_pos = result;
  while (c != '\0')
    {

      if (c == '"')
        {
          int bytes = p - last;
          memcpy (out_pos, last, bytes);
          last = p;
          out_pos[bytes + 0] = '&';
          out_pos[bytes + 1] = 'q';
          out_pos[bytes + 2] = 'u';
          out_pos[bytes + 3] = 'o';
          out_pos[bytes + 4] = 't';
          out_pos[bytes + 5] = ';';
          last += 1; /* Skip " */

          out_pos += bytes + 6;
        }

      p = g_utf8_next_char (p);
      c = g_utf8_get_char (p);
    }

  memcpy (out_pos, last, p - last);

  return result;
}


GDateTime *
cb_utils_parse_date (const char *_in)
{
  char *in = g_strdup (_in);
  const char *month_str;
  int year, month, hour, minute, day;
  GDateTime *result;
  GDateTime *result_local;
  GTimeZone *time_zone;
  GTimeZone *local_time_zone;
  double seconds;

  /* The input string is ASCII, in the form  'Wed Jun 20 19:01:28 +0000 2012' */

  if (!_in)
    {
      g_free (in);
      return g_date_time_new_now_local ();
    }

  g_assert (strlen (_in) == 30);

  in[3]  = '\0';
  in[7]  = '\0';
  in[10] = '\0';
  in[13] = '\0';
  in[16] = '\0';
  in[19] = '\0';
  in[25] = '\0';

  year    = atoi (in + 26);
  day     = atoi (in + 8);
  hour    = atoi (in + 11);
  minute  = atoi (in + 14);
  seconds = atof (in + 17);

  month_str = in + 4;
  switch (month_str[0])
    {
      case 'J': /* January */
        if (month_str[1] == 'u' && month_str[2] == 'n')
          month = 6;
        else if (month_str[1] == 'u' && month_str[2] == 'l')
          month = 7;
        else
          month = 1;
        break;
      case 'F':
        month = 2;
        break;
      case 'M':
        if (month_str[1] == 'a')
          month = 3;
        else
          month = 5;
        break;
      case 'A':
        if (month_str[1] == 'p')
          month = 4;
        else
          month = 8;
        break;
      case 'S':
        month = 9;
        break;
      case 'O':
        month = 10;
        break;
      case 'N':
        month = 11;
        break;
      case 'D':
        month = 12;
        break;

      default:
        month = 0;
        g_warn_if_reached ();
        break;
    }


  time_zone = g_time_zone_new (in + 20);

  result = g_date_time_new (time_zone,
                            year,
                            month,
                            day,
                            hour,
                            minute,
                            seconds);
  g_assert (result);

  local_time_zone = g_time_zone_new_local ();
  result_local = g_date_time_to_timezone (result, local_time_zone);

  g_time_zone_unref (local_time_zone);
  g_time_zone_unref (time_zone);
  g_date_time_unref (result);
  g_free (in);
  return result_local;
}


