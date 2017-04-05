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
#include "CbUtils.h"
#include <string.h>
#include <ctype.h>

#define TWEET_URL_LENGTH 23

static const char *TLDS[] = {
  "com",  "net",  "org",    "xxx",  "sexy", "pro",
  "biz",  "name", "info",   "arpa", "gov",  "aero",
  "asia", "cat",  "coop",   "edu",  "int",  "jobs",
  "mil",  "mobi", "museum", "post", "tel",  "travel"
};

static inline gboolean
is_tld (const char *str)
{
  guint i;

  for (i = 0; i < G_N_ELEMENTS (TLDS); i ++)
    {
      if (strcmp (TLDS[i], str) == 0)
        return TRUE;
    }

  return FALSE;
}

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
      case '#':
      case ' ':
      case '\t':
      case '\n':
        return TRUE;

      default:
        return FALSE;
    }

  return FALSE;
}

void
read_next_word (utf8iter *iter,
                gsize    *word_length)
{
  /* Handle the case of a splitting char at the beginning
   * of the word specially
   */
  if (splits_word (iter->cur))
    {
      *word_length = 1;
      utf8_iter_next (iter);
      return;
    }

  do {
    utf8_iter_next (iter);
    *word_length = *word_length + 1;

    if (splits_word (iter->cur))
      break;

  } while (iter->cur != '\0');
}

#if 0
void
parse_protocol_link (utf8iter *iter,
                     gsize    *link_size)
{
  /* Link start with either 'http:' or 'https:'.
   * That is, if they have a protocol attached. http and https are the only
   * protocols Twitter considers.
   */

  if (iter->cur != ':')
    return;

  utf8_iter_next (iter);
  *link_size = *link_size + 1;

  if (iter->cur != '/')
    return;

  utf8_iter_next (iter);
  *link_size = *link_size + 1;

  if (iter->cur != '/')
    return;

  while (iter->cur != '\0' &&
         !isspace (iter->cur))
    {
      utf8_iter_next (iter);
      *link_size = *link_size + 1;
    }


  /* If we reach this point then yes, this really was a link. */
  *link_size = TWEET_URL_LENGTH;
}

#endif

static gsize
parse_protocol_link (GPtrArray *words,
                     guint     *i)
{
  const char *w;
  gsize cur_len;
  gboolean have_link = FALSE;
  int parens = 0;
  gsize first_paren_index = 0;

  g_assert (*i < words->len);


  cur_len = g_utf8_strlen ((char *)g_ptr_array_index (words, *i), -1);

  // TODO: Check indices
  // TODO: Return failure?
  if (strcmp ((char *)g_ptr_array_index (words, *i + 1), ":") != 0)
    return cur_len;

  *i = *i + 1;
  cur_len ++;

  if (strcmp ((char *)g_ptr_array_index (words, *i + 1), "/") != 0)
    return cur_len;

  *i = *i + 1;
  cur_len ++;

  if (strcmp ((char *)g_ptr_array_index (words, *i + 1), "/") != 0)
    return cur_len;

  *i = *i + 1;
  cur_len ++;

  /* Skip current '/' */
  *i = *i + 1;

  /* We have 'https(s)://', so we need to parse until we find a valid TLD,
   * then parse the rest until the next whitespace.
   * If we can't find a valid TLD, or it appears too early, i.e. as part of a subdomain,
   * this is not a link. */


  /*
   * First, we need to find the correct TLD.
   * After that, special rules apply, e.g. when open/closed parentheses
   * count as part of the link or not.
   *
   * If we find a valid TLD, we at least have a link.
   */
  for (; *i < words->len; *i = *i + 1)
    {
      const char *word = g_ptr_array_index (words, *i);

      cur_len += g_utf8_strlen (word, -1);

      if (is_tld (word) &&
          strcmp ((const char *)g_ptr_array_index (words, (*i) - 1), ".") == 0)
        {
          have_link = TRUE;
          /* Skip it */
          *i = *i + 1;
          break;
        }
    }

  if (!have_link)
    return cur_len;

  /* End of string? */
  if (*i == words->len)
    return TWEET_URL_LENGTH;

  /* Port */
#if 0
  w = g_ptr_array_index (words, *i);
  if (strcmp (w, ":") == 0)
    {
      /* Must be followed by all-numbers */
    }

#endif

  /* Now that we know the TLD is there, we need to apply special rules for some characters,
   * see the unit tests for way too many examples */

  /* Current word has to be a '/' or a '?' */
  w = g_ptr_array_index (words, *i);
  g_message ("'%s'", w);
  if (strcmp (w, "/") != 0 &&
      strcmp (w, "?") != 0)
    {
      /* The part until now is still a valid link.
       * Return the tweet url length and go one word back
       * so the main loop catches that one again */
      *i = *i - 1;
      return TWEET_URL_LENGTH;
    }
  *i = *i + 1;

  /* we have a valid link, now parse the part after the TLD */

  for (; *i < words->len; *i = *i + 1)
    {
      const char *word = g_ptr_array_index (words, *i);

      if (strcmp (word, "(") == 0)
        {
          if (parens == 0)
            first_paren_index = *i;
          parens ++;
        }
      else if (strcmp (word, ")") == 0)
        {
          if (parens == 0)
            first_paren_index = *i;
          parens --;
        }

      if (parens < 0)
        {
          *i = *i - 1;
          /* Wrong. not a link anymore from this point forward */
          return TWEET_URL_LENGTH;
        }
    }

  if (parens != 0)
    {
      /* Unbalanced sequence of parens */
      *i = first_paren_index - 1;
      return TWEET_URL_LENGTH;
    }

  if (have_link)
    return TWEET_URL_LENGTH;

  return cur_len;
}


gsize
cb_tweet_counter_count_chars (const char *text)
{
  utf8iter iter;
  gsize text_length = 0;
  guint i;
  GPtrArray *words = g_ptr_array_new_with_free_func (g_free);

  g_return_val_if_fail (text != NULL, 0);

  utf8_iter_init (&iter, text);

  /* Split the input string into a sequence of words */

  while (!iter.done)
    {
      const char *saved = iter.cur_p;
      gsize n_word_chars = 0;

      /* TODO: Possible Optimization: Save a string + length pair in the GPtrArray
       *       and use that utf8 length later on, since we are already computing it here. */
      read_next_word (&iter, &n_word_chars);

      g_ptr_array_add (words, g_strndup (saved, iter.cur_p - saved));
    }

  g_message ("Words: %u", words->len);

  for (i = 0; i < words->len; i ++)
    g_message ("Word %u: '%s'", i, (char*)g_ptr_array_index (words, i));


  for (i = 0; i < words->len; i ++)
    {
      const char *word = g_ptr_array_index (words, i);

      g_message ("Main: Checking '%s'", word);

      if (strcmp (word, "http")  == 0 ||
          strcmp (word, "https") == 0)
        {
          /* Next 3 words should be ':', '/' and '/' respectively.
           * Otherwise this is not even the start of a link */
          gsize link_length = parse_protocol_link (words, &i);

          g_message ("Link length: %ld", link_length);
          g_message ("i: %u/%u", i, words->len);

          text_length += link_length;
        }
      else
        {
          /* Normal word, just add its length to the text length */
          text_length += g_utf8_strlen (word, -1);
        }
    }

  g_ptr_array_unref (words);

  return text_length;
}
