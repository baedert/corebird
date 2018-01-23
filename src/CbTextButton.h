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

#ifndef __CB_TEXT_BUTTON_H__
#define __CB_TEXT_BUTTON_H__

#include <gtk/gtk.h>

/* This is not actually a new class, just some convenience API around
 * a normal GtkButton. */

GtkWidget * cb_text_button_new      (const char *text);
void        cb_text_button_set_text (GtkWidget  *button,
                                     const char *text);

#endif
