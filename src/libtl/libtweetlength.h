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

#ifndef __LIBTWEETLENGTH_H__
#define __LIBTWEETLENGTH_H__

#include <glib.h>

struct _TlEntity {
  guint type;
  const char *start;
  gsize length_in_bytes;

  gsize start_character_index;
  gsize length_in_characters;
  gsize length_in_weighted_characters;
};
typedef struct _TlEntity TlEntity;

typedef enum {
  TL_ENT_TEXT       = 1,
  TL_ENT_HASHTAG    = 2,
  TL_ENT_LINK       = 3,
  TL_ENT_MENTION    = 4,
  TL_ENT_WHITESPACE = 5,
} TlEntityType;

gsize      tl_count_characters            (const char *input);
gsize      tl_count_characters_n          (const char *input,
                                           gsize       length_in_bytes);
gsize      tl_count_weighted_characters   (const char *input);
gsize      tl_count_weighted_characters_n (const char *input,
                                           gsize       length_in_bytes);
TlEntity * tl_extract_entities            (const char *input,
                                           gsize      *out_n_entities,
                                           gsize      *out_text_length);
TlEntity * tl_extract_entities_n          (const char *input,
                                           gsize       length_in_bytes,
                                           gsize      *out_n_entities,
                                           gsize      *out_text_length);
TlEntity * tl_extract_entities_and_text   (const char *input,
                                           gsize      *out_n_entities,
                                           gsize      *out_text_length);
TlEntity * tl_extract_entities_and_text_n (const char *input,
                                           gsize       length_in_bytes,
                                           gsize      *out_n_entities,
                                           gsize      *out_text_length);



#endif
