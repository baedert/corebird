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

#include "corebird.h"
#ifdef VIDEO
#include <gst/gst.h>
#endif

int
main (int argc, char **argv)
{
  GtkApplication *app;
  int ret;

#ifdef VIDEO
  gst_init (&argc, &argv);
#endif

  settings_init ();
  app = GTK_APPLICATION (corebird_new ());
  ret = g_application_run (G_APPLICATION (app), argc, argv);

#ifdef DEBUG
  {
    /* Explicitly destroy all remaining toplevel windows */
    GList *toplevels = gtk_window_list_toplevels ();
    GList *l = toplevels;

    g_debug ("Toplevels left: %u", g_list_length (toplevels));
    while (l)
      {
        GtkWidget *w = l->data;
        l = l->next;

        g_debug ("Destroying %s %p", G_OBJECT_TYPE_NAME (w), w);

        gtk_widget_destroy (w);
      }
    g_list_free (toplevels);
  }

#ifdef VIDEO
  gst_deinit ();
#endif

#endif /* ifdef DEBUG */

  g_object_unref (app);

  return ret;
}
