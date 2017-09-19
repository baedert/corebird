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

#ifndef _CB_SETTINGS_ACCOUNT_ROW_H_
#define _CB_SETTINGS_ACCOUNT_ROW_H_

#include <gtk/gtk.h>
#include "corebird.h"

struct _CbSettingsAccountRow
{
  GtkListBoxRow parent_instance;

  Account *account;

  GtkWidget *grid;
  GtkWidget *avatar_widget;
  GtkWidget *name_label;
  GtkWidget *screen_name_label;
  GtkWidget *description_label;

  cairo_surface_t *banner;
};
typedef struct _CbSettingsAccountRow CbSettingsAccountRow;

#define CB_TYPE_SETTINGS_ACCOUNT_ROW cb_settings_account_row_get_type ()
G_DECLARE_FINAL_TYPE (CbSettingsAccountRow, cb_settings_account_row, CB, SETTINGS_ACCOUNT_ROW, GtkListBoxRow);


GtkWidget * cb_settings_account_row_new (Account *account);
void        cb_settings_account_row_set_banner (CbSettingsAccountRow *self,
                                                cairo_surface_t      *banner);

#endif
