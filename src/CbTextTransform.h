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

#ifndef __TEXT_TRANSFORM_H
#define __TEXT_TRANSFORM_H

#include <glib-object.h>
#include "CbTypes.h"

typedef enum {
  CB_TEXT_TRANSFORM_REMOVE_MEDIA_LINKS       = 1 << 0,
  CB_TEXT_TRANSFORM_REMOVE_TRAILING_HASHTAGS = 1 << 1,
  CB_TEXT_TRANSFORM_EXPAND_LINKS             = 1 << 2
} CbTransformFlags;



char *cb_text_transform_tweet (const CbMiniTweet *tweet,
                               guint              flags,
                               guint64            quote_id);


char *cb_text_transform_text  (const char         *text,
                               const CbTextEntity *entities,
                               gsize               n_entities,
                               guint               flags,
                               gsize               n_medias,
                               gint64              quote_id,
                               guint               display_range_start);

#endif
