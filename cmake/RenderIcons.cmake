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



include (ParseArguments)

macro (render_icon ICON_NAME)
  parse_arguments(ARGS "SIZES" "" ${ARGN})
  message (STATUS "Icons will be installed into ${ICON_DEST_DIR} from ${ICON_SOURCE_DIR}")
  set (SRC "${CMAKE_CURRENT_SOURCE_DIR}/${ICON_SOURCE_DIR}")
  set (DST "${CMAKE_CURRENT_SOURCE_DIR}/${ICON_DEST_DIR}")


  # Our 'icons' target
  add_custom_target (icons ALL COMMENT "build icons")

  set (output_files "")
  foreach (size ${ARGS_SIZES})
    list (APPEND output_files "${size}x${size}/cb.png")
    execute_process (COMMAND ${CMAKE_COMMAND} -E make_directory "${DST}/${size}x${size}")
  endforeach (size ${ARGS_SIZES})




  message (STATUS "${ICON_NAME} will be rendered to ${output_files}")


  foreach (size ${ARGS_SIZES})
    add_custom_command (TARGET icons
                        COMMAND "rsvg-convert"
                        ARGS
                          "${SRC}/${ICON_NAME}.svg"
                          "--width=${size}"
                          "--height=${size}"
                          "--format=png"
                          "-o" "${DST}/${size}x${size}/${ICON_NAME}.png"
                        DEPENDS ${ICON_NAME})
  endforeach()

endmacro(render_icon icon_file sizes)
