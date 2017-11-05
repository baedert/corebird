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

#include "CbTypes.h"
#include "CbMediaDownloader.h"
#include "CbUtils.h"
#include <string.h>
#include <stdlib.h>

void
cb_user_identity_free (CbUserIdentity *id)
{
  g_free (id->screen_name);
  g_free (id->user_name);
}

void
cb_user_identity_copy (const CbUserIdentity *id, CbUserIdentity *id2)
{
  g_free (id2->screen_name);
  id2->screen_name = g_strdup (id->screen_name);
  g_free (id2->user_name);
  id2->user_name = g_strdup (id->user_name);
  id2->id = id->id;
  id2->verified = id->verified;
}

void cb_user_identity_parse (CbUserIdentity *id,
                             JsonObject     *user_obj)
{
  id->id = json_object_get_int_member (user_obj, "id");
  id->screen_name = g_strdup (json_object_get_string_member (user_obj, "screen_name"));
  id->user_name = cb_utils_escape_ampersands (json_object_get_string_member (user_obj, "name"));
  id->verified = json_object_get_boolean_member (user_obj, "verified");
}


void
cb_text_entity_free (CbTextEntity *e)
{
  g_free (e->display_text);
  g_free (e->tooltip_text);
  g_free (e->target);
}

void
cb_text_entity_copy (const CbTextEntity *e1, CbTextEntity *e2)
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

  for (i = 0; i < t->n_reply_users; i ++)
    cb_user_identity_free (&t->reply_users[i]);
  g_free (t->reply_users);

  cb_user_identity_free (&t->author);
}

void
cb_mini_tweet_copy (const CbMiniTweet *t1, CbMiniTweet *t2)
{
  guint i;

  t2->id = t1->id;
  t2->created_at = t1->created_at;
  cb_user_identity_copy (&t1->author, &t2->author);
  g_free (t2->text);
  t2->text = g_strdup (t1->text);

  t2->n_entities = t1->n_entities;
  t2->entities = g_new0 (CbTextEntity, t2->n_entities);
  for (i = 0; i < t2->n_entities; i ++)
    cb_text_entity_copy (&t1->entities[i], &t2->entities[i]);

  t2->n_medias = t1->n_medias;
  t2->medias = g_new0 (CbMedia*, t2->n_medias);
  for (i = 0; i < t2->n_medias; i ++)
    t2->medias[i] = g_object_ref (t1->medias[i]);
}

void
cb_mini_tweet_init (CbMiniTweet *t)
{
  t->reply_id = 0;
  t->medias = NULL;
  t->n_medias = 0;
  t->entities = NULL;
  t->n_entities = 0;
  t->reply_users = NULL;
  t->n_reply_users = 0;
}

void
cb_mini_tweet_parse (CbMiniTweet *t,
                     JsonObject  *obj)
{
  GDateTime *time;
  JsonObject *extended_object;
  const char *tweet_text;

  if (json_object_has_member (obj, "extended_tweet"))
    extended_object = json_object_get_object_member (obj, "extended_tweet");
  else
    extended_object = obj;

  time = cb_utils_parse_date (json_object_get_string_member (obj, "created_at"));

  t->id = json_object_get_int_member (obj, "id");
  if (json_object_has_member (extended_object, "full_text"))
    tweet_text = json_object_get_string_member (extended_object, "full_text");
  else
    tweet_text = json_object_get_string_member (extended_object, "text");

  if (json_object_has_member (extended_object, "display_text_range"))
    {
      /* We only remove the prefix */
      guint start = (guint)json_array_get_int_element (
                          json_object_get_array_member (extended_object, "display_text_range"),
                          0);
      guint i;
      const char *p = tweet_text;

      /* Skip ahead */
      for (i = 0; i < start; i ++)
        p = g_utf8_next_char (p);

      t->text = g_strdup (p);
      t->display_range_start = start;
    }
  else
    {
      t->text = g_strdup (tweet_text);
      t->display_range_start= 0;
    }

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
  JsonObject *extended_obj = status;
  JsonObject *entities;
  JsonArray *urls;
  JsonArray *hashtags;
  JsonArray *user_mentions;
  JsonArray *media_arrays[2];
  int media_count;
  guint i, p;
  int url_index = 0;
  guint n_media_arrays = 0;
  guint n_reply_users = 0;
  guint non_reply_mentions = 0;
  int max_entities;
  gboolean direct_duplicate = FALSE;

  if (json_object_has_member (status, "extended_tweet"))
    extended_obj = json_object_get_object_member (status, "extended_tweet");

  entities      = json_object_get_object_member (extended_obj, "entities");
  urls          = json_object_get_array_member (entities, "urls");
  hashtags      = json_object_get_array_member (entities, "hashtags");
  user_mentions = json_object_get_array_member (entities, "user_mentions");
  media_count   = json_object_get_member_size (entities, "media");


  if (json_object_has_member (status, "extended_entities"))
    media_count += json_object_get_member_size (json_object_get_object_member (status, "extended_entities"),
                                                "media");

  if (json_object_has_member (status, "in_reply_to_status_id") &&
      !json_object_get_null_member (status, "in_reply_to_status_id"))
    {
      guint reply_index = 0;
      gint64 reply_to_user_id = 0;

      reply_to_user_id = json_object_get_int_member (status, "in_reply_to_user_id");

      /* Check how many of the user mentions are reply mentions */
      t->reply_id = json_object_get_int_member (status, "in_reply_to_status_id");
      for (i = 0, p = json_array_get_length (user_mentions); i < p; i ++)
        {
          JsonObject *mention = json_node_get_object (json_array_get_element (user_mentions, i));
          JsonArray  *indices = json_object_get_array_member (mention, "indices");
          gint64 user_id = json_object_get_int_member (mention, "id");

          if (json_array_get_int_element (indices, 1) <= t->display_range_start)
              n_reply_users ++;
          else
            break;

          if (i == 0 && user_id == reply_to_user_id)
            direct_duplicate = TRUE;
        }

      if (!direct_duplicate)
        n_reply_users ++;

      t->reply_users = g_new0 (CbUserIdentity, n_reply_users);
      t->n_reply_users = n_reply_users;

      if (!direct_duplicate)
        {
          t->reply_users[0].id = reply_to_user_id;
          t->reply_users[0].screen_name = g_strdup (json_object_get_string_member (status, "in_reply_to_screen_name"));
          t->reply_users[0].user_name = g_strdup ("");
          reply_index = 1;
        }

      /* Now fill ->reply_users. The very first entry is always the user this tweet
       * *actually* replies to. */
      for (i = 0;
           i < n_reply_users - (direct_duplicate ? 0 : 1);
           i ++)
        {
          JsonObject *mention = json_node_get_object (json_array_get_element (user_mentions, i));
          t->reply_users[reply_index].id = json_object_get_int_member (mention, "id");
          t->reply_users[reply_index].screen_name = g_strdup (json_object_get_string_member (mention, "screen_name"));
          t->reply_users[reply_index].user_name = g_strdup (json_object_get_string_member (mention, "name"));
          reply_index ++;
        }

      non_reply_mentions = n_reply_users - 1;
    }

  max_entities = json_array_get_length (urls) +
                 json_array_get_length (hashtags) +
                 json_array_get_length (user_mentions) - non_reply_mentions +
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
          t->medias[t->n_medias]->target_url = g_strdup (expanded_url);
          t->n_medias ++;
        }

      indices = json_object_get_array_member (url, "indices");
      t->entities[url_index].from = json_array_get_int_element (indices, 0);
      t->entities[url_index].to   = json_array_get_int_element (indices, 1);
      t->entities[url_index].display_text = cb_utils_escape_ampersands (json_object_get_string_member (url, "display_url"));
      t->entities[url_index].tooltip_text = cb_utils_escape_ampersands (expanded_url);
      t->entities[url_index].target = cb_utils_escape_ampersands (expanded_url);

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
  if (direct_duplicate)
    i = n_reply_users;
  else
    i = n_reply_users == 0 ? 0 : n_reply_users - 1;

  for (p = json_array_get_length (user_mentions); i < p; i ++)
    {
      JsonObject *mention = json_node_get_object (json_array_get_element (user_mentions, i));
      JsonArray  *indices = json_object_get_array_member (mention, "indices");
      const char *screen_name = json_object_get_string_member (mention, "screen_name");
      const char *id_str = json_object_get_string_member (mention, "id_str");

      t->entities[url_index].from = json_array_get_int_element (indices, 0);
      t->entities[url_index].to   = json_array_get_int_element (indices, 1);
      t->entities[url_index].display_text = g_strdup_printf ("@%s", screen_name);
      t->entities[url_index].tooltip_text = cb_utils_escape_ampersands (json_object_get_string_member (mention, "name"));
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
          char *url_str = cb_utils_escape_ampersands (json_object_get_string_member (url, "url"));
          int k;
          gboolean duplicate = FALSE;

          /* Check for duplicates */
          for (k = 0; k < url_index; k ++)
            {
              const char *target = t->entities[k].target;
              if (target != NULL && strcmp (target, url_str) == 0)
                {
                  duplicate = TRUE;
                  break;
                }
            }

          if (duplicate)
            {
              g_free (url_str);
              continue;
            }

          t->entities[url_index].from = json_array_get_int_element (indices, 0);
          t->entities[url_index].to   = json_array_get_int_element (indices, 1);
          t->entities[url_index].display_text = cb_utils_escape_ampersands (json_object_get_string_member (url, "display_url"));
          t->entities[url_index].target = url_str;

          url_index ++;
        }
    }

  /* entities->media and extended_entities contain exactly the same media objects,
     but extended_entities is not always present, and entities->media doesn't
     contain all the attached media, so parse both the same way... */
  if (json_object_has_member (entities, "media"))
    {
      media_arrays[n_media_arrays] = json_object_get_array_member (entities, "media");
      n_media_arrays ++;
    }

  if (json_object_has_member (status, "extended_entities"))
    {
      media_arrays[n_media_arrays] = json_object_get_array_member (json_object_get_object_member (status,
                                                                                                  "extended_entities"),
                                                                   "media");

      n_media_arrays ++;
    }

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
                  t->medias[t->n_medias]->type = CB_MEDIA_TYPE_IMAGE;
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
                      variant = v;
                      break;
                    }
                }

              if (variant == NULL && json_array_get_length (variants) > 0)
                variant = json_node_get_object (json_array_get_element (variants, 0));

              if (variant != NULL)
                {
                  guint n_media = t->n_medias;
                  const char *thumb_url = json_object_get_string_member (media_obj, "media_url");
                  /* Some tweets have both a video and a thumbnail for that video attached. The tweet json
                   * will list the image first. The url of the image and the thumb_url of the video will match
                   */
                  for (k = 0; k < t->n_medias; k ++)
                    {
                      if (t->medias[k] != NULL &&
                          t->medias[k]->type == CB_MEDIA_TYPE_IMAGE &&
                          strcmp (t->medias[k]->url, thumb_url) == 0)
                        {
                          /* Replace this media */
                          g_object_unref (t->medias[k]);
                          n_media = k;
                          break;
                        }
                    }

                  t->medias[n_media] = cb_media_new ();
                  t->medias[n_media]->url = g_strdup (json_object_get_string_member (variant, "url"));
                  t->medias[n_media]->thumb_url = g_strdup (thumb_url);
                  t->medias[n_media]->type   = CB_MEDIA_TYPE_TWITTER_VIDEO;
                  t->medias[n_media]->width  = thumb_width;
                  t->medias[n_media]->height = thumb_height;

                  if (n_media == t->n_medias)
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
