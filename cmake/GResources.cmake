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

macro (resource_deps RESOURCE_FILE)
  execute_process (COMMAND "glib-compile-resources" "--generate-dependencies" "${RESOURCE_FILE}"
                   OUTPUT_VARIABLE "RESOURCES_DEPS"
                   OUTPUT_STRIP_TRAILING_WHITESPACE)
  # *EVIL LAUGH*
  #string (REPLACE "ui/" "../ui/" "RESOURCES_DEPS" ${RESOURCES_DEPS})
  string (REGEX REPLACE "\n" ";" RESOURCES_DEPS "${RESOURCES_DEPS}")
endmacro (resource_deps)
