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

#include "CbSettingsDialog2.h"
#include "CbSettingsAccountRow.h"
#include "corebird.h"
#include <glib/gi18n.h>

G_DEFINE_TYPE (CbSettingsDialog, cb_settings_dialog, GTK_TYPE_APPLICATION_WINDOW);

static void
create_account_button_clicked_cb (GtkButton *source,
                                  gpointer   user_data)
{
  GtkWidget *window = (GtkWidget *)main_window_new (GTK_APPLICATION (g_application_get_default ()),
                                                    NULL);
  // TODO: Add window to application
  gtk_widget_show_all (window);
}

static void
populate_accounts_list (CbSettingsDialog *self)
{
  guint n_accounts = account_get_n ();
  guint i;

  // TODO: Listen for changes in the accounts (account added, etc.)

  for (i = 0; i < n_accounts; i ++)
    {
      Account *acc = account_get_nth (i);
      GtkWidget *row = cb_settings_account_row_new (acc);

      cb_settings_account_row_set_banner (CB_SETTINGS_ACCOUNT_ROW (row),
                                          gdk_cairo_surface_create_from_pixbuf (twitter_no_banner,
                                                                                1, NULL));

      gtk_widget_show_all (row);
      gtk_container_add (GTK_CONTAINER (self->accounts_listbox), row);
    }
}

static void
cb_settings_dialog_load_geometry (CbSettingsDialog *self)
{
  GVariant *geom = g_settings_get_value (settings_get (), "settings-geometry");
  int x = g_variant_get_int32 (g_variant_get_child_value (geom, 0));
  int y = g_variant_get_int32 (g_variant_get_child_value (geom, 1));
  int w = g_variant_get_int32 (g_variant_get_child_value (geom, 2));
  int h = g_variant_get_int32 (g_variant_get_child_value (geom, 3));

  if (w == 0 || h == 0)
    return;

  gtk_window_move (GTK_WINDOW (self), x, y);
  gtk_window_set_default_size (GTK_WINDOW (self), w, h);

  // TODO: Memory
}

static void
cb_settings_dialog_save_geometry (CbSettingsDialog *self)
{
  GVariantBuilder *builder = g_variant_builder_new (G_VARIANT_TYPE_TUPLE);
  int x, y, w, h;

  gtk_window_get_position (GTK_WINDOW (self), &x, &y);
  gtk_window_get_size (GTK_WINDOW (self), &w, &h);

  g_variant_builder_add_value (builder, g_variant_new_int32 (x));
  g_variant_builder_add_value (builder, g_variant_new_int32 (y));
  g_variant_builder_add_value (builder, g_variant_new_int32 (w));
  g_variant_builder_add_value (builder, g_variant_new_int32 (h));

  g_settings_set_value (settings_get (), "settings-geometry", g_variant_builder_end (builder));

  // TODO: Memory
}

static gboolean
cb_settings_dialog_delete_cb (GtkWidget *widget,
                              gpointer   user_data)
{
  cb_settings_dialog_save_geometry (CB_SETTINGS_DIALOG (widget));

  return GDK_EVENT_PROPAGATE;
}

static void
cb_settings_dialog_class_init (CbSettingsDialogClass *klass)
{
}

static void
cb_settings_dialog_init (CbSettingsDialog *self)
{
  GtkWidget *w;
  GtkWidget *box;
  Account *fake_account;
  CbTweet *fake_tweet;

  g_signal_connect (self, "delete-event", G_CALLBACK (cb_settings_dialog_delete_cb), NULL);

  self->account_data_cancellable = g_cancellable_new ();
  self->main_box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 0);
  self->sidebar = gtk_stack_sidebar_new ();
  self->sidebar_revealer = gtk_revealer_new ();
  self->stack = gtk_stack_new ();
  self->titlebar = gtk_header_bar_new ();

  gtk_header_bar_set_show_close_button (GTK_HEADER_BAR (self->titlebar), TRUE);
  gtk_window_set_titlebar (GTK_WINDOW (self), self->titlebar);

  gtk_stack_sidebar_set_stack (GTK_STACK_SIDEBAR (self->sidebar), GTK_STACK (self->stack));

  gtk_revealer_set_reveal_child (GTK_REVEALER (self->sidebar_revealer), TRUE);
  gtk_revealer_set_transition_type (GTK_REVEALER (self->sidebar_revealer),
                                    GTK_REVEALER_TRANSITION_TYPE_SLIDE_RIGHT);

  gtk_container_add (GTK_CONTAINER (self->sidebar_revealer), self->sidebar);
  gtk_container_add (GTK_CONTAINER (self->main_box), self->sidebar_revealer);
  gtk_widget_set_vexpand (self->stack, TRUE);
  gtk_container_add (GTK_CONTAINER (self->main_box), self->stack);

  gtk_container_add (GTK_CONTAINER (self), self->main_box);

  /* Accounts Page */
  self->accounts_page = gtk_scrolled_window_new (NULL, NULL);
  self->accounts_create_button = gtk_button_new_with_label (_("Add new Account"));
  self->accounts_listbox = gtk_list_box_new ();

  populate_accounts_list (self);

  gtk_widget_set_size_request (self->accounts_listbox, -1, 100);
  gtk_list_box_set_selection_mode (GTK_LIST_BOX (self->accounts_listbox), GTK_SELECTION_NONE);
  w = gtk_label_new (_("No Accounts"));
  gtk_style_context_add_class (gtk_widget_get_style_context (w), "dim-label");
  gtk_widget_show (w);
  gtk_list_box_set_placeholder (GTK_LIST_BOX (self->accounts_listbox), w);

  box = gtk_box_new (GTK_ORIENTATION_VERTICAL, 0);
  g_object_set (G_OBJECT (box), "margin", 24, NULL);
  gtk_widget_set_valign (box, GTK_ALIGN_START);

  w = gtk_frame_new (NULL);
  gtk_widget_set_margin_top (w, 12);
  gtk_container_add (GTK_CONTAINER (w), self->accounts_listbox);
  g_signal_connect (self->accounts_create_button, "clicked", G_CALLBACK (create_account_button_clicked_cb), self);
  gtk_container_add (GTK_CONTAINER (box), self->accounts_create_button);
  gtk_container_add (GTK_CONTAINER (box), w);
  gtk_container_add (GTK_CONTAINER (self->accounts_page), box);

  gtk_stack_add_titled (GTK_STACK (self->stack), self->accounts_page, "accounts", _("Accounts"));

  /* Interface Page */
  self->interface_page = gtk_grid_new ();
  self->interface_show_inline_media_combobox = gtk_combo_box_text_new ();
  self->interface_auto_scroll_switch = gtk_switch_new ();
  self->interface_double_click_switch = gtk_switch_new ();

  w = gtk_label_new (_("Show inline media"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->interface_page), w, 0, 0, 1, 1);
  gtk_widget_set_halign (self->interface_show_inline_media_combobox, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->interface_page), self->interface_show_inline_media_combobox, 1, 0, 1, 1);

  w = gtk_label_new (_("Auto scroll on new tweets"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->interface_page), w, 0, 1, 1, 1);
  gtk_widget_set_halign (self->interface_auto_scroll_switch, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->interface_page), self->interface_auto_scroll_switch, 1, 1, 1, 1);

  w = gtk_label_new (_("Double Click Activation"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->interface_page), w, 0, 2, 1, 1);
  gtk_widget_set_halign (self->interface_double_click_switch, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->interface_page), self->interface_double_click_switch, 1, 2, 1, 1);

  g_object_set (G_OBJECT (self->interface_page), "margin", 12, NULL);
  gtk_grid_set_column_spacing (GTK_GRID (self->interface_page), 12);
  gtk_grid_set_row_spacing (GTK_GRID (self->interface_page), 12);
  gtk_grid_set_column_homogeneous (GTK_GRID (self->interface_page), TRUE);
  gtk_widget_set_hexpand (self->interface_page, TRUE);
  gtk_stack_add_titled (GTK_STACK (self->stack), self->interface_page, "interface", _("Interface"));

  /* Notifications Page */
  self->notifications_page = gtk_grid_new ();
  self->notifications_on_new_tweets_combobox = gtk_combo_box_text_new ();
  self->notifications_on_new_mentions_switch = gtk_switch_new ();
  self->notifications_on_new_messages_switch = gtk_switch_new ();

  w = gtk_label_new (_("On New Tweets"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->notifications_page), w, 0, 0, 1, 1);
  gtk_widget_set_halign (self->notifications_on_new_tweets_combobox, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->notifications_page), self->notifications_on_new_tweets_combobox, 1, 0, 1, 1);

  w = gtk_label_new (_("On New Mentions"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->notifications_page), w, 0, 1, 1, 1);
  gtk_widget_set_halign (self->notifications_on_new_mentions_switch, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->notifications_page), self->notifications_on_new_mentions_switch, 1, 1, 1, 1);

  w = gtk_label_new (_("On New Messages"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->notifications_page), w, 0, 2, 1, 1);
  gtk_widget_set_halign (self->notifications_on_new_messages_switch, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->notifications_page), self->notifications_on_new_messages_switch, 1, 2, 1, 1);

  g_object_set (G_OBJECT (self->notifications_page), "margin", 12, NULL);
  gtk_grid_set_column_spacing (GTK_GRID (self->notifications_page), 12);
  gtk_grid_set_row_spacing (GTK_GRID (self->notifications_page), 12);
  gtk_grid_set_column_homogeneous (GTK_GRID (self->notifications_page), TRUE);
  gtk_widget_set_hexpand (self->notifications_page, TRUE);
  gtk_stack_add_titled (GTK_STACK (self->stack), self->notifications_page, "notifications", _("Notifications"));

  /* Tweets Page */
  self->tweets_page = gtk_grid_new ();
  self->tweets_round_avatars_switch = gtk_switch_new ();
  self->tweets_trailing_hashtags_switch = gtk_switch_new ();
  self->tweets_media_links_switch = gtk_switch_new ();
  self->tweets_nsfw_content_switch = gtk_switch_new ();

  const char *sample_text = _("Hey, check out this new #Corebird version! \\ (•◡•) / #cool #newisalwaysbetter");
  fake_account = account_new (10, "corebirdclient", "Corebird");
  fake_tweet = cb_tweet_new ();
  fake_tweet->source_tweet.author.id = 10;
  fake_tweet->source_tweet.author.screen_name = g_strdup ("corebirdclient");
  fake_tweet->source_tweet.author.user_name = g_strdup ("Corebird");
  fake_tweet->source_tweet.text = g_strdup (sample_text);
  // TODO: hashtag regex
  w = (GtkWidget *)tweet_list_entry_new (fake_tweet, NULL, fake_account, FALSE);
  tweet_list_entry_set_read_only (TWEET_LIST_ENTRY (w), TRUE);
  box = gtk_list_box_new ();
  gtk_list_box_set_selection_mode (GTK_LIST_BOX (box), GTK_SELECTION_NONE);
  gtk_list_box_row_set_activatable (GTK_LIST_BOX_ROW (w), FALSE);
  gtk_container_add (GTK_CONTAINER (box), w);
  gtk_grid_attach (GTK_GRID (self->tweets_page), box, 0, 0, 2, 1);

  w = gtk_label_new (_("Round Avatars"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->tweets_page), w, 0, 1, 1, 1);
  gtk_widget_set_halign (self->tweets_round_avatars_switch, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->tweets_page), self->tweets_round_avatars_switch, 1, 1, 1, 1);

  w = gtk_label_new (_("Remove trailing hashtags"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->tweets_page), w, 0, 2, 1, 1);
  gtk_widget_set_halign (self->tweets_trailing_hashtags_switch, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->tweets_page), self->tweets_trailing_hashtags_switch, 1, 2, 1, 1);

  w = gtk_label_new (_("Remove media links"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->tweets_page), w, 0, 3, 1, 1);
  gtk_widget_set_halign (self->tweets_media_links_switch, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->tweets_page), self->tweets_media_links_switch, 1, 3, 1, 1);

  w = gtk_label_new (_("Hide inappropriate content"));
  gtk_widget_set_halign (w, GTK_ALIGN_END);
  gtk_grid_attach (GTK_GRID (self->tweets_page), w, 0, 4, 1, 1);
  gtk_widget_set_halign (self->tweets_nsfw_content_switch, GTK_ALIGN_START);
  gtk_grid_attach (GTK_GRID (self->tweets_page), self->tweets_nsfw_content_switch, 1, 4, 1, 1);

  gtk_widget_set_margin_bottom (self->tweets_page, 12);
  gtk_grid_set_column_spacing (GTK_GRID (self->tweets_page), 12);
  gtk_grid_set_row_spacing (GTK_GRID (self->tweets_page), 12);
  gtk_grid_set_column_homogeneous (GTK_GRID (self->tweets_page), TRUE);
  gtk_widget_set_hexpand (self->tweets_page, TRUE);
  gtk_stack_add_titled (GTK_STACK (self->stack), self->tweets_page, "tweets", _("Tweets"));

  /* Snippets Page */
  self->snippets_page = gtk_box_new (GTK_ORIENTATION_VERTICAL, 0);
  self->snippets_listbox = gtk_list_box_new ();
  self->snippets_add_button = gtk_button_new_from_icon_name ("list-add-symbolic", GTK_ICON_SIZE_BUTTON);

  box = gtk_scrolled_window_new (NULL, NULL);
  gtk_container_add (GTK_CONTAINER (box), self->snippets_listbox);

  gtk_widget_set_vexpand (box, TRUE);
  gtk_container_add (GTK_CONTAINER (self->snippets_page), box);

  gtk_container_add (GTK_CONTAINER (self->snippets_page), gtk_separator_new (GTK_ORIENTATION_HORIZONTAL));
  // TODO: The snippet page's design doesn't really work out anymore like this...
  box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_margin_start (self->snippets_add_button, 6);
  gtk_widget_set_margin_top (self->snippets_add_button, 6);
  gtk_widget_set_margin_bottom (self->snippets_add_button, 6);
  gtk_container_add (GTK_CONTAINER (box), self->snippets_add_button);
  w = gtk_label_new (_("You can activate snippets by writing the keyword and pressing TAB"));
  gtk_style_context_add_class (gtk_widget_get_style_context (w), "dim-label");
  gtk_widget_set_margin_start (w, 12);
  gtk_widget_set_margin_end (w, 6);
  gtk_widget_set_hexpand (w, TRUE);
  gtk_container_add (GTK_CONTAINER (box), w);
  gtk_container_add (GTK_CONTAINER (self->snippets_page), box);
  gtk_stack_add_titled (GTK_STACK (self->stack), self->snippets_page, "snippets", _("Snippets"));

  cb_settings_dialog_load_geometry (self);
}

GtkWidget *
cb_settings_dialog_new (GtkApplication *app)
{
  GtkWidget *self = GTK_WIDGET (g_object_new (CB_TYPE_SETTINGS_DIALOG,
                                              "application", app,
                                              NULL));

  return self;
}
