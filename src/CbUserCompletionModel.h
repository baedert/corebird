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

#ifndef _CB_USER_COMPLETION_MODEL_H
#define _CB_USER_COMPLETION_MODEL_H

#include "CbTypes.h"
#include "CbUserCounter.h"
#include <glib-object.h>
#include <gio/gio.h>

struct _CbUserCompletionModel
{
  GObject parent_instance;

  GArray *items;
};

typedef struct _CbUserCompletionModel CbUserCompletionModel;

#define CB_TYPE_USER_COMPLETION_MODEL cb_user_completion_model_get_type ()
G_DECLARE_FINAL_TYPE (CbUserCompletionModel, cb_user_completion_model, CB, USER_COMPLETION_MODEL, GObject);


CbUserCompletionModel * cb_user_completion_model_new          (void);
void                    cb_user_completion_model_insert_items (CbUserCompletionModel *self,
                                                               CbUserIdentity        *ids,
                                                               guint                  ids_len);
void                    cb_user_completion_model_insert_infos (CbUserCompletionModel *self,
                                                               CbUserInfo            *infos,
                                                               guint                  infos_len);
void                    cb_user_completion_model_clear        (CbUserCompletionModel *self);




#endif
