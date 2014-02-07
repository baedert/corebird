cmake_minimum_required (VERSION 2.8)
project("tests" C)
list (APPEND CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/../cmake/
)


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


set (VALAC_OPTIONS
  -g
  --thread
  --gresources=../../resources.xml
  --target-glib=2.38
  --enable-checking
  --vapidir="${CMAKE_SOURCE_DIR}/../vapi/"
  --vapidir="${CMAKE_SOURCE_DIR}/../"
)


find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${DEPS})

add_definitions (${DEPS_CFLAGS})
add_definitions (-I../../)
link_directories (${DEPS_LIBRARY_DIRS})
link_directories (${CMAKE_SOURCE_DIR}/../../)

add_subdirectory (missing-list-entry)
add_subdirectory (imagedialog)
