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

#ifndef __CB_TWEET_LIST_BOX_H__
#define __CB_TWEET_LIST_BOX_H__

#include <gtk/gtk.h>
#include "CbDeltaUpdater.h"
#include "CbTweetModel.h"

typedef struct _CbTweetListBox CbTweetListBox;
struct _CbTweetListBox
{
  GtkListBox parent_instance;

  CbTweetModel *model;
  CbDeltaUpdater *delta_updater;
  GtkGesture *multipress_gesture;
  GtkWidget *placeholder;
  GtkWidget *error_label;
  GtkWidget *no_entries_label;

  GtkWidget *action_entry;
};

#define CB_TYPE_TWEET_LIST_BOX cb_tweet_list_box_get_type ()
G_DECLARE_FINAL_TYPE (CbTweetListBox, cb_tweet_list_box, CB, TWEET_LIST_BOX, GtkListBox);

GtkWidget * cb_tweet_list_box_new                    (void);
void        cb_tweet_list_box_set_empty              (CbTweetListBox *self);
void        cb_tweet_list_box_set_unempty            (CbTweetListBox *self);
void        cb_tweet_list_box_set_error              (CbTweetListBox *self,
                                                      const char     *error_message);
void        cb_tweet_list_box_set_placeholder_text   (CbTweetListBox *self,
                                                      const char     *placeholder_text);
void        cb_tweet_list_box_reset_placeholder_text (CbTweetListBox *self);
GtkWidget * cb_tweet_list_box_get_first_visible_row  (CbTweetListBox *self);
GtkWidget * cb_tweet_list_box_get_placeholder        (CbTweetListBox *self);
void        cb_tweet_list_box_remove_all             (CbTweetListBox *self);




#endif
