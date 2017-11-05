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

#include "CbUserCompletionModel.h"

static void  cb_user_completion_model_iface_init (GListModelInterface *iface);

G_DEFINE_TYPE_WITH_CODE (CbUserCompletionModel, cb_user_completion_model, G_TYPE_OBJECT,
                         G_IMPLEMENT_INTERFACE (G_TYPE_LIST_MODEL, cb_user_completion_model_iface_init));


static GType
cb_user_completion_model_get_item_type (GListModel *model)
{
  return G_TYPE_POINTER;
}

static guint
cb_user_completion_model_get_n_items (GListModel *model)
{
  CbUserCompletionModel *self = CB_USER_COMPLETION_MODEL (model);

  return self->items->len;
}

static gpointer
cb_user_completion_model_get_item (GListModel *model,
                                   guint       index)
{
  CbUserCompletionModel *self = CB_USER_COMPLETION_MODEL (model);
  CbUserIdentity *id = &g_array_index (self->items, CbUserIdentity, index);

  g_assert (index < self->items->len);

  return id;
}

static void
cb_user_completion_model_iface_init (GListModelInterface *iface)
{
  iface->get_item_type = cb_user_completion_model_get_item_type;
  iface->get_n_items = cb_user_completion_model_get_n_items;
  iface->get_item = cb_user_completion_model_get_item;
}

static void
cb_user_completion_model_init (CbUserCompletionModel *self)
{
  self->items = g_array_new (FALSE, FALSE, sizeof (CbUserIdentity));
  g_array_set_clear_func (self->items, (GDestroyNotify)cb_user_identity_free);
}

static void
cb_user_completion_model_finalize (GObject *object)
{
  CbUserCompletionModel *self = CB_USER_COMPLETION_MODEL (object);

  g_array_free (self->items, TRUE);

  G_OBJECT_CLASS (cb_user_completion_model_parent_class)->finalize (object);
}

static void
cb_user_completion_model_class_init (CbUserCompletionModelClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = cb_user_completion_model_finalize;
}

CbUserCompletionModel *
cb_user_completion_model_new (void)
{
  return CB_USER_COMPLETION_MODEL (g_object_new (CB_TYPE_USER_COMPLETION_MODEL, NULL));
}

static inline gboolean
cb_user_completion_model_has_id (CbUserCompletionModel *self,
                                 gint64                 id)
{
  guint x;

  /* Look for duplicate */
  for (x = 0; x < self->items->len; x ++)
    {
      const CbUserIdentity *existing_id = &g_array_index (self->items, CbUserIdentity, x);

      if (existing_id->id == id)
        return TRUE;
    }

  return FALSE;
}

static inline void
emit_items_changed (CbUserCompletionModel *self,
                    guint                  position,
                    guint                  removed,
                    guint                  added)
{
  g_list_model_items_changed (G_LIST_MODEL (self), position, removed, added);
}


void
cb_user_completion_model_insert_items (CbUserCompletionModel *self,
                                       CbUserIdentity        *ids,
                                       guint                  ids_len)
{
  guint i;
  guint size_before;
  guint added = 0;

  g_return_if_fail (CB_IS_USER_COMPLETION_MODEL (self));

  if (ids_len == 0)
    return;

  size_before = self->items->len;
 
  for (i = 0; i < ids_len; i ++)
    {
      CbUserIdentity *id = &ids[i];
      CbUserIdentity *new_id;

      if (cb_user_completion_model_has_id (self, id->id))
        continue;

      g_array_set_size (self->items, self->items->len + 1);
      new_id = &g_array_index (self->items, CbUserIdentity, self->items->len - 1);

      new_id->id = id->id;
      new_id->screen_name = g_steal_pointer (&id->screen_name);
      new_id->user_name = g_steal_pointer (&id->user_name);
      new_id->verified = id->verified;
      added ++;
    }

  emit_items_changed (self, size_before, 0, added);
}

void
cb_user_completion_model_insert_infos (CbUserCompletionModel *self,
                                       CbUserInfo            *infos,
                                       guint                  infos_len)
{
  guint i;
  guint size_before;
  guint added = 0;

  g_return_if_fail (CB_IS_USER_COMPLETION_MODEL (self));

  if (infos_len == 0)
    return;

  size_before = self->items->len;

  for (i = 0; i < infos_len; i ++)
    {
      CbUserInfo *info = &infos[i];
      CbUserIdentity *new_id;

      if (cb_user_completion_model_has_id (self, info->user_id))
        continue;

      g_array_set_size (self->items, self->items->len + 1);
      new_id = &g_array_index (self->items, CbUserIdentity, self->items->len - 1);

      new_id->id = info->user_id;
      new_id->screen_name = g_steal_pointer (&info->screen_name);
      new_id->user_name = g_steal_pointer (&info->user_name);
      new_id->verified = FALSE;
      added ++;
    }


  emit_items_changed (self, size_before, 0, added);
}

void
cb_user_completion_model_clear (CbUserCompletionModel *self)
{
  guint old_size;

  g_return_if_fail (CB_IS_USER_COMPLETION_MODEL (self));

  old_size = self->items->len;
  g_array_remove_range (self->items, 0, self->items->len);

  emit_items_changed (self, 0, old_size, 0);
}
