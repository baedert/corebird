set (VALA_SOURCE
  imagedialog.vala
  ../../src/resources.c
)

vala_precompile (VALA_C
  ${VALA_SOURCE}
PACKAGES
  ${DEPS}
  libcorebird_t
OPTIONS
  ${VALAC_OPTIONS}
)

set (BIN_NAME image-dialog)
add_executable (${BIN_NAME} ${VALA_C})
target_link_libraries (${BIN_NAME} ${DEPS_LIBRARIES})
target_link_libraries (${BIN_NAME} ${CMAKE_SOURCE_DIR}/../libcorebird_t.a)

