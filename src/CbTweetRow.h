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

#ifndef __CB_TWEET_ROW_H__
#define __CB_TWEET_ROW_H__

#include <gtk/gtk.h>
#include "CbTweet.h"

struct _CbTweetRow
{
  GtkListBoxRow parent_instance;

  CbTweet *tweet;
  void    *main_window; // TODO: Make this an actual typed pointer

  GtkWidget *stack;
  GtkWidget *avatar_widget;
  GtkWidget *name_button;
  GtkWidget *screen_name_label;
  GtkWidget *time_delta_label;
  GtkWidget *text_label;
  GtkWidget *top_row_box;

  /* Only conditionally created widgets */
  GtkWidget *rt_image;
  GtkWidget *rt_label;
  GtkWidget *reply_label;
  GtkWidget *mm_widget;
};
typedef struct _CbTweetRow CbTweetRow;


#define CB_TYPE_TWEET_ROW cb_tweet_row_get_type ()
G_DECLARE_FINAL_TYPE (CbTweetRow, cb_tweet_row, CB, TWEET_ROW, GtkListBoxRow);

GtkWidget *  cb_tweet_row_new               (CbTweet    *tweet,
                                             void       *main_window);
void         cb_tweet_row_update_time_delta (CbTweetRow *self,
                                             GDateTime  *now);
#endif
