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

#include "CbSettingsAccountRow.h"


G_DEFINE_TYPE (CbSettingsAccountRow, cb_settings_account_row, GTK_TYPE_LIST_BOX_ROW);

static gboolean
cb_settings_account_row_draw (GtkWidget *widget,
                              cairo_t   *ct)
{
  CbSettingsAccountRow *self = CB_SETTINGS_ACCOUNT_ROW (widget);
  const int surface_width = 200;

  if (self->banner != NULL)
    {
      int width = gtk_widget_get_allocated_width (widget);
      int height = gtk_widget_get_allocated_height (widget);

      cairo_rectangle (ct, width - surface_width, 0, surface_width, height);
      cairo_set_source_surface (ct, self->banner, width - surface_width, 0);
      cairo_fill (ct);
    }

  GTK_WIDGET_CLASS (cb_settings_account_row_parent_class)->draw (widget, ct);

  return GDK_EVENT_PROPAGATE;
}

static void
cb_settings_account_row_finalize (GObject *object)
{
  CbSettingsAccountRow *self = CB_SETTINGS_ACCOUNT_ROW (object);

  g_clear_object (&self->account);
  g_clear_pointer (&self->banner, cairo_surface_destroy);

  G_OBJECT_CLASS (cb_settings_account_row_parent_class)->finalize (object);
}

static void
cb_settings_account_row_class_init (CbSettingsAccountRowClass *klass)
{
  GObjectClass *object_class   = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  object_class->finalize = cb_settings_account_row_finalize;

  widget_class->draw = cb_settings_account_row_draw;
}

static void
cb_settings_account_row_init (CbSettingsAccountRow *self)
{

}

static void
create_ui (CbSettingsAccountRow *self)
{
  self->grid = gtk_grid_new ();
  self->name_label = gtk_label_new (self->account->name);
  self->avatar_widget = (GtkWidget *)avatar_widget_new ();
  self->description_label = gtk_label_new ("DESCRIPTION!");
  char *screen_name;

  screen_name = g_strdup_printf ("@%s", self->account->screen_name);
  self->screen_name_label = gtk_label_new (screen_name);
  g_free (screen_name);

  avatar_widget_set_size (AVATAR_WIDGET (self->avatar_widget), 48);
  avatar_widget_set_surface (AVATAR_WIDGET (self->avatar_widget), account_get_avatar (self->account));
  gtk_widget_set_margin_end (self->avatar_widget, 6);
  gtk_grid_attach (GTK_GRID (self->grid), self->avatar_widget, 0, 0, 1, 2);
  gtk_grid_attach (GTK_GRID (self->grid), self->name_label, 1, 0, 1, 1);
  gtk_style_context_add_class (gtk_widget_get_style_context (self->screen_name_label), "dim-label");
  gtk_widget_set_margin_start (self->screen_name_label, 6);
  gtk_grid_attach (GTK_GRID (self->grid), self->screen_name_label, 2, 0, 1, 1);

  gtk_style_context_add_class (gtk_widget_get_style_context (self->description_label), "dim-label");
  gtk_label_set_ellipsize (GTK_LABEL (self->description_label), PANGO_ELLIPSIZE_END);
  gtk_label_set_xalign (GTK_LABEL (self->description_label), 0.0);
  gtk_grid_attach (GTK_GRID (self->grid), self->description_label, 1, 1, 2, 1);

  g_object_set (G_OBJECT (self->grid), "margin", 6, NULL);
  gtk_container_add (GTK_CONTAINER (self), self->grid);
}

GtkWidget *
cb_settings_account_row_new (Account *account)
{
  CbSettingsAccountRow *self = CB_SETTINGS_ACCOUNT_ROW (g_object_new (CB_TYPE_SETTINGS_ACCOUNT_ROW,
                                                                      NULL));
  g_set_object (&self->account, account);
  create_ui (self);

  return GTK_WIDGET (self);
}

void
cb_settings_account_row_set_banner (CbSettingsAccountRow *self,
                                    cairo_surface_t      *banner)
{
  g_assert (self->banner == NULL);
  g_assert (banner != NULL);

  self->banner = banner;
  gtk_widget_queue_draw (GTK_WIDGET (self));
  // TODO: Start fade-in transition;
}
