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

#ifndef __CB_EMOJI_CHOOSER_H__
#define __CB_EMOJI_CHOOSER_H__

#include <gtk/gtk.h>

typedef struct {
  GtkWidget *box;
  GtkWidget *heading;
  GtkWidget *button;
  const char *first;
  gunichar label;
  gboolean empty;
} EmojiSection;

struct _CbEmojiChooser
{
  GtkBox parent_instance;

  guint populated : 1;
  guint populate_idle_id;

  GtkWidget *search_entry;
  GtkWidget *stack;
  GtkWidget *scrolled_window;

  EmojiSection recent;
  EmojiSection people;
  EmojiSection body;
  EmojiSection nature;
  EmojiSection food;
  EmojiSection travel;
  EmojiSection activities;
  EmojiSection objects;
  EmojiSection symbols;
  EmojiSection flags;

  GVariant *data;

  GSettings *settings;
};
typedef struct _CbEmojiChooser CbEmojiChooser;

#define CB_TYPE_EMOJI_CHOOSER cb_emoji_chooser_get_type ()
G_DECLARE_FINAL_TYPE (CbEmojiChooser, cb_emoji_chooser, CB, EMOJI_CHOOSER, GtkBox);

GtkWidget * cb_emoji_chooser_new      (void);
void        cb_emoji_chooser_populate (CbEmojiChooser *self);

#endif
