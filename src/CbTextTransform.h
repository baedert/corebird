
#ifndef __TEXT_TRANSFORM_H
#define __TEXT_TRANSFORM_H

#include <glib-object.h>
#include "Types.h"

typedef enum {
  CB_TEXT_TRANSFORM_REMOVE_MEDIA_LINKS       = 1 << 0,
  CB_TEXT_TRANSFORM_REMOVE_TRAILING_HASHTAGS = 1 << 1,
  CB_TEXT_TRANSFORM_EXPAND_LINKS             = 1 << 2
} CbTransformFlags;



char *cb_text_transform_tweet (const CbMiniTweet *tweet,
                               guint              flags,
                               guint64            quote_id);


char *cb_text_transform_text  (const char   *text,
                               CbTextEntity *entities,
                               gsize         n_entities,
                               guint         flags,
                               gsize         n_medias,
                               gint64        quote_id);

#endif
