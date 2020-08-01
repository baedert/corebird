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

typedef struct {
  GtkWidget *listbox;
  CbUtilsCreateWidgetFunc create_widget_func;
  gpointer create_widget_func_data;
} ModelData;

static void
non_gobject_model_changed (GListModel *model,
                           guint       position,
                           guint       removed,
                           guint       added,
                           gpointer    user_data)
{
  ModelData *data = user_data;
  GtkListBox *box = GTK_LIST_BOX (data->listbox);
  guint i;

  while (removed--)
    {
      GtkListBoxRow *row;

      row = gtk_list_box_get_row_at_index (box, position);
      gtk_list_box_remove (GTK_LIST_BOX (box), GTK_WIDGET (row));
    }

  for (i = 0; i < added; i++)
    {
      gpointer item;
      GtkWidget *widget;

      item = g_list_model_get_item (model, position + i);
      widget = data->create_widget_func (item, data->create_widget_func_data);

      /* We allow the create_widget_func to either return a full
       * reference or a floating reference.  If we got the floating
       * reference, then turn it into a full reference now.  That means
       * that gtk_list_box_insert() will take another full reference.
       * Finally, we'll release this full reference below, leaving only
       * the one held by the box.
       */
      if (g_object_is_floating (widget))
        g_object_ref_sink (widget);

      gtk_widget_show (widget);
      gtk_list_box_insert (box, widget, position + i);

      g_object_unref (widget);
    }
}

void
cb_utils_bind_non_gobject_model (GtkWidget               *listbox,
                                 GListModel              *model,
                                 CbUtilsCreateWidgetFunc  func,
                                 gpointer                 user_data)
{
  ModelData *data;

  g_return_if_fail (GTK_IS_LIST_BOX (listbox));
  g_return_if_fail (G_IS_LIST_MODEL (model));
  g_return_if_fail (g_list_model_get_item_type (model) == G_TYPE_POINTER);
  g_return_if_fail (g_object_get_data (G_OBJECT (listbox), "model-hack") == NULL);

  data = g_malloc (sizeof (*data));
  data->listbox = listbox;
  data->create_widget_func = func;
  data->create_widget_func_data = user_data;

  g_signal_connect (model, "items-changed", G_CALLBACK (non_gobject_model_changed), data);

  g_object_set_data (G_OBJECT (listbox), "model-hack", data);
}

void
cb_utils_unbind_non_gobject_model (GtkWidget  *listbox,
                                   GListModel *model)
{
  ModelData *data;

  g_return_if_fail (GTK_IS_LIST_BOX (listbox));
  g_return_if_fail (G_IS_LIST_MODEL (model));
  g_return_if_fail (g_object_get_data (G_OBJECT (listbox), "model-hack") != NULL);

  data = g_object_get_data (G_OBJECT (listbox), "model-hack");
  g_signal_handlers_disconnect_by_func (model, non_gobject_model_changed, data);

  g_assert (data != NULL);
  g_free (data);
}

void
cb_utils_linkify_user (const CbUserIdentity *user,
                       GString              *str)
{
  g_string_append (str, "<span underline='none'><a href='@");
  g_string_append_printf (str, "%" G_GINT64_FORMAT, user->id);
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
cb_utils_linkify_user_name (const CbUserIdentity *user,
                            GString              *str)
{
  char *s1, *s2;

  /* ATTENTION: The usernames passed in here should already have
   * escaped ampersand characters. */
#ifdef DEBUG
  {
    const char *a = strchr (user->user_name, '&');

    if (a != NULL)
      {
        /* All & characters must actually be "&amp;", so followed by an 'a'.
         * This check is pretty weak but we only do it for debugging purposes anyway. */
        if (*(a + 1) != 'a')
          {
            g_warning ("Username with unescaped ampersand characters passed to %s: %s",
                       __FUNCTION__, user->user_name);
          }
      }
  }
#endif

  g_string_append (str, "<span underline='none'><a href='@");
  g_string_append_printf (str, "%" G_GINT64_FORMAT, user->id);
  g_string_append (str, "/@");
  g_string_append (str, user->screen_name);
  g_string_append (str, "' ");

  g_string_append (str, "title=\"@");
  g_string_append (str, user->screen_name);
  g_string_append_c (str, '"');

  g_string_append (str, ">");

  s1 = cb_utils_escape_quotes (user->user_name);
  s2 = cb_utils_escape_quotes (s1);

  g_string_append (str, s2);
  g_string_append (str, " – ");
  g_string_append_c (str, '@');
  g_string_append (str, user->screen_name);

  g_free (s1);
  g_free (s2);

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
  char in[25];
  int year, month, hour, minute, day;
  GDateTime *result;
  GDateTime *result_local;
  GTimeZone *time_zone;
  GTimeZone *local_time_zone;
  double seconds;

  /* The input string is ASCII, in the form  '2020-03-20T08:50:38.526Z' */

  if (!_in)
    return g_date_time_new_now_local ();

  // TODO: What's the time zone here?
  g_assert (strlen (_in) == 24);
  memcpy (in, _in, 24);

  in[4]  = '\0';
  in[7]  = '\0';
  in[10] = '\0';
  in[13] = '\0';
  in[16] = '\0';

  in[23] = '\0';

  year    = atoi (in + 0);
  month   = atoi (in + 5);
  day     = atoi (in + 8);
  hour    = atoi (in + 11);
  minute  = atoi (in + 14);
  seconds = atof (in + 17);

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
      g_object_unref (parser);
      g_task_return_error (task, error);
      return;
    }

  if (g_cancellable_is_cancelled (cancellable))
    {
      g_object_unref (parser);
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
      if (!g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
        {
          g_warning ("%s(%s): %p, %s", __FILE__, __FUNCTION__, call, error->message);
        }

      g_task_return_error (task, error);
      return;
    }

  payload = rest_proxy_call_take_payload (call);

#ifdef DEBUG
    {
      char *s = cb_utils_rest_proxy_call_to_string (call);
      g_message ("%s Result: \n%s", s, payload);
      g_free (s);
    }
#endif

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

static void
users_received_cb (GObject      *source_object,
                   GAsyncResult *result,
                   gpointer      user_data)
{
  RestProxyCall *call = REST_PROXY_CALL (source_object);
  GTask *task = user_data;
  GError *error = NULL;
  JsonNode *root_node;
  JsonArray *root_arr;
  guint i, len;
  struct {
    CbUserIdentity *ids;
    int length;
  } *data;

  /* We are in the main thread again here. */
  root_node = cb_utils_load_threaded_finish (result, &error);

  if (error != NULL)
    {
      g_task_return_error (task, error);
      goto out;
    }

  if (g_cancellable_is_cancelled (g_task_get_cancellable (task)))
    {
      g_task_return_pointer (task, NULL, NULL);
      goto out;
    }

  g_assert (root_node != NULL);
  root_arr = json_node_get_array (root_node);
  len = json_array_get_length (root_arr);

  data = g_malloc (sizeof (*data));
  data->ids = g_new (CbUserIdentity, len);
  data->length = len;
  for (i = 0; i < len; i ++)
    {
      JsonObject *obj = json_array_get_object_element (root_arr, i);

      data->ids[i].id = json_object_get_int_member (obj, "id");
      data->ids[i].user_name = cb_utils_escape_ampersands (json_object_get_string_member (obj, "name"));
      data->ids[i].screen_name = g_strdup (json_object_get_string_member (obj, "screen_name"));
      data->ids[i].verified = json_object_get_boolean_member (obj, "verified");
    }

  json_node_unref (root_node);

  g_task_return_pointer (task, data, NULL);

out:
  g_object_unref (G_OBJECT (call));
}

void
cb_utils_query_users_async (RestProxy           *proxy,
                            const char          *query,
                            GCancellable        *cancellable,
                            GAsyncReadyCallback  callback,
                            gpointer             user_data)
{
  GTask *task;
  RestProxyCall *call;

  g_return_if_fail (REST_IS_PROXY (proxy));
  g_return_if_fail (query != NULL);

  call = rest_proxy_new_call (proxy);
  task = g_task_new (call, cancellable, callback, user_data);

  rest_proxy_call_set_function (call, "1.1/users/search.json");
  rest_proxy_call_set_method (call, "GET");
  rest_proxy_call_add_param (call, "q", query);
  rest_proxy_call_add_param (call, "count", "10");
  rest_proxy_call_add_param (call, "include_entities", "false");

  cb_utils_load_threaded_async (call, cancellable, users_received_cb, task);
}

CbUserIdentity *
cb_utils_query_users_finish (GAsyncResult  *result,
                             int           *out_length,
                             GError       **error)
{
  struct {
    CbUserIdentity *ids;
    int length;
  } *data = g_task_propagate_pointer (G_TASK (result), error);
  CbUserIdentity *ids;

  if (data == NULL)
    {
      g_object_unref (result);
      *out_length = 0;
      return NULL;
    }

  *out_length = data->length;

  g_object_unref (result);
  ids = data->ids;

  g_free (data);

  return ids;
}

char *
cb_utils_get_time_delta (GDateTime *time,
                         GDateTime *now)
{
  GTimeSpan diff;
  int minutes;

  /* In microseconds */
  diff = g_date_time_difference (now, time);
  minutes = (int)(diff / 1000.0 / 1000.0 / 60.0);

  if (minutes == 0)
    return g_strdup (_("Now"));
  else if (minutes < 60)
    return g_strdup_printf (_("%dm"), minutes);

  int hours = minutes / 60;
  if (hours < 24)
    return g_strdup_printf (_("%dh"), hours);

  char *month = g_date_time_format (time, "%b");
  char *result;
  if (g_date_time_get_year (time) == g_date_time_get_year (now))
    result = g_strdup_printf ("%d %s", g_date_time_get_day_of_month (time), month);
  else
    result = g_strdup_printf ("%d %s %d",
                              g_date_time_get_day_of_month (time),
                              month,
                              g_date_time_get_year (time));

  g_free (month);

  return result;
}

void
cb_utils_load_custom_css (void)
{
  GtkCssProvider *provider = gtk_css_provider_new ();

  gtk_css_provider_load_from_resource (provider, "/org/baedert/corebird/ui/style.css");
  gtk_style_context_add_provider_for_display (gdk_display_get_default (),
                                              GTK_STYLE_PROVIDER (provider),
                                              GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
}

char *
cb_utils_get_tweet_debug_info (CbTweet *tweet)
{
  GString *s = g_string_new (NULL);

#ifdef DEBUG
  g_assert (tweet->json_data);
  g_string_append (s, tweet->json_data);
#endif
  g_string_append_c (s, '\n');

  return g_string_free (s, FALSE);
}


void
cb_default_header_func (GtkListBoxRow *row,
                        GtkListBoxRow *row_before,
                        gpointer       user_data)
{
  GtkWidget *header;

  if (row_before == NULL)
    {
      gtk_list_box_row_set_header (row, NULL);
      return;
    }

  header = gtk_list_box_row_get_header (row);
  if (header != NULL)
    return;


  header = gtk_separator_new (GTK_ORIENTATION_HORIZONTAL);
  gtk_list_box_row_set_header (row, header);
}
