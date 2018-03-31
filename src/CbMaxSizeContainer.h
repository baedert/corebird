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

#include <gtk/gtk.h>

typedef struct _CbMaxSizeContainer      CbMaxSizeContainer;
struct _CbMaxSizeContainer
{
  GtkBin parent_instance;

  int max_size;
};

#define CB_TYPE_MAX_SIZE_CONTAINER cb_max_size_container_get_type ()
G_DECLARE_FINAL_TYPE (CbMaxSizeContainer, cb_max_size_container, CB, MAX_SIZE_CONTAINER, GtkBin);

void          cb_max_size_container_set_max_size (CbMaxSizeContainer *self,
                                                  int                 max_size);
int           cb_max_size_container_get_max_size (CbMaxSizeContainer *self);
