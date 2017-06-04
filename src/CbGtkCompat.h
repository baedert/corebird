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
#ifndef CB_GTK_COMPAT_H
#define CB_GTK_COMPAT_H

#include <gtk/gtk.h>

#if GTK_CHECK_VERSION(3, 9, 1)
void gtk_widget_measure (GtkWidget      *widget,
                         GtkOrientation  orientation,
                         int             for_size,
                         int            *minimum,
                         int            *natural,
                         int            *minimum_baseline,
                         int            *natural_baseline)
{
  if (orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      g_assert (minimum_baseline == NULL);
      g_assert (natural_baseline == NULL);
      if (for_size == -1)
        gtk_widget_get_preferred_width (widget, minimum, natural);
      else
        gtk_widget_get_preferred_width_for_height (widget, for_size, minimum, natural);
    }
  else /* VERTICAL */
    {
      gtk_widget_get_preferred_height_and_baseline_for_width (widget,
                                                              for_size,
                                                              minimum,
                                                              natural,
                                                              minimum_baseline,
                                                              natural_baseline);
    }
}
#endif

#endif
