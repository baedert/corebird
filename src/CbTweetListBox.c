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

#include <glib/gi18n.h>
#include "CbTweetListBox.h"
#include "CbTweetRow.h"
#include "CbUtils.h"
#include "corebird.h"

G_DEFINE_TYPE (CbTweetListBox, cb_tweet_list_box, GTK_TYPE_WIDGET);

enum {
  RETRY_BUTTON_CLICKED,
  LAST_SIGNAL
};
static guint tweet_list_box_signals[LAST_SIGNAL] = { 0 };


static GtkWidget *
tweet_row_create_func (gpointer item,
                       gpointer user_data)
{
  GtkRoot *root;

  g_assert (CB_IS_TWEET (item));

  root = gtk_widget_get_root (user_data);

  return cb_tweet_row_new (CB_TWEET (item), CB_MAIN_WINDOW (root));
}

static void
gesture_pressed_cb (GtkGestureClick *gesture,
                    int              n_press,
                    double           x,
                    double           y,
                    gpointer         user_data)
{
  CbTweetListBox *self = user_data;
  CbMainWindow *main_window;
  CbTweetRow *row;

  /* First, get the proper tweet row, because we're not using one
   * gesture per row here. */
  {
      GtkWidget *picked = gtk_widget_pick (GTK_WIDGET (self), x, y, 0);

      if (!picked) return;

      row = (CbTweetRow *)gtk_widget_get_ancestor (picked, CB_TYPE_TWEET_ROW);

      if (!row) return;
  }

  /* Retrieve our main window */
  {
    GtkRoot *root = gtk_widget_get_root (GTK_WIDGET (self));
    if (!root) return;

    if (!CB_IS_MAIN_WINDOW (root)) return;

    main_window = CB_MAIN_WINDOW (root);
  }


  /* Switch to the tweet info page */
  {
    CbTweet *tweet = row->tweet;
    CbBundle *args = cb_bundle_new ();
    cb_bundle_put_int (args, TWEET_INFO_PAGE_KEY_MODE, TWEET_INFO_PAGE_BY_INSTANCE);
    cb_bundle_put_bool (args, TWEET_INFO_PAGE_KEY_EXISTING, TRUE);
    cb_bundle_put_object (args, TWEET_INFO_PAGE_KEY_TWEET, (GObject *)tweet);

    cb_main_window_switch_page (main_window, PAGE_TWEET_INFO, args);
  }
}

static void
double_click_activation_setting_changed_cb (GObject    *obj,
                                            GParamSpec *pspec,
                                            gpointer    user_data)
{
  /*CbTweetListBox *self = user_data;*/
  /*GSettings *settings = G_SETTINGS (obj);*/

  /*gtk_list_box_set_activate_on_single_click ((GtkListBox *)self->widget,*/
                                             /*FALSE);*/
                                             /*!g_settings_get_boolean (settings, "double-click-activation"));*/
}

static void
retry_button_clicked_cb (GtkButton *source,
                         gpointer   user_data)
{
  g_signal_emit (user_data, tweet_list_box_signals[RETRY_BUTTON_CLICKED], 0);
}

static GtkWidget *
get_focused_row (CbTweetListBox *self)
{
  GtkRoot *toplevel = gtk_widget_get_root ((GtkWidget *)self);
  GtkWidget *focus_widget;

  if (!GTK_IS_WINDOW (toplevel))
    return NULL;

  focus_widget = gtk_window_get_focus (GTK_WINDOW (toplevel));

  if (focus_widget)
    return gtk_widget_get_ancestor (focus_widget, CB_TYPE_TWEET_ROW);

  return NULL;
}

static void
cb_tweet_list_box_finalize (GObject *obj)
{
  CbTweetListBox *self = (CbTweetListBox *)obj;

  g_clear_pointer (&self->widget, gtk_widget_unparent);
  g_object_unref (self->delta_updater);
  g_object_unref (self->model);

  G_OBJECT_CLASS (cb_tweet_list_box_parent_class)->finalize (obj);
}

static void
cb_tweet_list_box_class_init (CbTweetListBoxClass *klass)
{
  GObjectClass *object_class = (GObjectClass *)klass;
  GtkWidgetClass *widget_class = (GtkWidgetClass *)klass;

  /* vfuncs */
  object_class->finalize = cb_tweet_list_box_finalize;

  /* signals */
  tweet_list_box_signals[RETRY_BUTTON_CLICKED] = g_signal_new ("retry-button-clicked",
                                                               G_OBJECT_CLASS_TYPE (object_class),
                                                               G_SIGNAL_RUN_FIRST,
                                                               0,
                                                               NULL, NULL,
                                                               NULL, G_TYPE_NONE, 0);

  gtk_widget_class_set_layout_manager_type (widget_class, GTK_TYPE_BIN_LAYOUT);
}

static void
reply_activated_cb (GSimpleAction *action,
                    GVariant      *param,
                    gpointer       user_data)
{
  CbTweetListBox *self = user_data;
  GtkWidget *focus_row = get_focused_row (self);
  CbMainWindow *main_window;
  ComposeTweetWindow *window;
  CbTweet *tweet;


  if (!focus_row)
    return;

  tweet = CB_TWEET_ROW (focus_row)->tweet;
  main_window = CB_MAIN_WINDOW (gtk_widget_get_root ((GtkWidget *)self));

  window = compose_tweet_window_new (main_window,
                                     self->account,
                                     tweet,
                                     COMPOSE_TWEET_WINDOW_MODE_REPLY);
  gtk_widget_show (GTK_WIDGET (window));
}

static void
quote_activated_cb (GSimpleAction *action,
                    GVariant      *param,
                    gpointer       user_data)
{
  CbTweetListBox *self = user_data;
  GtkWidget *focus_row = get_focused_row (self);
  CbMainWindow *main_window;
  ComposeTweetWindow *window;
  CbTweet *tweet;


  if (!focus_row)
    return;

  tweet = CB_TWEET_ROW (focus_row)->tweet;
  main_window = CB_MAIN_WINDOW (gtk_widget_get_root ((GtkWidget *)self));

  window = compose_tweet_window_new (main_window,
                                     self->account,
                                     tweet,
                                     COMPOSE_TWEET_WINDOW_MODE_QUOTE);
  gtk_widget_show (GTK_WIDGET (window));
}



static void G_GNUC_UNUSED
debug_string_activated_cb (GSimpleAction *action,
                           GVariant      *param,
                           gpointer       user_data)
{
  CbTweetListBox *self = user_data;
  GtkWidget *row = get_focused_row (self);

  /* Will leak that string */
  if (row)
    g_message ("\n%s\n", cb_utils_get_tweet_debug_info (CB_TWEET_ROW (row)->tweet));
}

static void
cb_tweet_list_box_init (CbTweetListBox *self)
{
  GtkGesture *multipress_gesture;

  /* Actions */
  {
    static GActionEntry action_entries[] = {
      { "reply", reply_activated_cb, NULL, NULL, NULL },
      { "quote", quote_activated_cb, NULL, NULL, NULL },
#ifdef DEBUG
      { "debug-str", debug_string_activated_cb, NULL, NULL, NULL },
#endif
    };
    GActionGroup *action_group;

    action_group = G_ACTION_GROUP (g_simple_action_group_new ());
    g_action_map_add_action_entries (G_ACTION_MAP (action_group),
                                     action_entries, G_N_ELEMENTS (action_entries),
                                     self);
    gtk_widget_insert_action_group (GTK_WIDGET (self), "tweet", action_group);
  }

  self->widget = gtk_list_box_new ();
  gtk_widget_set_parent (self->widget, (GtkWidget *)self);

  gtk_style_context_add_class (gtk_widget_get_style_context ((GtkWidget *)self->widget), "tweets");
  gtk_list_box_set_selection_mode ((GtkListBox *)self->widget, GTK_SELECTION_NONE);
  /*gtk_list_box_set_activate_on_single_click ((GtkListBox *)self->widget,*/
                                             /*FALSE);*/
                                             /*!g_settings_get_boolean ((GSettings *)settings_get (),*/
                                                                      /*"double-click-activation"));*/

  self->model = cb_tweet_model_new ();
  self->delta_updater = cb_delta_updater_new ((GtkWidget *)self);
  multipress_gesture = gtk_gesture_click_new ();
  gtk_gesture_single_set_button ((GtkGestureSingle *)multipress_gesture, 0);
  gtk_event_controller_set_propagation_phase ((GtkEventController *)multipress_gesture,
                                              GTK_PHASE_BUBBLE);
  g_signal_connect (multipress_gesture, "pressed", G_CALLBACK (gesture_pressed_cb), self);
  gtk_widget_add_controller (GTK_WIDGET (self), (GtkEventController *)multipress_gesture);

  g_signal_connect (settings_get (), "changed::double-click-activation",
                    G_CALLBACK (double_click_activation_setting_changed_cb), self);

  gtk_list_box_bind_model ((GtkListBox *)self->widget,
                           (GListModel *)self->model,
                           tweet_row_create_func,
                           self,
                           NULL);

  {
    GtkEventController *controller;

    controller = gtk_shortcut_controller_new ();

    gtk_shortcut_controller_add_shortcut (GTK_SHORTCUT_CONTROLLER (controller),
                                          gtk_shortcut_new (gtk_shortcut_trigger_parse_string ("r"),
                                                            gtk_named_action_new ("tweet.reply")));
    gtk_shortcut_controller_add_shortcut (GTK_SHORTCUT_CONTROLLER (controller),
                                          gtk_shortcut_new (gtk_shortcut_trigger_parse_string ("m"),
                                                            gtk_named_action_new ("tweet.debug-str")));


    gtk_widget_add_controller (GTK_WIDGET (self), controller);
  }

  /* Create some pre-defined placeholder widgetry */
  {
    GtkWidget *loading_label;
    GtkWidget *error_box;
    GtkWidget *retry_button;

    self->placeholder = gtk_stack_new ();
    gtk_stack_set_transition_type ((GtkStack *)self->placeholder, GTK_STACK_TRANSITION_TYPE_CROSSFADE);

    loading_label = gtk_label_new (_("Loading…"));
    gtk_style_context_add_class (gtk_widget_get_style_context (loading_label), "dim-label");
    gtk_stack_add_named ((GtkStack *)self->placeholder, loading_label, "spinner");

    self->no_entries_label = gtk_label_new (_("No entries found"));
    gtk_style_context_add_class (gtk_widget_get_style_context (self->no_entries_label), "dim-label");
    gtk_label_set_wrap_mode ((GtkLabel *)self->no_entries_label, PANGO_WRAP_WORD_CHAR);
    gtk_stack_add_named ((GtkStack *)self->placeholder, self->no_entries_label, "no-entries");

    error_box = gtk_box_new (GTK_ORIENTATION_VERTICAL, 12);
    retry_button = gtk_button_new_with_label (_("Retry"));
    self->error_label = gtk_label_new ("");
    gtk_style_context_add_class (gtk_widget_get_style_context (self->error_label), "dim-label");
    gtk_label_set_wrap_mode ((GtkLabel *)self->error_label, PANGO_WRAP_WORD_CHAR);
    gtk_widget_set_margin_top (self->error_label, 12);
    gtk_widget_set_margin_end (self->error_label, 12);
    gtk_widget_set_margin_bottom (self->error_label, 12);
    gtk_widget_set_margin_start (self->error_label, 12);
    gtk_label_set_selectable ((GtkLabel *)self->error_label, TRUE);
    gtk_box_append (GTK_BOX (error_box), self->error_label);
    gtk_widget_set_halign (retry_button, GTK_ALIGN_CENTER);
    g_signal_connect (retry_button, "clicked", G_CALLBACK (retry_button_clicked_cb), self);
    gtk_box_append (GTK_BOX (error_box), retry_button);
    gtk_stack_add_named ((GtkStack *)self->placeholder, error_box, "error");

    gtk_stack_set_visible_child_name ((GtkStack *)self->placeholder, "spinner");
    gtk_widget_set_halign (self->placeholder, GTK_ALIGN_CENTER);
    gtk_widget_set_valign (self->placeholder, GTK_ALIGN_CENTER);
    gtk_list_box_set_placeholder ((GtkListBox *)self->widget, self->placeholder);
  }
}

CbTweetListBox *
cb_tweet_list_box_new (void)
{
  return (CbTweetListBox *)g_object_new (CB_TYPE_TWEET_LIST_BOX, NULL);
}

GtkWidget *
cb_tweet_list_box_get_widget (CbTweetListBox *self)
{
  return self->widget;
}

void
cb_tweet_list_box_set_account (CbTweetListBox *self,
                               void           *account)
{
  g_assert (IS_ACCOUNT (account));

  self->account = account;
}

void
cb_tweet_list_box_set_empty (CbTweetListBox *self)
{
  gtk_stack_set_visible_child_name ((GtkStack *)self->placeholder, "no-entries");
}

void
cb_tweet_list_box_set_unempty (CbTweetListBox *self)
{
  gtk_stack_set_visible_child_name ((GtkStack *)self->placeholder, "spinner");
}

void
cb_tweet_list_box_set_error (CbTweetListBox *self,
                             const char     *error_message)
{
  gtk_label_set_label (GTK_LABEL (self->error_label), error_message);
  gtk_stack_set_visible_child_name ((GtkStack *)self->placeholder, "error");
}

void
cb_tweet_list_box_set_placeholder_text (CbTweetListBox *self,
                                        const char     *placeholder_text)
{
  gtk_label_set_label (GTK_LABEL (self->no_entries_label), placeholder_text);
}

void
cb_tweet_list_box_reset_placeholder_text (CbTweetListBox *self)
{
  gtk_label_set_label (GTK_LABEL (self->no_entries_label), _("No entries found"));
}

GtkWidget *
cb_tweet_list_box_get_first_visible_row (CbTweetListBox *self)
{
  /* This is more a historical function. These days, we only have visible rows
   * in the listbox, so we can always return the first one. */

  return (GtkWidget*)gtk_list_box_get_row_at_index ((GtkListBox *)self->widget, 0);
}

GtkWidget *
cb_tweet_list_box_get_placeholder (CbTweetListBox *self)
{
  return self->placeholder;
}

void
cb_tweet_list_box_remove_all (CbTweetListBox *self)
{
  /*GList *children = gtk_container_get_children (GTK_CONTAINER (self->widget));*/
  /*GList *l;*/

  /*for (l = children; l; l = l->next)*/
    /*{*/
      /*if (GTK_WIDGET (l->data) != self->placeholder)*/
        /*gtk_container_remove ((GtkContainer *)self, l->data);*/
    /*}*/

  /*g_list_free (children);*/
}
