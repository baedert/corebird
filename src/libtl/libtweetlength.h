#ifndef __LIBTWEETLENGTH_H__
#define __LIBTWEETLENGTH_H__

#include <glib.h>

struct _TlEntity {
  guint type;
  const char *start;
  gsize length_in_bytes;

  gsize start_character_index;
  gsize length_in_characters;
};
typedef struct _TlEntity TlEntity;

typedef enum {
  TL_ENT_TEXT = 1,
  TL_ENT_HASHTAG,
  TL_ENT_LINK,
  TL_ENT_MENTION,
  TL_ENT_WHITESPACE,
} TlEntityType;

gsize      tl_count_characters   (const char *input);
gsize      tl_count_characters_n (const char *input,
                                  gsize       length_in_bytes);
TlEntity * tl_extract_entities   (const char *input,
                                  gsize      *out_n_entities,
                                  gsize      *out_text_length);
TlEntity * tl_extract_entities_n (const char *input,
                                  gsize       length_in_bytes,
                                  gsize      *out_n_entities,
                                  gsize      *out_text_length);

#endif
