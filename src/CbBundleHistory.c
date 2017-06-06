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

#include "CbBundleHistory.h"
#include <string.h>

G_DEFINE_TYPE (CbBundleHistory, cb_bundle_history, G_TYPE_OBJECT);


static void
cb_bundle_history_finalize (GObject *object)
{
  CbBundleHistory *self = CB_BUNDLE_HISTORY (object);
  int i;

  for (i = 0; i < HISTORY_SIZE; i ++)
    {
      if (self->bundles[i] != NULL)
        g_object_unref (self->bundles[i]);
    }

  G_OBJECT_CLASS (cb_bundle_history_parent_class)->finalize (object);
}

static void
cb_bundle_history_init (CbBundleHistory *self)
{
  int i;

  for (i = 0; i < HISTORY_SIZE; i ++)
    self->elements[i] = -1;

  self->pos = -1;
}

static void
cb_bundle_history_class_init (CbBundleHistoryClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_bundle_history_finalize;
}

CbBundleHistory *
cb_bundle_history_new ()
{
  return CB_BUNDLE_HISTORY (g_object_new (CB_TYPE_BUNDLE_HISTORY, NULL));
}

void
cb_bundle_history_push (CbBundleHistory *self,
                        int              v,
                        CbBundle        *bundle)
{
   if (self->pos < HISTORY_SIZE - 1)
     {
       /* More space available. Just put it at the end and increase pos */
       self->pos ++;
     }
   else
     {
       /* No space left. Move everything one place to the start and then add @bundle */
       memmove (self->elements, self->elements + 1, sizeof (int) * (HISTORY_SIZE - 1));
       memmove (self->bundles,  self->bundles  + 1, sizeof (CbBundle *) * (HISTORY_SIZE - 1));
     }

   self->elements[self->pos] = v;
   self->bundles[self->pos] = bundle ? g_object_ref (bundle) : NULL;
}

int
cb_bundle_history_back (CbBundleHistory *self)
{
  if (self->pos > 0)
    {
      self->pos --;
      return self->elements[self->pos];
    }

  return -1;
}

int
cb_bundle_history_forward (CbBundleHistory *self)
{
  if (self->pos < HISTORY_SIZE - 1)
    {
      self->pos ++;
      return self->elements[self->pos];
    }

  return -1;
}

gboolean
cb_bundle_history_at_start (CbBundleHistory *self)
{
  return self->pos == 0;
}

gboolean
cb_bundle_history_at_end (CbBundleHistory *self)
{
  if (self->pos == HISTORY_SIZE - 1)
    return TRUE;

  if (self->pos == -1 ||
      self->elements[self->pos] == -1 ||
      self->elements[self->pos + 1] == -1)
    return TRUE;

  return FALSE;
}

void
cb_bundle_history_remove_current (CbBundleHistory *self)
{
  self->elements[self->pos] = -1;

  if (self->bundles[self->pos] != NULL)
    g_object_unref (self->bundles[self->pos]);
  self->bundles[self->pos] = NULL;

  /* Fill an eventual gap */
  if (self->pos + 1 < HISTORY_SIZE - 1 &&
      self->elements[self->pos + 1] != -1)
    {
      memmove (self->elements + self->pos,
              self->elements + self->pos + 1,
              (HISTORY_SIZE - self->pos - 1) * sizeof (int));

      memmove (self->bundles + self->pos,
              self->bundles + self->pos + 1,
              (HISTORY_SIZE - self->pos - 1) * sizeof (CbBundle*));
    }
}

int
cb_bundle_history_get_current (CbBundleHistory *self)
{
  if (self->pos == -1)
    return -1;

  return self->elements[self->pos];
}

CbBundle *
cb_bundle_history_get_current_bundle (CbBundleHistory *self)
{
  if (self->pos == -1)
    return NULL;

  return self->bundles[self->pos];
}
