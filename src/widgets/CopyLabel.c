/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2016 Timm Bäder
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
#include "../Types.h"
#include "CopyLabel.h"

G_DEFINE_TYPE (CbCopyLabel, cb_copy_label, GTK_TYPE_LABEL);

CbCopyLabel *
cb_copy_label_new (void)
{
  return CB_COPY_LABEL (g_object_new (CB_TYPE_COPY_LABEL, NULL));
}

void
cb_copy_label_set_tweet (CbCopyLabel *label,
                         CbTweet     *tweet)
{
  label->tweet = tweet;
}

static void
cb_copy_label_copy_clipboard (GtkLabel *gtk_label)
{
  CbCopyLabel *copy_label = CB_COPY_LABEL (gtk_label);
  int char_start, char_end;
  guint i;
  CbMiniTweet *mt;
  CbTextEntity *first_entity = NULL;
  const char *label = gtk_label_get_label (gtk_label);
  const char *text  = gtk_label_get_text (gtk_label);
  char *p;


  if (copy_label->tweet->retweeted_tweet == NULL)
    mt = &copy_label->tweet->source_tweet;
  else
    mt = copy_label->tweet->retweeted_tweet;

  gtk_label_get_selection_bounds (gtk_label, &char_start, &char_end);

  for (i = 0; i < mt->n_entities; i ++)
    {
      CbTextEntity *ent = &mt->entities[i];

      if (ent->from > char_start && ent->to < char_end)
        {
          first_entity = ent;
          break;
        }
    }

  if (first_entity == NULL)
    {
      /* easy, nothing special to do */
      return;
    }

  g_message ("Puh.");

  p = (char *)label;
  while (*p != '\0')
    {
      g_message ("char: %c", *p);

      p = g_utf8_next_char (p);
    }
  /*label_length = g_utf8_strlen (label, -1);*/
  /*for (label_index = 0; label_index < label_length; label_index ++)*/
    /*{*/

    /*}*/
}

static void
cb_copy_label_class_init (CbCopyLabelClass *klass)
{
  GtkLabelClass *label_class = GTK_LABEL_CLASS (klass);

  label_class->copy_clipboard = cb_copy_label_copy_clipboard;
}

static void
cb_copy_label_init (CbCopyLabel *label)
{

}
