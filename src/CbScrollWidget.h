/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2019 Timm Bäder
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

#ifndef __CB_SCROLL_WIDGET_H__
#define __CB_SCROLL_WIDGET_H__

#include <gtk/gtk.h>

#define CB_TYPE_SCROLL_WIDGET cb_scroll_widget_get_type ()
G_DECLARE_DERIVABLE_TYPE (CbScrollWidget, cb_scroll_widget, CB, SCROLL_WIDGET, GtkWidget);

struct _CbScrollWidgetClass
{
  GtkWidgetClass parent_class;
};


GType           cb_scroll_widget_get_type                  (void) G_GNUC_CONST;
GtkWidget *     cb_scroll_widget_new                       (void);

void            cb_scroll_widget_set_policy                (CbScrollWidget *self,
                                                            GtkPolicyType   hscroll_policy,
                                                            GtkPolicyType   vscroll_policy);
gboolean        cb_scroll_widget_scrolled_down             (CbScrollWidget *self);
gboolean        cb_scroll_widget_scrolled_up               (CbScrollWidget *self);
void            cb_scroll_widget_scroll_down_next          (CbScrollWidget *self,
                                                            gboolean        animate,
                                                            gboolean        force_start);
void            cb_scroll_widget_scroll_up_next            (CbScrollWidget *self,
                                                            gboolean        animate,
                                                            gboolean        force_start);
void            cb_scroll_widget_balance_next_upper_change (CbScrollWidget *self,
                                                            int             mode);
GtkAdjustment * cb_scroll_widget_get_vadjustment           (CbScrollWidget *self);

void cb_scroll_widget_add          (CbScrollWidget *self, GtkWidget *child);
#endif
