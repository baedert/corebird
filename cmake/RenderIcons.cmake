

include (ParseArguments)

macro (render_icon ICON_NAME)
  parse_arguments(ARGS "SIZES" "" ${ARGN})
  message (STATUS "Icons will be installed into ${ICON_DEST_DIR} from ${ICON_SOURCE_DIR}")

  set (output_files "")
  foreach (size ${ARGS_SIZES})
    list (APPEND output_files "${size}x${size}/cb.png")
  endforeach (size ${ARGS_SIZES})



  add_custom_target (icons COMMENT "build icons")

  message (STATUS "${ICON_NAME} will be rendered to ${output_files}")

  set (SRC "${CMAKE_CURRENT_SOURCE_DIR}/${ICON_SOURCE_DIR}")
  set (DST "${CMAKE_CURRENT_SOURCE_DIR}/${ICON_DEST_DIR}")

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
