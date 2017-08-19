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

#ifndef FILTER_H
#define FILTER_H

#include <glib-object.h>

G_BEGIN_DECLS

typedef struct _CbFilter      CbFilter;
struct _CbFilter
{
  GObject parent_instance;

  int     id;
  char   *contents;
  GRegex *regex;
};

#define CB_TYPE_FILTER cb_filter_get_type ()
G_DECLARE_FINAL_TYPE (CbFilter, cb_filter, CB, FILTER, GObject);


GType       cb_filter_get_type     (void) G_GNUC_CONST;
CbFilter   *cb_filter_new          (const char *expr);
void        cb_filter_reset        (CbFilter *filter, const char *expr);
gboolean    cb_filter_matches      (CbFilter *filter, const char *text);
const char *cb_filter_get_contents (CbFilter *filter);
int         cb_filter_get_id       (CbFilter *filter);
void        cb_filter_set_id       (CbFilter *filter, int id);

G_END_DECLS

#endif
