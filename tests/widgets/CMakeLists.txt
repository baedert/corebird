# TODO: Move this stuff into tests/
cmake_minimum_required (VERSION 2.8)
project("widget-tests" C)
list (APPEND CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/../../cmake/
)


set (CMAKE_VERBOSE_MAKEFILE ON)

include (ValaVersion)
include (ValaPrecompile)
include (GSettings)

set (DEPS glib-2.0;
      gtk+-3.0;
      gio-2.0;
      rest-0.7;
      gee-0.8;
      json-glib-1.0;
      libnotify;
      sqlite3;
      libsoup-2.4;
)
set (VALA_SOURCE
  widgets.vala
  ../../src/resources.c
)

#include_directories (${CMAKE_SOURCE_DIR}/../../)

set (VALAC_OPTIONS
  -g
  --thread
  --gresources=../../resources.xml
  --target-glib=2.38
  --enable-checking
  --vapidir="${CMAKE_SOURCE_DIR}/../../vapi/"
  --vapidir="${CMAKE_SOURCE_DIR}/../../"
)


find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${DEPS})

add_definitions (${DEPS_CFLAGS})
add_definitions (-I../../)
link_directories (${DEPS_LIBRARY_DIRS})
link_directories (${CMAKE_SOURCE_DIR}/../../)


vala_precompile (VALA_C
  ${VALA_SOURCE}
PACKAGES
  ${DEPS}
  libcorebird_t
OPTIONS
  ${VALAC_OPTIONS}
)


add_executable (widgets ${VALA_C})
#add_dependencies (widgets generated_resources)
target_link_libraries (widgets ${DEPS_LIBRARIES})
target_link_libraries (widgets ${CMAKE_SOURCE_DIR}/../../libcorebird_t.a)

