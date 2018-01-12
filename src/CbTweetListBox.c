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
#include "corebird.h"

G_DEFINE_TYPE (CbTweetListBox, cb_tweet_list_box, GTK_TYPE_LIST_BOX);

enum {
  RETRY_BUTTON_CLICKED,
  LAST_SIGNAL
};
static guint tweet_list_box_signals[LAST_SIGNAL] = { 0 };


static GtkWidget *
tweet_row_create_func (gpointer item,
                       gpointer user_data)
{
  g_assert (CB_IS_TWEET (item));

  return cb_tweet_row_new (CB_TWEET (item),
                           MAIN_WINDOW (gtk_widget_get_toplevel (GTK_WIDGET (user_data))));
}

static void
gesture_pressed_cb (GtkGestureMultiPress *gesture,
                    int                   n_press,
                    double                x,
                    double                y,
                    gpointer              user_data)
{
  CbTweetListBox *self = user_data;

  g_message (__FUNCTION__);
}

static void
double_click_activation_setting_changed_cb (GObject    *obj,
                                            GParamSpec *pspec,
                                            gpointer    user_data)
{
  CbTweetListBox *self = user_data;
  GSettings *settings = G_SETTINGS (obj);

  gtk_list_box_set_activate_on_single_click ((GtkListBox *)self,
                                             !g_settings_get_boolean (settings, "double-click-activation"));
}

static void
retry_button_clicked_cb (GtkButton *source,
                         gpointer   user_data)
{
  g_signal_emit (user_data, tweet_list_box_signals[RETRY_BUTTON_CLICKED], 0);
}

static void
cb_tweet_list_box_finalize (GObject *obj)
{
  CbTweetListBox *self = (CbTweetListBox *)obj;

  g_object_unref (self->delta_updater);
  g_object_unref (self->multipress_gesture);
  g_object_unref (self->model);

  G_OBJECT_CLASS (cb_tweet_list_box_parent_class)->finalize (obj);
}

static void
cb_tweet_list_box_class_init (CbTweetListBoxClass *klass)
{
  GtkBindingSet *binding_set;
  GObjectClass *object_class = (GObjectClass *)klass;

  /* vfuncs */
  object_class->finalize = cb_tweet_list_box_finalize;

  /* signals */
  tweet_list_box_signals[RETRY_BUTTON_CLICKED] = g_signal_new ("retry-button-clicked",
                                                               G_OBJECT_CLASS_TYPE (object_class),
                                                               G_SIGNAL_RUN_FIRST,
                                                               0,
                                                               NULL, NULL,
                                                               NULL, G_TYPE_NONE, 0);
  /* key bindings */
  binding_set = gtk_binding_set_by_class (klass);
  // TODO :(
}

static void
cb_tweet_list_box_init (CbTweetListBox *self)
{
  gtk_style_context_add_class (gtk_widget_get_style_context ((GtkWidget *)self), "tweets");
  gtk_list_box_set_selection_mode ((GtkListBox *)self, GTK_SELECTION_NONE);
  gtk_list_box_set_activate_on_single_click ((GtkListBox *)self,
                                             !g_settings_get_boolean ((GSettings *)settings_get (),
                                                                      "double-click-activation"));

  self->model = cb_tweet_model_new ();
  self->delta_updater = cb_delta_updater_new ((GtkWidget *)self);
  self->multipress_gesture = gtk_gesture_multi_press_new ((GtkWidget *)self);
  gtk_gesture_single_set_button ((GtkGestureSingle *)self->multipress_gesture, 0);
  gtk_event_controller_set_propagation_phase ((GtkEventController *)self->multipress_gesture,
                                              GTK_PHASE_BUBBLE);
  g_signal_connect (self->multipress_gesture, "pressed", G_CALLBACK (gesture_pressed_cb), self);

  g_signal_connect (settings_get (), "changed::double-click-activation",
                    G_CALLBACK (double_click_activation_setting_changed_cb), self);

  gtk_list_box_bind_model ((GtkListBox *)self,
                           (GListModel *)self->model,
                           tweet_row_create_func,
                           self,
                           NULL);
  
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
    gtk_label_set_line_wrap_mode ((GtkLabel *)self->no_entries_label, PANGO_WRAP_WORD_CHAR);
    gtk_stack_add_named ((GtkStack *)self->placeholder, self->no_entries_label, "no-entries");

    error_box = gtk_box_new (GTK_ORIENTATION_VERTICAL, 12);
    retry_button = gtk_button_new_with_label (_("Retry"));
    self->error_label = gtk_label_new ("");
    gtk_style_context_add_class (gtk_widget_get_style_context (self->error_label), "dim-label");
    gtk_label_set_line_wrap_mode ((GtkLabel *)self->error_label, PANGO_WRAP_WORD_CHAR);
    gtk_widget_set_margin_top (self->error_label, 12);
    gtk_widget_set_margin_end (self->error_label, 12);
    gtk_widget_set_margin_bottom (self->error_label, 12);
    gtk_widget_set_margin_start (self->error_label, 12);
    gtk_label_set_selectable ((GtkLabel *)self->error_label, TRUE);
    gtk_container_add (GTK_CONTAINER (error_box), self->error_label);
    gtk_widget_set_halign (retry_button, GTK_ALIGN_CENTER);
    g_signal_connect (retry_button, "clicked", G_CALLBACK (retry_button_clicked_cb), self);
    gtk_container_add (GTK_CONTAINER (error_box), retry_button);
    gtk_stack_add_named ((GtkStack *)self->placeholder, error_box, "error");

    gtk_stack_set_visible_child_name ((GtkStack *)self->placeholder, "spinner");
    gtk_widget_set_halign (self->placeholder, GTK_ALIGN_CENTER);
    gtk_widget_set_valign (self->placeholder, GTK_ALIGN_CENTER);
    gtk_list_box_set_placeholder ((GtkListBox *)self, self->placeholder);
  }
}

GtkWidget *
cb_tweet_list_box_new (void)
{
  return GTK_WIDGET (g_object_new (CB_TYPE_TWEET_LIST_BOX, NULL));
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
  return NULL;
}

GtkWidget *
cb_tweet_list_box_get_placeholder (CbTweetListBox *self)
{
  return self->placeholder;
}


void
cb_tweet_list_box_remove_all (CbTweetListBox *self)
{
  GList *children = gtk_container_get_children (GTK_CONTAINER (self));
  GList *l;

  for (l = children; l; l = l->next)
    {
      if (GTK_WIDGET (l->data) != self->placeholder)
        gtk_container_remove ((GtkContainer *)self, l->data);
    }

  g_list_free (children);
}
