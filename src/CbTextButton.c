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

#include "CbTextButton.h"

GtkWidget *
cb_text_button_new (const char *text)
{
  GtkWidget *label = gtk_label_new (text);
  GtkWidget *button;

  gtk_label_set_use_markup ((GtkLabel *)label, TRUE);
  gtk_label_set_ellipsize ((GtkLabel *)label, PANGO_ELLIPSIZE_END);
  gtk_label_set_xalign ((GtkLabel *)label, 0.0f);

  button = gtk_button_new ();
  gtk_container_add ((GtkContainer *)button, label);

  return button;
}

void
cb_text_button_set_text (GtkWidget  *button,
                         const char *text)
{
  GtkWidget *child;
  /* Should've been created using cb_text_button_new () */
  g_assert (GTK_IS_LABEL (gtk_bin_get_child (GTK_BIN (button))));

  child = gtk_bin_get_child (GTK_BIN (button));

  gtk_label_set_label (GTK_LABEL (child), text);
}
