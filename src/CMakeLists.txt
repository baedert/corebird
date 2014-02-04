


resource_deps ("${CMAKE_CURRENT_SOURCE_DIR}/../resources.xml")

add_custom_command (
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/resources.c
  COMMAND glib-compile-resources ../resources.xml --target=resources.c --generate-source --sourcedir=../
  DEPENDS "${RESOURCES_DEPS}"
)

add_custom_target (generated_resources DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/resources.c)
