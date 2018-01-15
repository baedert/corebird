/*  This file is part of libtweetlength
 *  Copyright (C) 2017 Timm Bäder
 *
 *  libtweetlength is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  libtweetlength is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with libtweetlength.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "libtweetlength.h"
#include "data.h"
#include <string.h>

#define LINK_LENGTH 23

typedef struct {
  guint type;
  const char *start;
  gsize start_character_index;
  gsize length_in_bytes;
  gsize length_in_characters;
  gsize length_in_weighted_characters;
} Token;

#ifdef LIBTL_DEBUG
static char * G_GNUC_UNUSED
token_str (const Token *t)
{
  return g_strdup_printf ("Type: %u, Text: '%.*s'", t->type, (int)t->length_in_bytes, t->start);
}

static char * G_GNUC_UNUSED
entity_str (const TlEntity *e)
{
  return g_strdup_printf ("Type: %u, Text: '%.*s'", e->type, (int)e->length_in_bytes, e->start);
}

#endif

enum {
  TOK_TEXT = 1,
  TOK_NUMBER,
  TOK_WHITESPACE,
  TOK_COLON,
  TOK_SLASH,
  TOK_OPEN_PAREN,
  TOK_CLOSE_PAREN,
  TOK_QUESTIONMARK,
  TOK_DOT,
  TOK_HASH,
  TOK_AT,
  TOK_EQUALS,
  TOK_DASH,
  TOK_UNDERSCORE,
  TOK_APOSTROPHE,
  TOK_QUOTE,
  TOK_DOLLAR,
  TOK_AMPERSAND,
  TOK_EXCLAMATION,
  TOK_TILDE
};

static inline guint
token_type_from_char (gunichar c)
{
  switch (c) {
    case '@':
      return TOK_AT;
    case '#':
      return TOK_HASH;
    case ':':
      return TOK_COLON;
    case '/':
      return TOK_SLASH;
    case '(':
      return TOK_OPEN_PAREN;
    case ')':
      return TOK_CLOSE_PAREN;
    case '.':
      return TOK_DOT;
    case '?':
      return TOK_QUESTIONMARK;
    case '=':
      return TOK_EQUALS;
    case '-':
      return TOK_DASH;
    case '_':
      return TOK_UNDERSCORE;
    case '\'':
      return TOK_APOSTROPHE;
    case '"':
      return TOK_QUOTE;
    case '$':
      return TOK_DOLLAR;
    case '&':
      return TOK_AMPERSAND;
    case '!':
      return TOK_EXCLAMATION;
    case '~':
      return TOK_TILDE;
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      return TOK_NUMBER;
    case ' ':
    case '\n':
    case '\t':
      return TOK_WHITESPACE;

    default:
      return TOK_TEXT;
  }
}

static inline gboolean
token_ends_in_accented (const Token *t)
{
  const char *p = t->start;
  gunichar c;
  gsize i;

  if (t->length_in_bytes == 1 ||
      t->type != TOK_TEXT) {
    return FALSE;
  }

  // The rules here aren't exactly clear...
  // We read the last character of the text pointed to by the given token.
  // If that's not an ascii character, we return TRUE.
  for (i = 0; i < t->length_in_characters - 1; i ++) {
    p = g_utf8_next_char (p);
  }

  c = g_utf8_get_char (p);

  if (c > 127)
    return TRUE;

  return FALSE;
}

static inline gboolean
token_in (const Token *t,
          const char  *haystack)
{
  const int haystack_len = strlen (haystack);
  int i;

  if (t->length_in_bytes > 1) {
    return FALSE;
  }


  for (i = 0; i < haystack_len; i ++) {
    if (haystack[i] == t->start[0]) {
      return TRUE;
    }
  }

  return FALSE;
}


static inline void
emplace_token (GArray     *array,
               const char *token_start,
               gsize       token_length,
               gsize       start_character_index,
               gsize       length_in_characters,
               gsize       length_in_weighted_characters)
{
  Token *t;

  g_array_set_size (array, array->len + 1);
  t = &g_array_index (array, Token, array->len - 1);

  t->type = token_type_from_char (token_start[0]);
  t->start = token_start;
  t->length_in_bytes = token_length;
  t->start_character_index = start_character_index;
  t->length_in_characters = length_in_characters;
  t->length_in_weighted_characters = length_in_weighted_characters;
}

static inline void
emplace_entity_for_tokens (GArray      *array,
                           const Token *tokens,
                           guint        entity_type,
                           guint        start_token_index,
                           guint        end_token_index)
{
  TlEntity *e;
  guint i;

  g_array_set_size (array, array->len + 1);
  e = &g_array_index (array, TlEntity, array->len - 1);

  e->type = entity_type;
  e->start = tokens[start_token_index].start;
  e->length_in_bytes = 0;
  e->length_in_characters = 0;
  e->length_in_weighted_characters = 0;
  e->start_character_index = tokens[start_token_index].start_character_index;

  for (i = start_token_index; i <= end_token_index; i ++) {
    e->length_in_bytes += tokens[i].length_in_bytes;
    e->length_in_characters += tokens[i].length_in_characters;
    e->length_in_weighted_characters += tokens[i].length_in_weighted_characters;
  }
}

static inline gboolean
is_valid_mention_char (gunichar c)
{
  // Just ASCII
  if (c > 127)
    return FALSE;

  return TRUE;
}


static inline gboolean
token_is_tld (const Token *t,
              gboolean     has_protocol)
{
  guint i;

  if (t->length_in_characters > GTLDS[G_N_ELEMENTS (GTLDS) - 1].length) {
    return FALSE;
  }

  for (i = 0; i < G_N_ELEMENTS (GTLDS); i ++) {
    if (t->length_in_characters == GTLDS[i].length &&
        strncasecmp (t->start, GTLDS[i].str, t->length_in_bytes) == 0) {
      return TRUE;
    }
  }

  for (i = 0; i < G_N_ELEMENTS (SPECIAL_CCTLDS); i ++) {
    if (t->length_in_characters == SPECIAL_CCTLDS[i].length &&
        strncasecmp (t->start, SPECIAL_CCTLDS[i].str, t->length_in_bytes) == 0) {
      return TRUE;
    }
  }

  if (has_protocol) {
    for (i = 0; i < G_N_ELEMENTS (CCTLDS); i ++) {
      if (t->length_in_characters == CCTLDS[i].length &&
          strncasecmp (t->start, CCTLDS[i].str, t->length_in_bytes) == 0) {
        return TRUE;
      }
    }
  }

  return FALSE;
}

static inline gboolean
token_is_protocol (const Token *t)
{
  if (t->type != TOK_TEXT) {
    return FALSE;
  }

  if (t->length_in_bytes != 4 && t->length_in_bytes != 5) {
    return FALSE;
  }

  return strncasecmp (t->start, "http", t->length_in_bytes) == 0 ||
         strncasecmp (t->start, "https", t->length_in_bytes) == 0;
}

static inline gboolean
char_splits (gunichar c)
{
  switch (c) {
    case ',':
    case '.':
    case '/':
    case '?':
    case '(':
    case ')':
    case ':':
    case ';':
    case '=':
    case '@':
    case '#':
    case '-':
    case '_':
    case '\n':
    case '\t':
    case '\0':
    case ' ':
    case '\'':
    case '"':
    case '$':
    case '|':
    case '&':
    case '^':
    case '%':
    case '+':
    case '*':
    case '\\':
    case '{':
    case '}':
    case '[':
    case ']':
    case '`':
    case '~':
    case '!':
      return TRUE;
    default:
      return FALSE;
  }

  return FALSE;
}

static inline gsize
entity_length_in_characters (const TlEntity *e)
{
  switch (e->type) {
    case TL_ENT_LINK:
      return LINK_LENGTH;

    default:
      return e->length_in_characters;
  }
}

static gsize
weighted_length_for_character (gunichar ch)
{
  // Based on https://developer.twitter.com/en/docs/developer-utilities/twitter-text
  // then the following ranges count as "1", everything else is "2":
  //   * 0 - 4351 (Latin through to Georgian)
  //   * 8192 - 8205 (Unicode spaces)
  //   * 8208 - 8223 (Unicode hyphens and smart quotes)
  //   * 8242 - 8247 (Prime marks)
  if ((ch >= 0    && ch <= 4351) ||
      (ch >= 8192 && ch <= 8205) ||
      (ch >= 8208 && ch <= 8223) ||
      (ch >= 8424 && ch <= 8247)) {
    return 1;
  } else {
    return 2;
  }
}

/*
 * tokenize:
 *
 * Returns: (transfer full): Tokens
 */
static GArray *
tokenize (const char *input,
          gsize       length_in_bytes)
{
  GArray *tokens = g_array_new (FALSE, TRUE, sizeof (Token));
  const char *p = input;
  gsize cur_character_index = 0;

  while (p - input < (long)length_in_bytes) {
    const char *cur_start = p;
    gunichar cur_char = g_utf8_get_char (p);
    gsize cur_length = 0;
    gsize length_in_chars = 0;
    gsize length_in_weighted_chars = 0;
    guint last_token_type = 0;

    /* If this char already splits, it's a one-char token */
    if (char_splits (cur_char)) {
      const char *old_p = p;
      p = g_utf8_next_char (p);
      emplace_token (tokens, cur_start, p - old_p, cur_character_index, 1, weighted_length_for_character (cur_char));
      cur_character_index ++;
      continue;
    }

    last_token_type = token_type_from_char (cur_char);
    do {
      length_in_weighted_chars += weighted_length_for_character (cur_char);
      const char *old_p = p;
      p = g_utf8_next_char (p);
      cur_char = g_utf8_get_char (p);
      cur_length += p - old_p;
      length_in_chars ++;

      if (token_type_from_char (cur_char) != last_token_type)
        break;

    } while (!char_splits (cur_char) &&
             p - input < (long)length_in_bytes);

    emplace_token (tokens, cur_start, cur_length, cur_character_index, length_in_chars, length_in_weighted_chars);

    cur_character_index += length_in_chars;
  }

  return g_steal_pointer (&tokens);
}

static gboolean
parse_link_tail (GArray      *entities,
                 const Token *tokens,
                 gsize        n_tokens,
                 guint       *current_position)
{
  guint i = *current_position;
  const Token *t;

  g_debug ("--------");

  gsize paren_level = 0;
  int first_paren_index = -1;
  for (;;) {
    t = &tokens[i];

    if (t->type == TOK_WHITESPACE || t->type == TOK_APOSTROPHE) {
      i --;
      break;
    }

    if (tokens[i].type == TOK_OPEN_PAREN) {

      if (first_paren_index == -1) {
        first_paren_index = i;
        g_debug ("First paren index: %d", (int)first_paren_index);
      }
      paren_level ++;
      if (paren_level == 3) {
        break;
      }
    } else if (tokens[i].type == TOK_CLOSE_PAREN) {
      if (first_paren_index == -1) {
        first_paren_index = i;
        g_debug ("First paren index: %d", (int)first_paren_index);
      }
      g_debug ("Close paren");
      paren_level --;
    }

    i ++;

    if (i == n_tokens) {
      i --;
      break;
    }
  }

  g_debug ("After i: %u", i);
  g_debug ("paren level: %d", (int)paren_level);
  if (paren_level != 0) {
    g_assert (first_paren_index != -1);
    i = first_paren_index - 1; // Before that paren
  }

  t = &tokens[i];
  /* Whatever happened, don't count trailing punctuation */
  if (token_in (t, INVALID_AFTER_URL_CHARS)) {
    i --;
  }

  *current_position = i;

  return TRUE;
}


// Returns whether a link has been parsed or not.
static gboolean
parse_link (GArray      *entities,
            const Token *tokens,
            gsize        n_tokens,
            guint       *current_position)
{
  guint i = *current_position;
  const Token *t;
  guint start_token = *current_position;
  guint end_token;
  gboolean has_protocol = FALSE;

  t = &tokens[i];

  // Some may not even appear before a protocol
  if (i > 0 && token_in (&tokens[i - 1], INVALID_BEFORE_URL_CHARS)) {
    return FALSE;
  }

  if (token_is_protocol (t)) {
    // need "://" now.
    t = &tokens[i + 1];
    if (t->type != TOK_COLON) {
      return FALSE;
    }
    i ++;

    t = &tokens[i + 1];
    if (t->type != TOK_SLASH) {
      return FALSE;
    }
    i ++;

    t = &tokens[i + 1];
    if (t->type != TOK_SLASH) {
      return FALSE;
    }
    // If we are at the end now, this is not a link, just the protocol.
    if (i + 1 == n_tokens - 1) {
      return FALSE;
    }
    i += 2; // Skip to token after second slash
    has_protocol = TRUE;
  } else {
    // Lookbehind: Token before may not be an @, they are not supported.
    if (i > 0 && token_in (&tokens[i - 1], INVALID_BEFORE_NON_PROTOCOL_URL_CHARS)) {
      return FALSE;
    }
  }

  if (token_in (&tokens[i], INVALID_URL_CHARS)) {
    return FALSE;
  }

  // Now read until .tld. There can be multiple (e.g. in http://foobar.com.com.com"),
  // so we need to do this in a greedy way.
  guint tld_index = i;
  guint tld_iter = i;
  gboolean tld_found = FALSE;
  g_debug ("Looking for TLD starting from %u of %ld", i, n_tokens);
  while (tld_iter < n_tokens - 1) {
    const Token *t = &tokens[tld_iter];

    if (t->type == TOK_WHITESPACE) {
      if (!tld_found) {
        return FALSE;
      }
    }

    if (!(t->type == TOK_NUMBER ||
          t->type == TOK_TEXT ||
          t->type == TOK_DOT ||
          t->type == TOK_DASH)) {
      if (!tld_found) {
        return FALSE;
      } else {
        break;
      }
    }

    if (t->type == TOK_DOT &&
        token_is_tld (&tokens[tld_iter + 1], has_protocol)) {
      tld_index = tld_iter;
      tld_found = TRUE;
      g_debug ("TLD found at %u", tld_iter);
    }

    tld_iter ++;
  }
  g_debug ("tld_index: %u", tld_index);

  if (tld_index >= n_tokens - 1 ||
      !tld_found ||
      token_in (&tokens[tld_index - 1], INVALID_URL_CHARS)) {
    return FALSE;
  }

  // tld_index is the TOK_DOT
  g_assert (tokens[tld_index].type == TOK_DOT);
  i = tld_index + 1;

  // If the next token is a colon, we are reading a port
  if (i < n_tokens - 1 && tokens[i + 1].type == TOK_COLON) {
    i ++; // i == COLON
    if (tokens[i + 1].type != TOK_NUMBER) {
      // According to twitter.com, the link reaches until before the COLON
      i --;
    } else {
      // Skip port number
      i ++;
    }
  }

  g_debug ("After reading a port: %u", i);

  // To continue a link, the next token must be a slash or a question mark
  // If it isn't, we stop here.
  if (i < n_tokens - 1) {
    // A trailing slash is part of the link, other punctuation is not.
    if (tokens[i + 1].type == TOK_SLASH ||
        tokens[i + 1].type == TOK_QUESTIONMARK) {
      i ++;

      if (i < n_tokens - 1) {
        if (!parse_link_tail (entities, tokens, n_tokens, &i)) {
          return FALSE;
        }
      } else if (tokens[i].type == TOK_QUESTIONMARK) {
        // Trailing questionmark is not part of the link
        i --;
      }
    } else if (tokens[i + 1].type == TOK_AT) {
      // We cannot just return FALSE for all non-slash/non-questionmark tokens here since
      // The Rules say some of them make a link until this token and some of them cause the
      // entire parsing to produce no link at all, like in the @ case (don't want to turn
      // email addresses into links).
      return FALSE;
    }
  }

  g_debug ("end_token = i = %u", i);
  end_token = i;
  g_assert (end_token < n_tokens);

  emplace_entity_for_tokens (entities,
                             tokens,
                             TL_ENT_LINK,
                             start_token,
                             end_token);

  *current_position = end_token + 1; // Hop to the next token!

  return TRUE;
}

static gboolean
parse_mention (GArray      *entities,
               const Token *tokens,
               gsize        n_tokens,
               guint       *current_position)
{
  guint i = *current_position;
  const guint start_token = i;
  guint end_token;

  g_assert (tokens[i].type == TOK_AT);

  // Lookback at the previous token. If it was a text token
  // without whitespace between, this is not going to be a mention...
  if (i > 0) {
    // Text tokens before an @-token generally destroy the mention,
    // except in a few cases...
    if (tokens[i - 1].type == TOK_TEXT &&
        !token_in (&tokens[i - 1], VALID_BEFORE_MENTION_CHARS) &&
        !token_ends_in_accented (&tokens[i - 1])) {
      return FALSE;
    }

    // Numbers and special invalid chars always ruin the mention
    if (tokens[i - 1].type == TOK_NUMBER ||
        token_in (&tokens[i - 1], INVALID_BEFORE_MENTION_CHARS)) {
      return FALSE;
    }
  }

  // Skip @
  i ++;

  for (;;) {
    if (i >= n_tokens) {
      i --;
      break;
    }

    if (token_in (&tokens[i], INVALID_MENTION_CHARS)) {
      i --;
      break;
    }

    if (tokens[i].type != TOK_TEXT &&
        tokens[i].type != TOK_NUMBER &&
        tokens[i].type != TOK_UNDERSCORE) {
      i --;
      break;
    }

    if (tokens[i].type == TOK_TEXT) {
      const char *text = tokens[i].start;
      // Special rules apply about what characters may appear in a @screen_name
      const char *p = text;

      while (p - text < (long)tokens[i].length_in_bytes) {
        gunichar c = g_utf8_get_char (p);

        if (!is_valid_mention_char (c)) {
          return FALSE;
        }

        p = g_utf8_next_char (p);
      }

    }

    i ++;
  }

  if (i == start_token) {
    return FALSE;
  }

  // Mentions ending in an '@' are no mentions, e.g. @_@
  if (i < n_tokens - 1 &&
      tokens[i + 1].type == TOK_AT) {
    return FALSE;
  }

  end_token = i;
  g_assert (end_token < n_tokens);

  emplace_entity_for_tokens (entities,
                             tokens,
                             TL_ENT_MENTION,
                             start_token,
                             end_token);

  *current_position = end_token + 1; // Hop to the next token!

  return TRUE;
}

static gboolean
parse_hashtag (GArray      *entities,
               const Token *tokens,
               gsize        n_tokens,
               guint       *current_position)
{
  gsize i = *current_position;
  const guint start_token = i;
  guint end_token;
  gboolean text_found = FALSE;

  g_assert (tokens[i].type == TOK_HASH);

  // Lookback at the previous token. If it was a text token
  // without whitespace between, this is not going to be a mention...
  if (i > 0 && tokens[i - 1].type == TOK_TEXT &&
      !token_in (&tokens[i - 1], VALID_BEFORE_HASHTAG_CHARS)) {
    return FALSE;
  }

  // Some chars make the entire hashtag invalid
  if (i > 0 && token_in (&tokens[i - 1], INVALID_BEFORE_HASHTAG_CHARS)) {
    return FALSE;
  }

  //skip #
  i ++;

  for (; i < n_tokens; i ++) {
    if (token_in (&tokens[i], INVALID_HASHTAG_CHARS)) {
      break;
    }

    if (tokens[i].type != TOK_TEXT &&
        tokens[i].type != TOK_NUMBER &&
        tokens[i].type != TOK_UNDERSCORE) {
      break;
    }

    text_found |= tokens[i].type == TOK_TEXT;
  }

  if (!text_found) {
    return FALSE;
  }

  end_token = i - 1;
  g_assert (end_token < n_tokens);

  emplace_entity_for_tokens (entities,
                             tokens,
                             TL_ENT_HASHTAG,
                             start_token,
                             end_token);

  *current_position = end_token + 1; // Hop to the next token!

  return TRUE;
}

/*
 * parse:
 *
 * Returns: (transfer full): list of tokens
 */
static GArray *
parse (const Token *tokens,
       gsize        n_tokens,
       gboolean     extract_text_entities,
       guint       *n_relevant_entities)
{
  GArray *entities = g_array_new (FALSE, TRUE, sizeof (TlEntity));
  guint i = 0;
  guint relevant_entities = 0;

  while (i < n_tokens) {
    const Token *token = &tokens[i];

    // We always have to do this since links can begin with whatever word
    if (parse_link (entities, tokens, n_tokens, &i)) {
      relevant_entities ++;
      continue;
    }

    switch (token->type) {
      case TOK_AT:
        if (parse_mention (entities, tokens, n_tokens, &i)) {
          relevant_entities ++;
          continue;
        }
      break;

      case TOK_HASH:
        if (parse_hashtag (entities, tokens, n_tokens, &i)) {
          relevant_entities ++;
          continue;
        }
      break;
    }

    if (extract_text_entities &&
        token->type == TOK_TEXT) {
      relevant_entities ++;
    }

    emplace_entity_for_tokens (entities,
                               tokens,
                               token->type == TOK_TEXT ? TL_ENT_TEXT : TL_ENT_WHITESPACE,
                               i, i);

    i ++;
  }

  if (n_relevant_entities) {
    *n_relevant_entities = relevant_entities;
  }

  return entities;
}

static gsize
count_entities_in_characters (GArray *entities)
{
  guint i;
  gsize sum = 0;

  for (i = 0; i < entities->len; i ++) {
    const TlEntity *e = &g_array_index (entities, TlEntity, i);

    sum += entity_length_in_characters (e);
  }

  return sum;
}

/*
 * tl_count_chars:
 * input: (nullable): NUL-terminated tweet text
 *
 * Returns: The length of @input, in characters.
 */
gsize
tl_count_characters (const char *input)
{
  if (input == NULL || input[0] == '\0') {
    return 0;
  }

  return tl_count_characters_n (input, strlen (input));
}

/*
 * tl_count_characters_n:
 * input: (nullable): Text to measure
 * length_in_bytes: Length of @input, in bytes.
 *
 * Returns: The length of @input, in characters.
 */
gsize
tl_count_characters_n (const char *input,
                       gsize       length_in_bytes)
{
  GArray *tokens;
  const Token *token_array;
  gsize n_tokens;
  GArray *entities;
  gsize length;

  if (input == NULL || input[0] == '\0') {
    return 0;
  }

  // From here on, input/length_in_bytes are trusted to be OK
  tokens = tokenize (input, length_in_bytes);

  n_tokens = tokens->len;
  token_array = (const Token *)g_array_free (tokens, FALSE);

  entities = parse (token_array, n_tokens, FALSE, NULL);

  length = count_entities_in_characters (entities);
  g_array_free (entities, TRUE);
  g_free ((char *)token_array);

  return length;
}

static inline gsize
entity_length_in_weighted_characters (const TlEntity *e)
{
  switch (e->type) {
    case TL_ENT_LINK:
      return LINK_LENGTH;

    default:
      return e->length_in_weighted_characters;
  }
}

static gsize
count_entities_in_weighted_characters (GArray *entities)
{
  guint i;
  gsize sum = 0;

  for (i = 0; i < entities->len; i ++) {
    const TlEntity *e = &g_array_index (entities, TlEntity, i);

    sum += entity_length_in_weighted_characters (e);
  }

  return sum;
}

/*
 * tl_count_weighted_chararacters:
 * input: (nullable): NUL-terminated tweet text
 *
 * Returns: The length of @input, in Twitter's weighted characters.
 */
gsize
tl_count_weighted_characters (const char *input)
{
  if (input == NULL || input[0] == '\0') {
    return 0;
  }

  return tl_count_weighted_characters_n (input, strlen (input));
}

/*
 * tl_count_weighted_characters_n:
 * input: (nullable): Text to measure
 * length_in_bytes: Length of @input, in bytes.
 *
 * Returns: The length of @input, in characters.
 */
gsize
tl_count_weighted_characters_n (const char *input,
                       gsize       length_in_bytes)
{
  GArray *tokens;
  const Token *token_array;
  gsize n_tokens;
  GArray *entities;
  gsize length;

  if (input == NULL || input[0] == '\0') {
    return 0;
  }

  // From here on, input/length_in_bytes are trusted to be OK
  tokens = tokenize (input, length_in_bytes);

  n_tokens = tokens->len;
  token_array = (const Token *)g_array_free (tokens, FALSE);

  entities = parse (token_array, n_tokens, FALSE, NULL);

  length = count_entities_in_weighted_characters (entities);
  g_array_free (entities, TRUE);
  g_free ((char *)token_array);

  return length;
}

/**
 * tl_extract_entities:
 * @input: The input text to extract entities from
 * @out_n_entities: (out): Location to store the amount of entities in the returned
 *   array. If 0, the return value is %NULL.
 * @out_text_length: (out) (optional): Return location for the complete
 *   length of @input, in characters. This is the same value one would
 *   get from calling tl_count_characters() or tl_count_characters_n()
 *   on @input.
 *
 * Returns: An array of #TlEntity. If no entities are found, %NULL is returned.
 */
TlEntity *
tl_extract_entities (const char *input,
                     gsize      *out_n_entities,
                     gsize      *out_text_length)
{
  gsize dummy;

  g_return_val_if_fail (out_n_entities != NULL, NULL);

  if (out_text_length == NULL) {
    out_text_length = &dummy;
  }

  if (input == NULL || input[0] == '\0') {
    *out_n_entities = 0;
    *out_text_length = 0;
    return NULL;
  }

  return tl_extract_entities_n (input, strlen (input), out_n_entities, out_text_length);
}


static TlEntity *
tl_extract_entities_internal (const char *input,
                              gsize       length_in_bytes,
                              gsize      *out_n_entities,
                              gsize      *out_text_length,
                              gboolean    extract_text_entities)
{
  GArray *tokens;
  const Token *token_array;
  gsize n_tokens;
  GArray *entities;
  guint n_relevant_entities;
  TlEntity *result_entities;
  guint result_index = 0;

  tokens = tokenize (input, length_in_bytes);

#ifdef LIBTL_DEBUG
  g_debug ("############ %s: %.*s", __FUNCTION__, (guint)length_in_bytes, input);
  for (guint i = 0; i < tokens->len; i ++) {
    const Token *t = &g_array_index (tokens, Token, i);
    g_debug ("Token %u: Type: %d, Length: %u, Text:%.*s, start char: %u, chars: %u", i, t->type, (guint)t->length_in_bytes,
         (int)t->length_in_bytes, t->start, (guint)t->start_character_index, (guint)t->length_in_characters);
  }
#endif

  n_tokens = tokens->len;
  token_array = (const Token *)g_array_free (tokens, FALSE);
  entities = parse (token_array, n_tokens, extract_text_entities, &n_relevant_entities);

  *out_text_length = count_entities_in_characters (entities);
  g_free ((char *)token_array);

#ifdef LIBTL_DEBUG
  for (guint i = 0; i < entities->len; i ++) {
    const TlEntity *e = &g_array_index (entities, TlEntity, i);
    g_debug ("TlEntity %u: Text: '%.*s', Type: %u, Bytes: %u, Length: %u, start character: %u", i, (int)e->length_in_bytes, e->start,
               e->type, (guint)e->length_in_bytes, (guint)entity_length_in_characters (e), (guint)e->start_character_index);
  }
#endif

  // Only pass mentions, hashtags and links out
  result_entities = g_malloc (sizeof (TlEntity) * n_relevant_entities);
  for (guint i = 0; i < entities->len; i ++) {
    const TlEntity *e = &g_array_index (entities, TlEntity, i);
    switch (e->type) {
      case TL_ENT_LINK:
      case TL_ENT_HASHTAG:
      case TL_ENT_MENTION:
        memcpy (&result_entities[result_index], e, sizeof (TlEntity));
        result_index ++;
      break;

      case TL_ENT_TEXT:
        if (extract_text_entities) {
          memcpy (&result_entities[result_index], e, sizeof (TlEntity));
          result_index ++;
        }
      break;

      default: {}
    }
  }

  *out_n_entities = n_relevant_entities;
  g_array_free (entities, TRUE);

  return result_entities;
}

/**
 * tl_extract_entities_n:
 * @input: The input text to extract entities from
 * @length_in_bytes: The length of @input, in bytes
 * @out_n_entities: (out): Location to store the amount of entities in the returned
 *   array. If 0, the return value is %NULL.
 * @out_text_length: (out) (optional): Return location for the complete
 *   length of @input, in characters. This is the same value one would
 *   get from calling tl_count_characters() or tl_count_characters_n()
 *   on @input.
 *
 * Returns: An array of #TlEntity. If no entities are found, %NULL is returned.
 */
TlEntity *
tl_extract_entities_n (const char *input,
                       gsize       length_in_bytes,
                       gsize      *out_n_entities,
                       gsize      *out_text_length)
{
  gsize dummy;

  g_return_val_if_fail (out_n_entities != NULL, NULL);

  if (out_text_length == NULL) {
    out_text_length = &dummy;
  }

  if (input == NULL || input[0] == '\0') {
    *out_n_entities = 0;
    *out_text_length = 0;
    return NULL;
  }

  return tl_extract_entities_internal (input,
                                       length_in_bytes,
                                       out_n_entities,
                                       out_text_length,
                                       FALSE);
}

/**
 * tl_extract_entities_and_text:
 * @input: The input text to extract entities from
 * @out_n_entities: (out): Location to store the amount of entities in the returned
 *   array. If 0, the return value is %NULL.
 * @out_text_length: (out) (optional): Return location for the complete
 *   length of @input, in characters. This is the same value one would
 *   get from calling tl_count_characters() or tl_count_characters_n()
 *   on @input.
 *
 * This is different from tl_extract_entities() in that it returns all entities
 * and not just hashtags, links and mentions. This allows for further post-processing
 * from the caller.
 *
 * Returns: An array of #TlEntity. If no entities are found, %NULL is returned.
 */
TlEntity *
tl_extract_entities_and_text (const char *input,
                              gsize      *out_n_entities,
                              gsize      *out_text_length)
{
  gsize dummy;

  g_return_val_if_fail (out_n_entities != NULL, NULL);

  if (out_text_length == NULL) {
    out_text_length = &dummy;
  }

  if (input == NULL || input[0] == '\0') {
    *out_n_entities = 0;
    *out_text_length = 0;
    return NULL;
  }

  return tl_extract_entities_internal (input,
                                       strlen (input),
                                       out_n_entities,
                                       out_text_length,
                                       TRUE);
}

/**
 * tl_extract_entities_and_text_n:
 * @input: The input text to extract entities from
 * @length_in_bytes: The length of @input, in bytes
 * @out_n_entities: (out): Location to store the amount of entities in the returned
 *   array. If 0, the return value is %NULL.
 * @out_text_length: (out) (optional): Return location for the complete
 *   length of @input, in characters. This is the same value one would
 *   get from calling tl_count_characters() or tl_count_characters_n()
 *   on @input.
 *
 * This is different from tl_extract_entities_n() in that it returns all entities
 * and not just hashtags, links and mentions. This allows for further post-processing
 * from the caller.
 *
 * Returns: An array of #TlEntity. If no entities are found, %NULL is returned.
 */
TlEntity *
tl_extract_entities_and_text_n (const char *input,
                                gsize       length_in_bytes,
                                gsize      *out_n_entities,
                                gsize      *out_text_length)
{
  gsize dummy;

  g_return_val_if_fail (out_n_entities != NULL, NULL);

  if (out_text_length == NULL) {
    out_text_length = &dummy;
  }

  if (input == NULL || input[0] == '\0') {
    *out_n_entities = 0;
    *out_text_length = 0;
    return NULL;
  }

  return tl_extract_entities_internal (input,
                                       length_in_bytes,
                                       out_n_entities,
                                       out_text_length,
                                       TRUE);
}
