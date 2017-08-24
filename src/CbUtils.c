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
#include <glib/gi18n.h>

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

void
cb_utils_linkify_user (const CbUserIdentity *user,
                       GString              *str)
{
  g_string_append (str, "<span underline='none'><a href='@");
  g_string_append_printf (str, "%ld", user->id);
  g_string_append (str, "/@");
  g_string_append (str, user->screen_name);
  g_string_append (str, "' ");

  if (strlen (user->user_name) > 0)
    {
      char *s1, *s2, *s3, *s4;

      /* TODO: Write one function doing all 4 things, since we need that often
       *       and execute it often? */
      s1 = cb_utils_escape_quotes (user->user_name);
      s2 = cb_utils_escape_ampersands (s1);
      s3 = cb_utils_escape_quotes (s2);
      s4 = cb_utils_escape_ampersands (s3);

      g_string_append (str, "title=\"");
      g_string_append (str, s4);
      g_string_append_c (str, '"');

      g_free (s1);
      g_free (s2);
      g_free (s3);
      g_free (s4);
    }

  g_string_append (str, ">@");
  g_string_append (str, user->screen_name);
  g_string_append (str, "</a></span>");
}

void
cb_utils_write_reply_text (const CbMiniTweet *t,
                           GString           *str)
{

  g_return_if_fail (t->reply_id != 0);
  g_return_if_fail (t->n_reply_users > 0);

  /* TRANSLATORS: This is the start of a "Replying to" line in a tweet */
  g_string_append (str, _("Replying to"));
  g_string_append_c (str, ' ');

  cb_utils_linkify_user (&t->reply_users[0], str);

  if (t->n_reply_users == 2)
    {
      g_string_append_c (str, ' ');
      /* TRANSLATORS: This gets appended to the "replying to" line
       * in a tweet. Example: "Replying to Foo and Bar" where
       * "and Bar" comes from this string. */
      g_string_append (str, _("and"));
      g_string_append_c (str, ' ');
      cb_utils_linkify_user (&t->reply_users[1], str);
    }
  else if (t->n_reply_users > 2)
    {
      g_string_append_c (str, ' ');
      /* TRANSLATORS: This gets appended to the "replying to" line
       * in a tweet */
      g_string_append_printf (str, _("and %d others"), t->n_reply_users - 1);
    }
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

/* TODO: Code duplication here with escape_quotes */
char *
cb_utils_escape_ampersands (const char *in)
{
  gsize bytes = strlen (in);
  gsize n_ampersands = 0;
  const char *p = in;
  gunichar c;
  char *result;
  const char *last;
  char *out_pos;

  c = g_utf8_get_char (p);
  while (c != '\0')
    {
      if (c == '&')
        n_ampersands ++;

      p = g_utf8_next_char (p);
      c = g_utf8_get_char (p);
    }

  /* 'amp;' and not '&amp;' since the input already contains the '&' */
  result = g_malloc (bytes + (n_ampersands * strlen ("amp;")) + 1);
  result[bytes + (n_ampersands * strlen ("amp;"))] = '\0';

  p = in;
  c = g_utf8_get_char (p);
  last = p;
  out_pos = result;
  while (c != '\0')
    {

      if (c == '&')
        {
          int bytes = p - last;
          memcpy (out_pos, last, bytes);
          last = p;
          out_pos[bytes + 0] = '&';
          out_pos[bytes + 1] = 'a';
          out_pos[bytes + 2] = 'm';
          out_pos[bytes + 3] = 'p';
          out_pos[bytes + 4] = ';';
          last += 1; /* Skip & */
          out_pos += bytes + 5;
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
  char in[31];
  const char *month_str;
  int year, month, hour, minute, day;
  GDateTime *result;
  GDateTime *result_local;
  GTimeZone *time_zone;
  GTimeZone *local_time_zone;
  double seconds;
  guint i;

  /* The input string is ASCII, in the form  'Wed Jun 20 19:01:28 +0000 2012' */

  if (!_in)
    return g_date_time_new_now_local ();

  for (i = 0; i < 30; i ++)
    in[i] = _in[i];


  g_assert (strlen (_in) == 30);

  in[3]  = '\0';
  in[7]  = '\0';
  in[10] = '\0';
  in[13] = '\0';
  in[16] = '\0';
  in[19] = '\0';
  in[25] = '\0';
  in[30] = '\0';

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
        if (month_str[1] == 'a' && month_str[2] == 'r')
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

  return result_local;
}

char *
cb_utils_get_file_type (const char *url)
{
  const char *filename;
  const char *extension;
  char *type;

  filename = g_strrstr (url, "/");
  if (filename == NULL)
    filename = url;
  else
    filename += 1;

  extension = g_strrstr (filename, ".");

  if (extension == NULL)
    return g_strdup ("");

  extension += 1;

  type = g_ascii_strdown (extension, -1);

  if (strcmp (type, "jpg") == 0)
    {
      g_free (type);
      return g_strdup ("jpeg");
    }

  return type;
}

char *
cb_utils_rest_proxy_call_to_string (RestProxyCall *call)
{
  GString *str = g_string_new (NULL);
  RestParams *params = rest_proxy_call_get_params (call);
  GHashTable *params_table = rest_params_as_string_hash_table (params);

  g_string_append (str, rest_proxy_call_get_method (call));
  g_string_append_c (str, ' ');
  g_string_append (str, rest_proxy_call_get_function (call));

  if (g_hash_table_size (params_table) > 0)
    {
      GList *keys;
      GList *l;

      g_string_append_c (str, '?');

      keys = g_hash_table_get_keys (params_table);

      for (l = keys; l; l = l->next)
        {
          const char *value = g_hash_table_lookup (params_table, l->data);

          g_assert (value);
          g_string_append (str, (const char *)l->data);
          g_string_append_c (str, '=');
          g_string_append (str, value);

          if (l->next != NULL)
            g_string_append_c (str, '&');
        }

      g_list_free (keys);

    }

  g_hash_table_unref (params_table);

  return g_string_free (str, FALSE);
}

static void
parse_json_async (GTask        *task,
                  gpointer      source_object,
                  gpointer      task_data,
                  GCancellable *cancellable)
{
  const char *payload = task_data;
  JsonParser *parser;
  JsonNode *root_node;
  GError *error = NULL;

  parser = json_parser_new ();
  json_parser_load_from_data (parser, payload, -1, &error);
  if (error)
    {
      g_task_return_error (task, error);
      return;
    }

  if (g_cancellable_is_cancelled (cancellable))
    {
      g_task_return_pointer (task, NULL, NULL);
      return;
    }

  root_node = json_parser_get_root (parser);

  g_assert (root_node);

  g_task_return_pointer (task, json_node_ref (root_node), (GDestroyNotify)json_node_unref);
  g_object_unref (parser);
}

static void
call_done_cb (GObject      *source_object,
              GAsyncResult *result,
              gpointer      user_data)
{
  RestProxyCall *call = REST_PROXY_CALL (source_object);
  GTask *task = user_data;
  GError *error = NULL;
  char *payload;

  /* Get the json data, run another GTask that actually parses the json and returns the root node */
  rest_proxy_call_invoke_finish (call, result, &error);
  if (error != NULL)
    {
      g_warning ("%s(%s): %s", __FILE__, __FUNCTION__, error->message);
      g_task_return_error (task, error);
      return;
    }

  payload = rest_proxy_call_take_payload (call);

  g_task_set_task_data (task, payload, g_free);
  g_task_run_in_thread (task, parse_json_async);
}

void
cb_utils_load_threaded_async  (RestProxyCall       *call,
                               GCancellable        *cancellable,
                               GAsyncReadyCallback  callback,
                               gpointer             user_data)
{
  GTask *task = g_task_new (call, cancellable, callback, user_data);

#ifdef DEBUG
  {
    char *s = cb_utils_rest_proxy_call_to_string (call);
    g_debug ("REST: %s", s);
    g_free (s);
  }
#endif

  rest_proxy_call_invoke_async (call, cancellable, call_done_cb, task);
}

JsonNode *
cb_utils_load_threaded_finish (GAsyncResult   *result,
                               GError        **error)
{
  JsonNode *node = g_task_propagate_pointer (G_TASK (result), error);
  g_object_unref (result);

  return node;
}
