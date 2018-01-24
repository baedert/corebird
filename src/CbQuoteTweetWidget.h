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

#ifndef __CB_QUOTE_TWEET_WIDGET_H__
#define __CB_QUOTE_TWEET_WIDGET_H__

#include <gtk/gtk.h>
#include "CbTypes.h"

struct _CbQuoteTweetWidget
{
  GtkWidget parent_instance;

  GtkWidget *top_row_box;
  GtkWidget *name_button;
  GtkWidget *screen_name_label;
  GtkWidget *time_delta_label;
  GtkWidget *text_label;

  gint64 user_id;
  char *screen_name;
  gint64 tweet_created_at;
};
typedef struct _CbQuoteTweetWidget CbQuoteTweetWidget;

#define CB_TYPE_QUOTE_TWEET_WIDGET cb_quote_tweet_widget_get_type ()
G_DECLARE_FINAL_TYPE (CbQuoteTweetWidget, cb_quote_tweet_widget, CB, QUOTE_TWEET_WIDGET, GtkWidget);

GtkWidget * cb_quote_tweet_widget_new         (void);
void        cb_quote_tweet_widget_set_tweet   (CbQuoteTweetWidget *self,
                                               const CbMiniTweet  *quote);
void        cb_quote_tweet_widget_update_time (CbQuoteTweetWidget *self,
                                               GDateTime          *now);

#endif
