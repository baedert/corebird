


resource_deps ("${CMAKE_CURRENT_SOURCE_DIR}/../resources.xml")


message (STATUS "${CMAKE_SOURCE_DIR}")

add_custom_command (
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/resources.c
  COMMAND glib-compile-resources ${CMAKE_SOURCE_DIR}/resources.xml --target=resources.c --generate-source --sourcedir=${CMAKE_SOURCE_DIR}
  #WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  DEPENDS ../resources.xml
  #DEPENDS "${RESOURCES_DEPS}"
)

add_custom_target (generated_resources DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/resources.c)
