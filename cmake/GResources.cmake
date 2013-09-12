#  This file is part of corebird, a Gtk+ linux Twitter client.
#  Copyright (C) 2013 Timm Bäder
#
#  corebird is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  corebird is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
#

# Old command:
# glib-compile-resources resources.xml --target=src/resources.c --generate-source




macro (add_resources RESOURCE_FILE DST)
  #  if(NOT EXISTS ${RESOURCE_FILE})
  #    message (FATAL_ERROR "Resource file '${RESOURCE_FILE}'does not exist")
  #  else()
  #    message ("Add GResource ${RESOURCE_FILE}")
  #    message ("Writing resouces to ${DST}")

    add_custom_command (OUTPUT ${DST}
                        COMMAND "glib-compile-resources"
                        ARGS
                          "${RESOURCE_FILE}"
                          "--target=${CMAKE_CURRENT_SOURCE_DIR}/${DST}"
                          "--generate-source"
                          DEPENDS ${RESOURCE_FILE})
                        #    add_custom_target (gresources DEPENDS ${RESOURCE_FILE})
                        #  endif()
endmacro (add_resources)
