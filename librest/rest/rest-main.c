/*
 * librest - RESTful web services access
 * Copyright (c) 2008, 2009, Intel Corporation.
 *
 * Authors: Rob Bradford <rob@linux.intel.com>
 *          Ross Burton <ross@linux.intel.com>
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
 *
 */

#include "rest-private.h"

guint rest_debug_flags = 0;

/*
 * "Private" function used to set debugging flags based on environment
 * variables. Called upon entry into all public functions.
 */
void
_rest_setup_debugging (void)
{
  static gboolean setup_done = FALSE;
  static const GDebugKey keys[] = {
    { "xml-parser", REST_DEBUG_XML_PARSER },
    { "proxy", REST_DEBUG_PROXY }
  };

  if (G_LIKELY (setup_done))
    return;

  rest_debug_flags = g_parse_debug_string (g_getenv ("REST_DEBUG"),
                                           keys, G_N_ELEMENTS (keys));
  
  setup_done = TRUE;
}
