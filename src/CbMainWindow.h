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

#ifndef __CB_MAIN_WINDOW_H__
#define __CB_MAIN_WINDOW_H__

#include <gtk/gtk.h>

typedef struct _CbMainWindow CbMainWindow;
struct _CbMainWindow
{
  GtkApplicationWindow parent_instance;

  GtkWidget *headerbar;
  GtkWidget *main_widget;
  GtkWidget *title_stack;
  GtkWidget *title_label;
  GtkWidget *last_page_label;
  GtkWidget *account_button;
  GtkWidget *avatar_widget;
  GtkWidget *compose_tweet_button;
  GtkWidget *back_button;
  GtkWidget *accounts_popover;
  GtkWidget *accounts_list;
  GtkWidget *header_box; /* Box in the upper left, showing those 3 buttons. */
  GtkWidget *app_menu_button;

  GtkWidget *compose_window;

  GtkGesture *thumb_button_gesture;

  void *account; /* XXX should be Account instance */
};

#define CB_TYPE_MAIN_WINDOW (cb_main_window_get_type ())
G_DECLARE_FINAL_TYPE (CbMainWindow, cb_main_window, CB, MAIN_WINDOW, GtkApplicationWindow);

GtkWidget *       cb_main_window_new                (void                   *account);
void              cb_main_window_change_account     (CbMainWindow           *self,
                                                     void                   *account);
void              cb_main_window_set_window_title   (CbMainWindow           *self,
                                                     const char             *title,
                                                     GtkStackTransitionType  transition_type);
void              cb_main_window_rerun_filters      (CbMainWindow           *self);
void              cb_main_window_save_geometry      (CbMainWindow           *self);
void              cb_main_window_reply_to_tweet     (CbMainWindow           *self,
                                                     gint64                  tweet_id);
void              cb_main_window_mark_tweet_as_read (CbMainWindow           *self,
                                                     gint64                  tweet_id);
int               cb_main_window_get_cur_page_id    (CbMainWindow           *self);
void *            cb_main_window_get_page           (CbMainWindow           *self,
                                                     int                     page_id);


#endif
