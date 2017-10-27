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

#ifndef __CB_TEXT_VIEW_H__
#define __CB_TEXT_VIEW_H__

#include <gtk/gtk.h>


struct _CbTextView
{
  GtkWidget parent_instance;

  void *account;

  GtkWidget *text_view;
  GtkWidget *scrolled_window;
  GtkWidget *box;

  GtkWidget *completion_listbox;
};

#define CB_TYPE_TEXT_VIEW cb_text_view_get_type ()
G_DECLARE_FINAL_TYPE (CbTextView, cb_text_view, CB, TEXT_VIEW, GtkWidget);


GtkWidget * cb_text_view_new              (void);
void        cb_text_view_set_account      (CbTextView *self,
                                           void       *acc);
void        cb_text_view_add_widget       (CbTextView *self,
                                           GtkWidget  *widget);
void        cb_text_view_insert_at_cursor (CbTextView *self,
                                           const char *text);
void        cb_text_view_set_text         (CbTextView *self,
                                           const char *text);

#endif
