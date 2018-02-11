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

#include "CbMainWindow.h"
#include "CbUtils.h"
#include "corebird.h"
#include <glib/gi18n.h>

G_DEFINE_TYPE (CbMainWindow, cb_main_window, GTK_TYPE_APPLICATION_WINDOW);

static int
accounts_list_sort_func (GtkListBoxRow *row1,
                         GtkListBoxRow *row2,
                         gpointer user_data)
{
  UserListEntry *e1;
  UserListEntry *e2;

  if (IS_ADD_LIST_ENTRY (row1))
    return 1;

  e1 = USER_LIST_ENTRY (row1);
  e2 = USER_LIST_ENTRY (row2);

  return g_ascii_strcasecmp (user_list_entry_get_screen_name (e1),
                             user_list_entry_get_screen_name (e2));
}

static void
cb_main_window_finalize (GObject *object)
{
  CbMainWindow *self = CB_MAIN_WINDOW (object);

  g_clear_object (&self->thumb_button_gesture);

  G_OBJECT_CLASS (cb_main_window_parent_class)->finalize (object);
}

static void
accounts_row_action_clicked_cb (UserListEntry *entry,
                                gpointer       user_data)
{
  CbMainWindow *self = user_data;

  gtk_popover_popdown (GTK_POPOVER (self->accounts_popover));
}

static void
app_account_added_cb (Corebird *cb,
                      Account  *account,
                      gpointer  user_data)
{
  CbMainWindow *self = user_data;
  GList *entries, *l;
  GtkWidget *row;

  entries = gtk_container_get_children (GTK_CONTAINER (self->accounts_list));

  for (l = entries; l; l = l->next)
    {
      if (!IS_USER_LIST_ENTRY (l->data))
        continue;

      if (user_list_entry_get_user_id (USER_LIST_ENTRY (l->data)) == account->id)
        goto out;
    }

  /* Account not yet in list */
  row = (GtkWidget *)user_list_entry_new_from_account (account);
  user_list_entry_set_show_settings (USER_LIST_ENTRY (row), TRUE);
  g_signal_connect (row, "action-clicked", G_CALLBACK (accounts_row_action_clicked_cb), self);

  gtk_container_add (GTK_CONTAINER (self->accounts_list), row);

out:
  g_list_free (entries);
}

static void
app_account_removed_cb (Corebird *cb,
                        Account  *account,
                        gpointer  user_data)
{
  CbMainWindow *self = user_data;
  GList *entries, *l;

  entries = gtk_container_get_children (GTK_CONTAINER (self->accounts_list));

  for (l = entries; l; l = l->next)
    {
      if (!IS_USER_LIST_ENTRY (l->data))
        continue;

      if (user_list_entry_get_user_id (USER_LIST_ENTRY (l->data)) == account->id)
        {
          gtk_container_remove (GTK_CONTAINER (self->accounts_list), GTK_WIDGET (l->data));
          break;
        }
    }

  g_list_free (entries);
}

static void
account_create_widget_result_received_cb (AccountCreateWidget *widget,
                                          gboolean             result,
                                          Account             *account,
                                          gpointer             user_data)
{
  CbMainWindow *self = user_data;

  if (result)
    cb_main_window_change_account (self, account);
  else
    account_remove_account ("screen_name");

  g_message ("result: %d", result);
}

static void
accounts_list_row_activated_cb (GtkListBox    *list,
                                GtkListBoxRow *row,
                                gpointer       user_data)
{
  CbMainWindow *self = user_data;
  UserListEntry *ule;
  gint64 user_id;
  Corebird *cb;
  CbMainWindow *out_window = NULL;
  Account *acc;

  if (IS_ADD_LIST_ENTRY (row))
    {
      Account *dummy_acc;
      GtkWidget *window;

      gtk_popover_popdown (GTK_POPOVER (self->accounts_popover));
      dummy_acc = account_new (0, ACCOUNT_DUMMY, "name");
      window = cb_main_window_new (dummy_acc);
      gtk_application_add_window (GTK_APPLICATION (g_application_get_default ()),
                                  GTK_WINDOW (window));
      gtk_widget_show (window);

      return;
    }

  g_assert (IS_USER_LIST_ENTRY (row));

  cb = COREBIRD (g_application_get_default ());
  ule = USER_LIST_ENTRY (row);
  user_id = user_list_entry_get_user_id (ule);

  if (user_id == ACCOUNT (self->account)->id ||
      corebird_is_window_open_for_user_id (cb, user_id, &out_window))
    {
      gtk_popover_popdown (GTK_POPOVER (self->accounts_popover));

      if (out_window != NULL)
        gtk_window_present (GTK_WINDOW (out_window));

      return;
    }

  acc = account_query_account_by_id (user_id);
  if (acc != NULL)
    {
      cb_main_window_change_account (self, acc);
      gtk_popover_popdown (GTK_POPOVER (self->accounts_popover));
    }
  else
    {
      g_warning ("No valid account for id %" G_GINT64_FORMAT " found", user_id);
    }
}

static void
focus_set_cb (GtkWindow *window,
              GtkWidget *widget,
              gpointer   user_data)
{
  g_message ("Focus widget now: %s %p", widget ? G_OBJECT_TYPE_NAME (widget) : "NULL", widget);
}

static gboolean
cb_main_window_close_request (GtkWindow *window)
{
  CbMainWindow *self = CB_MAIN_WINDOW (window);
  GList *windows, *l;
  char **startup_accounts;
  int n_startup_accounts;
  int n_main_windows = 0;

  if (self->main_widget != NULL)
    main_widget_stop (MAIN_WIDGET (self->main_widget));

  if (self->account == NULL)
    goto out;

  startup_accounts = g_settings_get_strv (settings_get (), "startup-accounts");
  n_startup_accounts = g_strv_length (startup_accounts);

  if (n_startup_accounts == 1 && strlen (startup_accounts[0]) == 0)
    n_startup_accounts = 0; /* In case we have only one entry and it's "" */

  cb_main_window_save_geometry (self);

  if (n_startup_accounts > 0)
    goto out;

  /* Save the account as a startup account, if this window is the last one
   * to get closed. */

  windows = gtk_application_get_windows (GTK_APPLICATION (g_application_get_default ()));
  for (l = windows; l; l = l->next)
    {
      GtkWidget *window = l->data;

      if (CB_IS_MAIN_WINDOW (window) &&
          CB_MAIN_WINDOW (window)->account != NULL &&
          strcmp (ACCOUNT (CB_MAIN_WINDOW (window)->account)->screen_name, ACCOUNT_DUMMY) != 0)
        n_main_windows ++;
    }

  if (n_main_windows == 1)
    {
      const char *new_startup_accounts[2];

      new_startup_accounts[0] = ACCOUNT (self->account)->screen_name;
      new_startup_accounts[1] = NULL;

      g_settings_set_strv (settings_get (), "startup-accounts", new_startup_accounts);
    }

out:
  return GTK_WINDOW_CLASS (cb_main_window_parent_class)->close_request (window);
}

static void
account_button_clicked_cb (GtkButton *source,
                           gpointer   user_data)
{
  CbMainWindow *self = user_data;

  if (gtk_widget_get_visible (self->accounts_popover))
    gtk_popover_popdown (GTK_POPOVER (self->accounts_popover));
  else
    gtk_popover_popup (GTK_POPOVER (self->accounts_popover));
}

static void
accounts_popover_closed_cb (GtkPopover *popover,
                            gpointer    user_data)
{
  CbMainWindow *self = user_data;

  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->account_button), FALSE);
}

static void
back_button_clicked_cb (GtkButton *source,
                        gpointer   user_data)
{
  CbMainWindow *self = user_data;

  main_widget_switch_page (MAIN_WIDGET (self->main_widget), PAGE_PREVIOUS, NULL);
}

static void
compose_window_destroyed_cb (GtkWidget *widget,
                             gpointer   user_data)
{
  CbMainWindow *self = user_data;

  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (self->compose_tweet_button), FALSE);
  self->compose_window = NULL;
}

static void
thumb_button_gesture_pressed_cb (GtkGestureMultiPress *gesture,
                                 int                   n_press,
                                 double                x,
                                 double                y,
                                 gpointer              user_data)
{
  CbMainWindow *self = user_data;
  guint button = gtk_gesture_single_get_current_button (GTK_GESTURE_SINGLE (gesture));

  if (button == 9)
    {
      /* Forward thumb button */
      main_widget_switch_page (MAIN_WIDGET (self->main_widget), PAGE_NEXT, NULL);
      gtk_gesture_set_state (GTK_GESTURE (gesture), GTK_EVENT_SEQUENCE_CLAIMED);
    }
  else if (button == 8)
    {
      /* Backward thumb button */
      main_widget_switch_page (MAIN_WIDGET (self->main_widget), PAGE_PREVIOUS, NULL);
      gtk_gesture_set_state (GTK_GESTURE (gesture), GTK_EVENT_SEQUENCE_CLAIMED);
    }
}

static void
account_info_changed_cb (Account    *account,
                         const char *screen_name,
                         const char *user_name,
                         GdkTexture *avatar_small,
                         GdkTexture *avatar,
                         gpointer    user_data)
{
  CbMainWindow *self = user_data;
  IPage *cur_page;
  char *title;

  g_assert (CB_IS_MAIN_WINDOW (user_data));

  /* Just update title from the current page */
  cur_page = cb_main_window_get_page (self, cb_main_window_get_cur_page_id (self));
  cb_main_window_set_window_title (self, ipage_get_title (cur_page),
                                   GTK_STACK_TRANSITION_TYPE_NONE);

  title = g_strdup_printf ("Corebird - @%s", screen_name);
  gtk_window_set_title (GTK_WINDOW (self), title);
  g_free (title);
}

void
cb_main_window_save_geometry (CbMainWindow *self)
{
  GVariant *win_geom;
  GVariant *new_geom;
  GVariantBuilder builder;
  GVariantIter geom_iter;
  int x = 0, y = 0, w = 0, h = 0;
  char *key;

  if (self->account == NULL ||
      strcmp (ACCOUNT (self->account)->screen_name, ACCOUNT_DUMMY) == 0)
    return;

  win_geom = g_settings_get_value (settings_get (), "window-geometry");
  g_variant_iter_init (&geom_iter, win_geom);
  g_variant_builder_init (&builder, G_VARIANT_TYPE ("a{s(iiii)}"));

  while (g_variant_iter_next (&geom_iter, "{s(iiii)}", &key, &x, &y, &w, &h))
    {
      if (strcmp (key, ACCOUNT (self->account)->screen_name) != 0)
        g_variant_builder_add (&builder, "{s(iiii)}", key, x, y, w, h);

      g_free (key);
    }

  /* Now add this window's geometry */
  g_variant_builder_add (&builder, "{s(iiii)}",
                         ACCOUNT (self->account)->screen_name, x, y, w, h);
  new_geom = g_variant_builder_end (&builder);

  g_settings_set_value (settings_get (), "window-geometry", new_geom);

  g_variant_unref (win_geom);
}

static void
load_geometry (CbMainWindow *self)
{
  GVariant *win_geom;
  int x = 0, y = 0, w = 0, h = 0;

  if (self->account == NULL ||
      strcmp (ACCOUNT (self->account)->screen_name, ACCOUNT_DUMMY) == 0)
    return;

  win_geom = g_settings_get_value (settings_get (), "window-geometry");

  if (!g_variant_lookup (win_geom, ACCOUNT (self->account)->screen_name, "(iiii)", &x, &y, &w, &h))
    {
      g_warning ("Could not load window geometry for screen name '%s'",
                 ACCOUNT (self->account)->screen_name);
      goto out;
    }

  if (w > 0 && h > 0)
    {
      gtk_window_set_default_size (GTK_WINDOW (self), w, h);
      gtk_window_move (GTK_WINDOW (self), x, y);
    }

out:
  g_variant_unref (win_geom);
}

static void
headerbar_key_press_event_cb (GtkWidget   *widget,
                              GdkEventKey *event,
                              gpointer     user_data)
{
  CbMainWindow *self = user_data;
  guint keyval;

  gdk_event_get_keyval ((GdkEvent *)event, &keyval);

  if (keyval == GDK_KEY_Down && self->main_widget != NULL)
    {
      IPage *cur_page = cb_main_window_get_page (self, cb_main_window_get_cur_page_id (self));

      gtk_widget_child_focus (GTK_WIDGET (cur_page), GTK_DIR_RIGHT);
    }
}

static void
toggle_compose_window (GSimpleAction *action,
                       GVariant      *parameter,
                       gpointer       user_data)
{
  CbMainWindow *self = user_data;

  g_assert (self != NULL);

  if (self->account == NULL ||
      strcmp (ACCOUNT (self->account)->screen_name, ACCOUNT_DUMMY) == 0)
    return;

  if (self->compose_window == NULL)
    {
      self->compose_window = (GtkWidget *)compose_tweet_window_new (self, self->account, NULL,
                                                                    COMPOSE_TWEET_WINDOW_MODE_NORMAL);

      g_signal_connect (self->compose_window, "destroy",
                        G_CALLBACK (compose_window_destroyed_cb), self);

      gtk_widget_show (self->compose_window);
    }
  else
    {
      gtk_widget_destroy (self->compose_window);
      self->compose_window = NULL;
    }
}

static void
toggle_topbar_visible (GSimpleAction *action,
                       GVariant      *parameter,
                       gpointer       user_data)
{
  settings_toggle_topbar_visible ();
}

static void
simple_switch_page (GSimpleAction *action,
                    GVariant      *parameter,
                    gpointer       user_data)
{
  CbMainWindow *self = user_data;

  if (self->main_widget == NULL)
    return;

  main_widget_switch_page (MAIN_WIDGET (self->main_widget),
                           g_variant_get_int32 (parameter),
                           NULL);
}

static void
show_account_dialog (GSimpleAction *action,
                     GVariant      *parameter,
                     gpointer       user_data)
{
  CbMainWindow *self = user_data;
  GtkWidget *dialog;

  g_assert (self != NULL);

  if (self->account == NULL ||
      strcmp (ACCOUNT (self->account)->screen_name, ACCOUNT_DUMMY) == 0)
    return;

  dialog = (GtkWidget *)account_dialog_new (self->account);
  gtk_window_set_transient_for (GTK_WINDOW (dialog), GTK_WINDOW (self));
  gtk_window_set_modal (GTK_WINDOW (dialog), TRUE);
  gtk_widget_show (dialog);
}

static void
show_accounts_list (GSimpleAction *action,
                    GVariant      *parameter,
                    gpointer       user_data)
{
  CbMainWindow *self = user_data;

  if (self->account == NULL ||
      strcmp (ACCOUNT (self->account)->screen_name, ACCOUNT_DUMMY) == 0)
    return;

  gtk_popover_popup (GTK_POPOVER (self->accounts_popover));
}

static void
previous_page (GSimpleAction *action,
               GVariant      *parameter,
               gpointer       user_data)
{
  CbMainWindow *self = user_data;

  if (self->account == NULL ||
      strcmp (ACCOUNT (self->account)->screen_name, ACCOUNT_DUMMY) == 0)
    return;

  main_widget_switch_page (MAIN_WIDGET (self->main_widget), PAGE_PREVIOUS, NULL);
}

static void
next_page (GSimpleAction *action,
           GVariant      *parameter,
           gpointer       user_data)
{
  CbMainWindow *self = user_data;

  if (self->account == NULL ||
      strcmp (ACCOUNT (self->account)->screen_name, ACCOUNT_DUMMY) == 0)
    return;

  main_widget_switch_page (MAIN_WIDGET (self->main_widget), PAGE_NEXT, NULL);
}

static const GActionEntry win_entries[] = {
  {"compose-tweet",       toggle_compose_window},
  {"toggle-topbar",       toggle_topbar_visible},
  {"switch-page",         simple_switch_page, "i"},
  {"show-account-dialog", show_account_dialog},
  {"show-account-list",   show_accounts_list},
  {"previous",            previous_page},
  {"next",                next_page}
};

static void
cb_main_window_init (CbMainWindow *self)
{
  Corebird *cb;
  GtkWidget *accounts_frame;
  GtkWidget *add_entry;
  guint i;

  gtk_window_set_default_size ((GtkWindow *)self, 530, 700);
  gtk_window_set_icon_name ((GtkWindow *)self, "corebird");
  g_action_map_add_action_entries (G_ACTION_MAP (self), win_entries, G_N_ELEMENTS (win_entries), self);

#ifdef DEBUG
  g_signal_connect (self, "set-focus", G_CALLBACK (focus_set_cb), NULL);
#endif

  /* Create UI */
  self->headerbar = gtk_header_bar_new ();
  gtk_header_bar_set_title (GTK_HEADER_BAR (self->headerbar), "Corebird");
  gtk_header_bar_set_show_title_buttons (GTK_HEADER_BAR (self->headerbar), TRUE);
  g_signal_connect (self->headerbar, "key-press-event", G_CALLBACK (headerbar_key_press_event_cb), self);
  gtk_window_set_titlebar ((GtkWindow *)self, self->headerbar);

  self->title_stack = gtk_stack_new ();
  self->title_label = gtk_label_new ("");
  gtk_label_set_ellipsize (GTK_LABEL (self->title_label), PANGO_ELLIPSIZE_MIDDLE);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->title_label), "title");
  gtk_container_add (GTK_CONTAINER (self->title_stack), self->title_label);
  self->last_page_label = gtk_label_new ("");
  gtk_label_set_ellipsize (GTK_LABEL (self->last_page_label), PANGO_ELLIPSIZE_MIDDLE);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->last_page_label), "title");
  gtk_container_add (GTK_CONTAINER (self->title_stack), self->last_page_label);

  gtk_header_bar_set_custom_title (GTK_HEADER_BAR (self->headerbar), self->title_stack);

  self->header_box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 6);
  self->account_button = gtk_toggle_button_new ();
  gtk_widget_set_tooltip_text (self->account_button, _("Show configured accounts"));
  g_signal_connect (self->account_button, "clicked", G_CALLBACK (account_button_clicked_cb), self);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->account_button), "account-button");
  self->avatar_widget = (GtkWidget *)avatar_widget_new ();
  avatar_widget_set_size (AVATAR_WIDGET (self->avatar_widget), 24);
  gtk_widget_set_valign (self->avatar_widget, GTK_ALIGN_CENTER);
  gtk_container_add (GTK_CONTAINER (self->account_button), self->avatar_widget);
  gtk_container_add (GTK_CONTAINER (self->header_box), self->account_button);

  self->compose_tweet_button = gtk_toggle_button_new ();
  gtk_button_set_icon_name (GTK_BUTTON (self->compose_tweet_button), "corebird-compose-symbolic");
  gtk_widget_set_tooltip_text (self->compose_tweet_button, _("Compose tweet"));
  gtk_actionable_set_action_name (GTK_ACTIONABLE (self->compose_tweet_button), "win.compose-tweet");
  gtk_container_add (GTK_CONTAINER (self->header_box), self->compose_tweet_button);

  self->back_button = gtk_button_new_from_icon_name ("go-previous-symbolic");
  g_signal_connect (self->back_button, "clicked", G_CALLBACK (back_button_clicked_cb), self);
  gtk_container_add (GTK_CONTAINER (self->header_box), self->back_button);

  self->accounts_popover = gtk_popover_new (self->account_button);
  g_signal_connect (self->accounts_popover, "closed", G_CALLBACK (accounts_popover_closed_cb), self);
  accounts_frame = gtk_frame_new (NULL);
  gtk_widget_set_margin_start (accounts_frame, 6);
  gtk_widget_set_margin_end (accounts_frame, 6);
  gtk_widget_set_margin_top (accounts_frame, 6);
  gtk_widget_set_margin_bottom (accounts_frame, 6);
  gtk_container_add (GTK_CONTAINER (self->accounts_popover), accounts_frame);
  self->accounts_list = gtk_list_box_new ();
  gtk_list_box_set_selection_mode (GTK_LIST_BOX (self->accounts_list), GTK_SELECTION_NONE);
  gtk_list_box_set_sort_func (GTK_LIST_BOX (self->accounts_list), accounts_list_sort_func, NULL, NULL);
  gtk_list_box_set_header_func (GTK_LIST_BOX (self->accounts_list), cb_default_header_func, NULL, NULL);
  g_signal_connect (self->accounts_list, "row-activated", G_CALLBACK (accounts_list_row_activated_cb), self);
  gtk_container_add (GTK_CONTAINER (accounts_frame), self->accounts_list);

  add_entry = (GtkWidget *)add_list_entry_new (_("Add new Account"));
  gtk_container_add (GTK_CONTAINER (self->accounts_list), add_entry);

  for (i = 0; i < account_get_n (); i ++)
    {
      Account *acc = account_get_nth (i);
      GtkWidget *row;

      if (strcmp (acc->screen_name, ACCOUNT_DUMMY) == 0)
        continue;

      row = (GtkWidget *)user_list_entry_new_from_account (acc);
      g_signal_connect (row, "action-clicked", G_CALLBACK (accounts_row_action_clicked_cb), self);
      gtk_container_add (GTK_CONTAINER (self->accounts_list), row);
    }

  gtk_header_bar_pack_start (GTK_HEADER_BAR (self->headerbar), self->header_box);

  self->thumb_button_gesture = gtk_gesture_multi_press_new (GTK_WIDGET (self));
  gtk_gesture_single_set_button (GTK_GESTURE_SINGLE (self->thumb_button_gesture), 0);
  gtk_event_controller_set_propagation_phase (GTK_EVENT_CONTROLLER (self->thumb_button_gesture), GTK_PHASE_CAPTURE);
  g_signal_connect (self->thumb_button_gesture, "pressed", G_CALLBACK (thumb_button_gesture_pressed_cb), self);

  cb = COREBIRD (g_application_get_default ());
  g_signal_connect (cb, "account-added", G_CALLBACK (app_account_added_cb), self);
  g_signal_connect (cb, "account-removed", G_CALLBACK (app_account_removed_cb), self);
}

static void
cb_main_window_class_init (CbMainWindowClass *klass)
{
  GObjectClass   *object_class = G_OBJECT_CLASS (klass);
  GtkWindowClass *window_class = GTK_WINDOW_CLASS (klass);

  object_class->finalize = cb_main_window_finalize;

  window_class->close_request = cb_main_window_close_request;
}

GtkWidget *
cb_main_window_new (void *account)
{
  CbMainWindow *self;
  g_assert (IS_ACCOUNT (account));

  self = CB_MAIN_WINDOW (g_object_new (CB_TYPE_MAIN_WINDOW, NULL));
  cb_main_window_change_account (self, ACCOUNT (account));
  load_geometry (self);

  gtk_application_window_set_show_menubar ((GtkApplicationWindow *)self, FALSE);
  return GTK_WIDGET (self);
}

void
cb_main_window_set_window_title (CbMainWindow           *self,
                                 const char             *title,
                                 GtkStackTransitionType  transition_type)
{
  gtk_label_set_label (GTK_LABEL (self->last_page_label),
                       gtk_label_get_label (GTK_LABEL (self->title_label)));
  gtk_stack_set_transition_type (GTK_STACK (self->title_stack), GTK_STACK_TRANSITION_TYPE_NONE);
  gtk_stack_set_visible_child (GTK_STACK (self->title_stack), self->last_page_label);

  gtk_stack_set_transition_type (GTK_STACK (self->title_stack), transition_type);
  gtk_label_set_label (GTK_LABEL (self->title_label), title);
  gtk_stack_set_visible_child (GTK_STACK (self->title_stack), self->title_label);
}

void
cb_main_window_rerun_filters (CbMainWindow *self)
{
  /* We only do this for stream + mentions at the moment */
  default_timeline_rerun_filters (DEFAULT_TIMELINE (cb_main_window_get_page (self, PAGE_STREAM)));
  default_timeline_rerun_filters (DEFAULT_TIMELINE (cb_main_window_get_page (self, PAGE_MENTIONS)));
}

void
cb_main_window_mark_tweet_as_read (CbMainWindow *self,
                                   gint64        tweet_id)
{
  DefaultTimeline *home_timeline;
  DefaultTimeline *mentions_timeline;
  CbTweet *tweet = NULL;

  home_timeline = DEFAULT_TIMELINE (cb_main_window_get_page (self, PAGE_STREAM));
  mentions_timeline = DEFAULT_TIMELINE (cb_main_window_get_page (self, PAGE_MENTIONS));

  tweet = cb_tweet_model_get_for_id (home_timeline->tweet_list->model, tweet_id, 0);

  if (tweet != NULL)
    {
      cb_tweet_set_seen (tweet, TRUE);
      default_timeline_set_unread_count (home_timeline,
                                         default_timeline_get_unread_count (home_timeline) - 1);
    }

  /* Mentions */
  tweet = cb_tweet_model_get_for_id (mentions_timeline->tweet_list->model, tweet_id, 0);

  if (tweet != NULL)
    {
      cb_tweet_set_seen (tweet, TRUE);
      default_timeline_set_unread_count (mentions_timeline,
                                         default_timeline_get_unread_count (mentions_timeline) - 1);
    }
}

void
cb_main_window_reply_to_tweet (CbMainWindow *self,
                               gint64        tweet_id)
{
  CbTweet *tweet;
  DefaultTimeline *home_timeline;
  GtkWidget *window;

  home_timeline = DEFAULT_TIMELINE (cb_main_window_get_page (self, PAGE_STREAM));

  tweet = cb_tweet_model_get_for_id (home_timeline->tweet_list->model, tweet_id, 0);

  if (tweet == NULL)
    {
      g_message ("Tweet with id %" G_GINT64_FORMAT " could not be found", tweet_id);
      return;
    }

  window = (GtkWidget *)compose_tweet_window_new (self, self->account, tweet,
                                                  COMPOSE_TWEET_WINDOW_MODE_REPLY);
  gtk_widget_show (window);
}


int
cb_main_window_get_cur_page_id (CbMainWindow *self)
{
  if (self->main_widget == NULL)
    return -1;

  return main_widget_get_cur_page_id (MAIN_WIDGET (self->main_widget));
}

void *
cb_main_window_get_page (CbMainWindow *self,
                         int           page_id)
{
  return main_widget_get_page (MAIN_WIDGET (self->main_widget), page_id);
}

void
cb_main_window_change_account (CbMainWindow *self,
                               void         *acc)
{
  Account *account = ACCOUNT (acc);
  Account *old_account = self->account ? ACCOUNT (self->account) : NULL;
  Corebird *cb;
  gint64 old_user_id = 0;

  g_assert (IS_ACCOUNT (acc));

  if (old_account != NULL)
    {
      old_user_id = old_account->id;
      g_signal_handlers_disconnect_by_func (old_account, G_CALLBACK (account_info_changed_cb), self);
    }

  self->account = account;

  if (self->main_widget != NULL)
    main_widget_stop (MAIN_WIDGET (self->main_widget));

  if (gtk_bin_get_child (GTK_BIN (self)) != NULL)
    {
      gtk_container_remove (GTK_CONTAINER (self), gtk_bin_get_child (GTK_BIN (self)));
    }

  cb = COREBIRD (g_application_get_default ());

  if (account != NULL &&
      strcmp (account->screen_name, ACCOUNT_DUMMY) != 0)
    {
      IPage *first_page;
      char *title;
      gboolean shell_shows_app_menu;

      gtk_widget_show (self->header_box);

      self->main_widget = (GtkWidget *)main_widget_new (account, self, cb);
      gtk_container_add (GTK_CONTAINER (self), self->main_widget);
      main_widget_switch_page (MAIN_WIDGET (self->main_widget), 0, NULL);

      first_page = main_widget_get_page (MAIN_WIDGET (self->main_widget), 0);
      cb_main_window_set_window_title (self, ipage_get_title (first_page), GTK_STACK_TRANSITION_TYPE_NONE);

      avatar_widget_set_texture (AVATAR_WIDGET (self->avatar_widget),
                                 account_get_avatar_small (account));
      g_signal_connect (account, "info-changed", G_CALLBACK (account_info_changed_cb), self);
      title = g_strdup_printf ("Corebird - @%s", account->screen_name);
      gtk_window_set_title (GTK_WINDOW (self), title);
      g_free (title);

      g_signal_emit_by_name (cb, "account-window-changed", old_user_id, account->id);

      /* Disable app menu in the titlebar since we do that ourselves */
      g_object_get (gtk_settings_get_default (), "gtk-shell-shows-app-menu", &shell_shows_app_menu, NULL);
      if (!shell_shows_app_menu)
        {
          if (self->app_menu_button == NULL)
            {
              self->app_menu_button = gtk_menu_button_new ();
              gtk_button_set_icon_name (GTK_BUTTON (self->app_menu_button), "emblem-system-symbolic");
              gtk_menu_button_set_menu_model (GTK_MENU_BUTTON (self->app_menu_button),
                                              gtk_application_get_app_menu (GTK_APPLICATION (cb)));
              gtk_header_bar_pack_end (GTK_HEADER_BAR (self->headerbar), self->app_menu_button);
            }
          else
            {
              gtk_widget_show (self->app_menu_button);
            }
        }
    }
  else
    {
      Account *acc;
      GtkWidget *account_create_widget;
      /* Special case when creating a new account */
      gtk_widget_hide (self->header_box);

      if (self->app_menu_button != NULL)
        gtk_widget_hide (self->app_menu_button);

      if (account != NULL)
        acc = account;
      else
        acc = account_new (0, ACCOUNT_DUMMY, "name");

      gtk_label_set_label (GTK_LABEL (self->title_label), "Corebird");
      gtk_window_set_title (GTK_WINDOW (self), "Corebird");

      account_add_account (acc);
      account_create_widget = (GtkWidget *)account_create_widget_new (acc, cb, self);
      gtk_container_add (GTK_CONTAINER (self), account_create_widget);
      g_signal_connect (account_create_widget, "result-received",
                        G_CALLBACK (account_create_widget_result_received_cb), self);
    }


}
