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

#ifndef _CB_SETTINGS_DIALOG_H_
#define _CB_SETTINGS_DIALOG_H_

#include <gtk/gtk.h>

struct _CbSettingsDialog
{
  GtkApplicationWindow parent_instance;

  GCancellable *account_data_cancellable;

  GtkWidget *main_box;
  GtkWidget *sidebar_revealer;
  GtkWidget *sidebar;
  GtkWidget *stack;
  GtkWidget *titlebar;

  /* Accounts */
  GtkWidget *accounts_page;
  GtkWidget *accounts_create_button;
  GtkWidget *accounts_listbox;

  /* Interface */
  GtkWidget *interface_page;
  GtkWidget *interface_show_inline_media_combobox;
  GtkWidget *interface_auto_scroll_switch;
  GtkWidget *interface_double_click_switch;

  /* Notifications */
  GtkWidget *notifications_page;
  GtkWidget *notifications_on_new_tweets_combobox;
  GtkWidget *notifications_on_new_mentions_switch;
  GtkWidget *notifications_on_new_messages_switch;

  /* Tweets */
  GtkWidget *tweets_page;
  GtkWidget *tweets_round_avatars_switch;
  GtkWidget *tweets_trailing_hashtags_switch;
  GtkWidget *tweets_media_links_switch;
  GtkWidget *tweets_nsfw_content_switch;

  /* Snippets */
  GtkWidget *snippets_page;
  GtkWidget *snippets_listbox;
  GtkWidget *snippets_add_button;
};

typedef struct _CbSettingsDialog CbSettingsDialog;

#define CB_TYPE_SETTINGS_DIALOG cb_settings_dialog_get_type ()
G_DECLARE_FINAL_TYPE (CbSettingsDialog, cb_settings_dialog, CB, SETTINGS_DIALOG, GtkApplicationWindow);


GtkWidget * cb_settings_dialog_new (GtkApplication *app);


#endif
