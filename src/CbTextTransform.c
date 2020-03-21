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

#include "CbTextTransform.h"
#include "CbMediaDownloader.h"
#include "CbTypes.h"
#include "CbUtils.h"
#include <string.h>
#include <ctype.h>

char *
cb_text_transform_tweet (const CbMiniTweet *tweet,
                         guint              flags,
                         guint64            quote_id)
{
  return cb_text_transform_text (tweet->text,
                                 tweet->entities,
                                 tweet->n_entities,
                                 flags,
                                 tweet->n_medias,
                                 quote_id,
                                 0);
  /* TODO: Remove display_range_start parameter from transform_text */
}

const int TRAILING = 1 << 0;


static inline gboolean
is_hashtag (const char *s)
{
  return s[0] == '#';
}

static inline gboolean
is_link (const char *s)
{
  return s != NULL && (g_str_has_prefix (s, "http://") || g_str_has_prefix (s, "https://"));
}

static inline gboolean
is_quote_link (const CbTextEntity *e, gint64 quote_id)
{
  char *suffix = g_strdup_printf ("/status/%" G_GINT64_FORMAT, quote_id);
  gboolean ql;

  ql = (e->target != NULL) &&
       (g_str_has_prefix (e->target, "https://twitter.com/") &&
        g_str_has_suffix (e->target, suffix));

  g_free (suffix);

  return ql;
}

static inline gboolean
is_media_url (const char *url,
              const char *display_text,
              gsize       media_count)
{
  return (is_media_candidate (url != NULL ? url : display_text) && media_count == 1) ||
         g_str_has_prefix (display_text, "pic.twitter.com/");
}

static inline gboolean
is_whitespace (const char *s)
{
  while (*s != '\0')
    {
      if (!isspace (*s))
        return FALSE;

      s++;
    }

  return TRUE;
}

char *
cb_text_transform_text (const char         *text,
                        const CbTextEntity *entities,
                        gsize               n_entities,
                        guint               flags,
                        gsize               n_medias,
                        gint64              quote_id,
                        guint               display_range_start)
{
  GString *str;
  const  guint text_len   = g_utf8_strlen (text, -1);
  int i;
  char *end_str;
  gboolean last_entity_was_trailing = FALSE;
  guint last_end = 0;
  guint cur_end = text_len;
  gint32 *info;

  if (text_len == 0)
    return g_strdup (text);

  str = g_string_new (NULL);

  info = g_newa (gint32, n_entities);
  memset (info, 0, n_entities * sizeof (gint32));

  for (i = (int)n_entities - 1; i >= 0; i --)
    {
      char *btw;
      guint entity_to;
      gsize btw_length = cur_end - entities[i].to;

      if (entities[i].to <= display_range_start)
        continue;

      entity_to = entities[i].to - display_range_start;

      btw = g_utf8_substring (text,
                              entity_to,
                              cur_end);

      if (!is_whitespace (btw) && btw_length > 0)
        {
          g_free (btw);
          break;
        }
      else
        cur_end = entity_to;

      if (entities[i].to == cur_end &&
          (is_hashtag (entities[i].display_text) || is_link (entities[i].target)))
          {
            info[i] |= TRAILING;
            cur_end = entities[i].from - display_range_start;
          }
      else
        {
          g_free (btw);
          break;
        }

      g_free (btw);
    }


  for (i = 0; i < (int)n_entities; i ++)
    {
      const CbTextEntity *entity = &entities[i];
      char *before;
      guint entity_to;

      if (entity->to <= display_range_start)
        continue;

      entity_to = entity->to - display_range_start;
      before = g_utf8_substring (text,
                                 last_end,
                                 entity->from - display_range_start);

      if (!(last_entity_was_trailing && is_whitespace (before)))
        g_string_append (str, before);

      if ((flags & CB_TEXT_TRANSFORM_REMOVE_TRAILING_HASHTAGS) > 0 &&
          (info[i] & TRAILING) > 0 &&
          is_hashtag (entity->display_text))
        {
          last_end = entity_to;
          last_entity_was_trailing = TRUE;
          g_free (before);
          continue;
        }

      last_entity_was_trailing = FALSE;

      if (((flags & CB_TEXT_TRANSFORM_REMOVE_MEDIA_LINKS) > 0 &&
           is_media_url (entity->target, entity->display_text, n_medias)) ||
          (quote_id != 0 && is_quote_link (entity, quote_id)))
        {
          last_end = entity_to;
          g_free (before);
          continue;
        }

      if ((flags & CB_TEXT_TRANSFORM_EXPAND_LINKS) > 0)
        {
          if (entity->display_text[0] == '@')
            g_string_append (str, entity->display_text);
          else
            g_string_append (str, entity->target ? entity->target : entity->display_text);
        }
      else
        {
          g_string_append (str, "<span underline=\"none\"><a href=\"");
          g_string_append (str, entity->target ? entity->target : entity->display_text);
          g_string_append (str, "\"");

          if (entity->tooltip_text != NULL)
            {
              char *c = cb_utils_escape_ampersands (entity->tooltip_text);
              char *cc = cb_utils_escape_quotes (c);

              g_string_append (str, " title=\"");
              g_string_append (str, cc);
              g_string_append (str, "\"");

              g_free (cc);
              g_free (c);
            }

          g_string_append (str, ">");
          g_string_append (str, entity->display_text);
          g_string_append (str,"</a></span>");
        }

      last_end = entity_to;
      g_free (before);
    }

  end_str = g_utf8_substring (text, last_end, text_len);
  g_string_append (str, end_str);

  g_free (end_str);

  /* As a last step, make sure that removing trailing hashtags did not leave some
   * trailing whitespace (esp. newlines) behind.
   * Technically, that condition is too lax but it's good enough in practice and
   * we actually *never* care about trailing whitespace and can alway safely
   * remove it. */
  if ((flags & CB_TEXT_TRANSFORM_REMOVE_TRAILING_HASHTAGS) > 0 &&
      strlen (str->str) > 0)
    {
      char *p = str->str + str->len;
      gunichar c = g_utf8_get_char (p);

      while (c == '\0' || g_unichar_isspace (c))
        {
          p = g_utf8_prev_char (p);

          if (p == str->str)
            break;

          c = g_utf8_get_char (p);
        }

      /* Go one forward again, since the current character is the first non-space one. */
      p = g_utf8_next_char (p);

      g_string_truncate (str, p - str->str);
    }

  return g_string_free (str, FALSE);
}

char *
cb_text_transform_raw (const char *input)
{
  GString *str = g_string_new (NULL);
  const char *p;
  gunichar c;

  p = input;
  c = g_utf8_get_char (input);
  while (1)
    {
      if (c == '<')
        {
          const char *tag_start = p + 1; /* Skip < */
          gsize len;

          while (c != '>' && c != '\0')
            {
              p = g_utf8_next_char (p);
              c = g_utf8_get_char (p);
            }

          len = p - tag_start;
          if (strncmp (tag_start, "br", len) == 0 ||
              strncmp (tag_start, "br/", len) == 0 ||
              strncmp (tag_start, "br /", len) == 0)
            g_string_append_c (str, '\n');
          else if (strncmp (tag_start, "/p", len) == 0)
            {
              /* End of paragraph -> double newline */
              g_string_append_c (str, '\n');
              g_string_append_c (str, '\n');
            }
          else
            {
              /*GString *s = g_string_new (NULL);*/
              /*g_string_append_len (s, tag_start, len);*/
              /*g_message ("Tag: %s", s->str);*/
            }
          /* Ignore all other tags */
          /* TODO: This is a good way of finding out about links of course. Also this is all shit. */

          /* Skip to next one */
          goto next;
        }

      g_string_append_unichar (str, c);

next:
      /* Next char */
      p = g_utf8_next_char (p);
      c = g_utf8_get_char (p);

      if (c == '\0')
        break;
    }

  /* Remove trailing whitespace here again. */
  p = g_utf8_prev_char (str->str + str->len);
  c = g_utf8_get_char (p);
  if (g_unichar_isspace (c))
    {
      while (g_unichar_isspace (c))
        {
          p = g_utf8_prev_char (p);
          c = g_utf8_get_char (p);
        }
      g_string_set_size (str, g_utf8_next_char (p) - str->str);
    }

  return g_string_free (str, FALSE);
}
