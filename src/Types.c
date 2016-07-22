/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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

#include "Types.h"
#include "MediaDownloader.h"
#include <string.h>
#include <stdlib.h>

char *
escape_ampersand (const char *in)
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

  result = g_malloc (bytes + (n_ampersands * 4) + 1);
  result[bytes + (n_ampersands * 4)] = '\0';

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



void
cb_user_identity_free (CbUserIdentity *id)
{
  g_free (id->screen_name);
  g_free (id->user_name);
}

void
cb_user_identity_copy (CbUserIdentity *id, CbUserIdentity *id2)
{
  g_free (id2->screen_name);
  id2->screen_name = g_strdup (id->screen_name);
  g_free (id2->user_name);
  id2->user_name = g_strdup (id->user_name);
  id2->id = id->id;
}

void cb_user_identity_parse (CbUserIdentity *id,
                             JsonObject     *user_obj)
{
  id->id = json_object_get_int_member (user_obj, "id");
  id->screen_name = g_strdup (json_object_get_string_member (user_obj, "screen_name"));
  id->user_name = escape_ampersand (json_object_get_string_member (user_obj, "name"));
}


void
cb_text_entity_free (CbTextEntity *e)
{
  g_free (e->display_text);
  g_free (e->tooltip_text);
  g_free (e->target);
}

void
cb_text_entity_copy (CbTextEntity *e1, CbTextEntity *e2)
{
  e2->from = e1->from;
  e2->to   = e1->to;
  g_free (e2->display_text);
  e2->display_text = g_strdup (e1->display_text);
  g_free (e2->tooltip_text);
  e2->tooltip_text = g_strdup (e1->tooltip_text);
  g_free (e2->target);
  e2->target = g_strdup (e1->target);
  e2->info = e1->info;
}


void
cb_mini_tweet_free (CbMiniTweet *t)
{
  guint i;

  g_free (t->text);

  for (i = 0; i < t->n_medias; i ++)
    g_object_unref (t->medias[i]);

  g_free (t->medias);

  for (i = 0; i < t->n_entities; i ++)
    cb_text_entity_free (&t->entities[i]);
  g_free (t->entities);

  cb_user_identity_free (&t->author);
}

void
cb_mini_tweet_copy (CbMiniTweet *t1, CbMiniTweet *t2)
{
  guint i;

  t2->id = t1->id;
  t2->created_at = t1->created_at;
  cb_user_identity_free (&t2->author);
  cb_user_identity_copy (&t1->author, &t2->author);
  g_free (t2->text);
  t2->text = g_strdup (t1->text);

  t2->n_entities = t1->n_entities;
  t2->entities = g_new0 (CbTextEntity, t2->n_entities);
  memcpy  (&t2->entities, &t1->entities, sizeof (CbTextEntity) * t2->n_entities);

  t2->n_medias = t1->n_medias;
  t2->medias = g_new0 (CbMedia*, t2->n_medias);
  for (i = 0; i < t2->n_medias; i ++)
    t2->medias[i] = g_object_ref (t1->medias[i]);
}

void
cb_mini_tweet_init (CbMiniTweet *t)
{
  t->medias = NULL;
  t->n_medias = 0;
  t->entities = NULL;
  t->n_entities = 0;
}

static GDateTime *
parse_created_at (const char *_in)
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


void
cb_mini_tweet_parse (CbMiniTweet *t,
                     JsonObject  *obj)
{
  GDateTime *time = parse_created_at (json_object_get_string_member (obj, "created_at"));

  t->id = json_object_get_int_member (obj, "id");
  t->text = g_strdup (json_object_get_string_member (obj, "text"));
  t->created_at = g_date_time_to_unix (time);
  cb_user_identity_parse (&t->author, json_object_get_object_member (obj, "user"));

  g_date_time_unref (time);
}

static int
json_object_get_member_size (JsonObject *obj,
                             const char *member_name)
{
  if (!obj || !json_object_has_member (obj, member_name))
    return 0;

  return (int)json_array_get_length (json_object_get_array_member (obj, member_name));
}

void
cb_mini_tweet_parse_entities (CbMiniTweet *t,
                              JsonObject  *status)
{
  JsonObject *entities     = json_object_get_object_member (status, "entities");
  JsonArray *urls          = json_object_get_array_member (entities, "urls");
  JsonArray *hashtags      = json_object_get_array_member (entities, "hashtags");
  JsonArray *user_mentions = json_object_get_array_member (entities, "user_mentions");
  JsonArray *media_arrays[2];
  int media_count = json_object_get_member_size (entities, "media");
  guint i, p;
  int url_index = 0;
  guint n_media_arrays = 0;
  int max_entities;

  if (json_object_has_member (status, "extended_entities"))
    media_count +=  json_object_get_member_size (json_object_get_object_member (status, "extended_entities"),
                                                 "media");

  max_entities = json_array_get_length (urls) +
                                      json_array_get_length (hashtags) +
                                      json_array_get_length (user_mentions) +
                                      media_count;
  media_count += (int)json_array_get_length (urls);


  t->medias   = g_new0 (CbMedia*, media_count);
  t->entities = g_new0 (CbTextEntity, max_entities);
  /*
   * TODO: display_text and tooltip_text are often the same here, can we just set them to the
   *       same value and only free one?
   */

  /* URLS */
  for (i  = 0, p = json_array_get_length (urls); i < p; i ++)
    {
      JsonObject *url = json_node_get_object (json_array_get_element (urls, i));
      const char *expanded_url = json_object_get_string_member (url, "expanded_url");
      JsonArray *indices;

      if (is_media_candidate (expanded_url))
        {
          t->medias[t->n_medias] = cb_media_new ();
          t->medias[t->n_medias]->url = g_strdup (expanded_url);
          t->medias[t->n_medias]->type = cb_media_type_from_url (expanded_url);
          t->n_medias ++;
        }

      indices = json_object_get_array_member (url, "indices");
      t->entities[url_index].from = json_array_get_int_element (indices, 0);
      t->entities[url_index].to   = json_array_get_int_element (indices, 1);
      t->entities[url_index].display_text = escape_ampersand (json_object_get_string_member (url, "display_url"));
      t->entities[url_index].tooltip_text = escape_ampersand (expanded_url);
      t->entities[url_index].target = escape_ampersand (expanded_url);

      url_index ++;
    }

  /* HASHTAGS */
  for (i = 0, p = json_array_get_length (hashtags); i < p; i ++)
    {
      JsonObject *hashtag = json_node_get_object (json_array_get_element (hashtags, i));
      JsonArray  *indices = json_object_get_array_member (hashtag, "indices");
      const char *text    = json_object_get_string_member (hashtag, "text");

      t->entities[url_index].from = json_array_get_int_element (indices, 0);
      t->entities[url_index].to   = json_array_get_int_element (indices, 1);
      t->entities[url_index].display_text = g_strdup_printf ("#%s", text);
      t->entities[url_index].tooltip_text = g_strdup_printf ("#%s", text);
      t->entities[url_index].target = NULL;

      url_index ++;
    }

  /* USER MENTIONS */
  for (i = 0, p = json_array_get_length (user_mentions); i < p; i ++)
    {
      JsonObject *mention = json_node_get_object (json_array_get_element (user_mentions, i));
      JsonArray  *indices = json_object_get_array_member (mention, "indices");
      const char *screen_name = json_object_get_string_member (mention, "screen_name");
      const char *id_str = json_object_get_string_member (mention, "id_str");

      t->entities[url_index].from = json_array_get_int_element (indices, 0);
      t->entities[url_index].to   = json_array_get_int_element (indices, 1);
      t->entities[url_index].display_text = g_strdup_printf ("@%s", screen_name);
      t->entities[url_index].tooltip_text = g_strdup (json_object_get_string_member (mention, "name"));
      t->entities[url_index].target = g_strdup_printf ("@%s/@%s", id_str, screen_name);
      url_index ++;
    }

  /* MEDIA */
  if (json_object_has_member (entities, "media"))
    {
      JsonArray *medias = json_object_get_array_member (entities, "media");

      for (i = 0, p = json_array_get_length (medias); i < p; i ++)
        {
          JsonObject *url = json_node_get_object (json_array_get_element (medias, i));
          JsonArray  *indices = json_object_get_array_member (url, "indices");
          /*const char *expanded_url = json_object_get_string_member (url, "expanded_url");*/

          t->entities[url_index].from = json_array_get_int_element (indices, 0);
          t->entities[url_index].to   = json_array_get_int_element (indices, 1);
          t->entities[url_index].display_text = escape_ampersand (json_object_get_string_member (url, "display_url"));
          t->entities[url_index].target = escape_ampersand (json_object_get_string_member (url, "url"));

          url_index ++;
        }
    }

  /* entities->media and extended_entities contain exactly the same media objects,
     but extended_entities is not always present, and entities->media doesn't
     contain all the attached media, so parse both the same way... */

  i = 0;
  if (json_object_has_member (entities, "media")) n_media_arrays ++;
  if (json_object_has_member (status, "extended_entities")) n_media_arrays ++;
  if (json_object_has_member (entities, "media"))
    media_arrays[i++] = json_object_get_array_member (entities, "media");
  if (json_object_has_member (status, "extended_entities"))
    media_arrays[i] = json_object_get_array_member (json_object_get_object_member (status, "extended_entities"),
                                                    "media");

  for (i = 0; i < n_media_arrays; i ++)
    {
      guint x, k;
      for (x = 0, p = json_array_get_length (media_arrays[i]); x < p; x ++)
        {
          JsonObject *media_obj = json_node_get_object (json_array_get_element (media_arrays[i], x));
          const char *media_type = json_object_get_string_member (media_obj, "type");

          if (strcmp (media_type, "photo") == 0)
            {
              const char *url = json_object_get_string_member (media_obj, "media_url");
              gboolean dup = FALSE;

              /* Remove duplicates */
              for (k = 0; k < t->n_medias; k ++)
                {
                  if (t->medias[k] != NULL && strcmp (t->medias[k]->url, url) == 0)
                    {
                      dup = TRUE;
                      break;
                    }
                }

              if (dup)
                continue;

              if (is_media_candidate (url))
                {
                  t->medias[t->n_medias] = cb_media_new ();
                  t->medias[t->n_medias]->url = g_strdup (url);
                  t->medias[t->n_medias]->target_url = g_strdup_printf ("%s:orig", url);

                  if (json_object_has_member (media_obj, "sizes"))
                    {
                      JsonObject *sizes = json_object_get_object_member (media_obj, "sizes");
                      JsonObject *medium = json_object_get_object_member (sizes, "medium");

                      t->medias[t->n_medias]->width  = json_object_get_int_member (medium, "w");
                      t->medias[t->n_medias]->height = json_object_get_int_member (medium, "h");
                    }

                  t->n_medias ++;
                }

            }
          else if (strcmp (media_type, "video")        == 0 ||
                   strcmp (media_type, "animated_gif") == 0)
            {
              JsonObject *video_info = json_object_get_object_member (media_obj, "video_info");
              JsonArray  *variants = json_object_get_array_member (video_info, "variants");
              JsonObject *variant = NULL;
              int thumb_width  = -1;
              int thumb_height = -1;
              /*gboolean hls_found = FALSE;*/
              guint q;

              if (json_object_has_member (media_obj, "sizes"))
                {
                  JsonObject *sizes = json_object_get_object_member (media_obj, "sizes");
                  JsonObject *medium = json_object_get_object_member (sizes, "medium");

                  thumb_width  = json_object_get_int_member (medium, "w");
                  thumb_height = json_object_get_int_member (medium, "h");
                }

              for (k = 0, q = json_array_get_length (variants); k < q; k ++)
                {
                  JsonObject *v = json_node_get_object (json_array_get_element (variants, k));
                  if (strcmp (json_object_get_string_member (v, "content_type"), "application/x-mpegURL") == 0)
                    {
                      /*hls_found = TRUE;*/
                      variant = v;
                      break;
                    }
                }

#if 0
              if (!hls_found)
                {
                  /* We pick the mp4 variant with size closest to the thumbnails size, but not bigger */
                  for (k = 0, q = json_array_get_length (variants); k < q; k ++)
                    {
                      JsonObject *v = json_node_get_object (json_array_get_element (variants, k));
                      if (strcmp (json_object_get_string_member (v, "content_type"), "video/mp4") == 0)
                        {

                        }
                    }
                }
#endif

              if (variant == NULL && json_array_get_length (variants) > 0)
                variant = json_node_get_object (json_array_get_element (variants, 0));

              if (variant != NULL)
                {
                  t->medias[t->n_medias] = cb_media_new ();
                  t->medias[t->n_medias]->url = g_strdup (json_object_get_string_member (variant, "url"));
                  t->medias[t->n_medias]->thumb_url = g_strdup (json_object_get_string_member (media_obj, "media_url"));
                  t->medias[t->n_medias]->type   = CB_MEDIA_TYPE_TWITTER_VIDEO;
                  t->medias[t->n_medias]->width  = thumb_width;
                  t->medias[t->n_medias]->height = thumb_height;
                  t->n_medias ++;
                }
            }
          else
            {
              g_debug ("Unhandled media type: %s", media_type);
            }
        }
    }

  t->n_entities = url_index;
#if 0
  g_debug ("Wasted entities: %d", max_entities - t->n_entities);
  g_debug ("Wasted media   : %d", media_count  - t->n_medias);
#endif

  if (t->n_medias > 0)
    cb_media_downloader_load_all (cb_media_downloader_get_default (), t);

  if (t->n_entities > 0)
    {
      guint i, k;
      /* Sort entities. */
      for (i = 0; i < t->n_entities; i ++)
        for (k = 0; k < t->n_entities; k++)
          if (t->entities[i].from < t->entities[k].from)
            {
              CbTextEntity tmp = { 0 };
              cb_text_entity_copy (&t->entities[i], &tmp);
              cb_text_entity_copy (&t->entities[k], &t->entities[i]);
              cb_text_entity_copy (&tmp, &t->entities[k]);

              cb_text_entity_free (&tmp);
            }
    }
}
