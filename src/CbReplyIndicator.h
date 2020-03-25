/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2018 Timm Bäder
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

#ifndef __CB_REPLY_INDICATOR_H__
#define __CB_REPLY_INDICATOR_H__

#include <gtk/gtk.h>

typedef struct _CbReplyIndicator      CbReplyIndicator;
struct _CbReplyIndicator
{
  GtkWidget parent_instance;

  GtkWidget *revealer;
  GtkWidget *button;
};

#define CB_TYPE_REPLY_INDICATOR cb_reply_indicator_get_type ()
G_DECLARE_FINAL_TYPE (CbReplyIndicator, cb_reply_indicator, CB, REPLY_INDICATOR, GtkWidget);

void      cb_reply_indicator_set_replies_available (CbReplyIndicator *self,
                                                    gboolean          replies_available);
gboolean  cb_reply_indicator_get_replies_available (CbReplyIndicator *self);

#endif
