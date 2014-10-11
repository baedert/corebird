/* -*- Mode: C; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/*
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, see <http://www.gnu.org/licenses/>.
*/
#ifndef GLIB_COMPAT_H
#define GLIB_COMPAT_H

#include <glib-object.h>
#include <gio/gio.h>

#if !GLIB_CHECK_VERSION(2,28,0)
#define g_clear_object(object_ptr) \
  G_STMT_START {                                                             \
    /* Only one access, please */                                            \
    gpointer *_p = (gpointer) (object_ptr);                                  \
    gpointer _o;                                                             \
                                                                             \
    do                                                                       \
      _o = g_atomic_pointer_get (_p);                                        \
    while G_UNLIKELY (!g_atomic_pointer_compare_and_exchange (_p, _o, NULL));\
                                                                             \
    if (_o)                                                                  \
      g_object_unref (_o);                                                   \
  } G_STMT_END

GSimpleAsyncResult *
g_simple_async_result_new_take_error (GObject             *source_object,
                                      GAsyncReadyCallback  callback,
                                      gpointer             user_data,
                                      GError              *error);
void
g_simple_async_result_take_error(GSimpleAsyncResult *simple,
                                 GError             *error);
void
g_simple_async_report_take_gerror_in_idle (GObject *object,
                                           GAsyncReadyCallback callback,
                                           gpointer user_data,
                                           GError *error);

#endif /* glib 2.28 */

#endif /* GLIB_COMPAT_H */
