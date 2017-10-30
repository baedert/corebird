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

#ifndef __CB_ANIMATION_H__
#define __CB_ANIMATION_H__

#include <gtk/gtk.h>

typedef struct _CbAnimation CbAnimation;

typedef void (*CbAnimateFunc) (CbAnimation *self,
                               double       t);

struct _CbAnimation
{
  GtkWidget *owner;
  guint64 duration;
  guint tick_id;
  guint reverse : 1;
  double start_percentage;

  guint64 start_time;
  CbAnimateFunc func;
};

void     cb_animation_init          (CbAnimation      *self,
                                     GtkWidget        *owner,
                                     CbAnimateFunc     func);
void     cb_animation_start         (CbAnimation       *self);
void     cb_animation_start_reverse (CbAnimation       *self);
void     cb_animation_stop          (CbAnimation       *self);
gboolean cb_animation_is_running    (const CbAnimation *self);
gboolean cb_animation_is_reverse    (const CbAnimation *self);
void     cb_animation_destroy       (CbAnimation       *self);

#endif
