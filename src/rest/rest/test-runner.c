/*
 * librest - RESTful web services access
 * Copyright (C) 2009 Intel Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU Lesser General Public License,
 * version 2.1, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
 * more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <config.h>
#include <glib-object.h>

#define test_add(unit_name, func) G_STMT_START {                        \
    extern void func (void);                                            \
    g_test_add_func (unit_name, func); } G_STMT_END

int
main (int argc, char *argv[])
{
  g_test_init (&argc, &argv, NULL);

  test_add ("/oauth/param-encoding", test_param_encoding);

  return g_test_run ();
}
