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

#ifndef __UTILS_H
#define __UTILS_H

#include <gtk/gtk.h>
#include <glib-object.h>
#include "CbTypes.h"

void cb_utils_bind_model (GtkWidget                  *listbox,
                          GListModel                 *model,
                          GtkListBoxCreateWidgetFunc  func,
                          void                       *data);

void cb_utils_linkify_user (const CbUserIdentity *user,
                            GString              *str);

void cb_utils_write_reply_text (const CbMiniTweet *t,
                                GString           *str);

char * cb_utils_escape_quotes (const char *in);
char * cb_utils_escape_ampersands (const char *in);

GDateTime * cb_utils_parse_date (const char *_in);


#endif
