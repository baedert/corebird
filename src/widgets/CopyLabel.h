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
#include <gtk/gtk.h>
#include "../CbTweet.h"


struct _CbCopyLabel
{
  GtkLabel  parent_instance;
  CbTweet  *tweet;
};

typedef struct _CbCopyLabel CbCopyLabel;

#define CB_TYPE_COPY_LABEL cb_copy_label_get_type ()
G_DECLARE_FINAL_TYPE (CbCopyLabel, cb_copy_label, CB, COPY_LABEL, GtkLabel);

CbCopyLabel *cb_copy_label_new       (void);
void         cb_copy_label_set_tweet (CbCopyLabel *label,
                                      CbTweet     *tweet);
