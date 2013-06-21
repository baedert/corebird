# TODO: https://github.com/rcrowther/Vala_CMake

cmake_minimum_required(VERSION 2.6)
project("Corebrid" C)

list(APPEND CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/cmake/
)

# Enable coloring
set (CMAKE_COLOR_MAKEFILE ON)
# set (CMAKE_VERBOSE_MAKEFILE ON)

set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O0")
#set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-value")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-function")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-variable")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-unused-but-set-variable")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-deprecated-declarations")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I src/egglistbox/")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I src/libgd/")

# Just use PREFIX instead of CMAKE_INSTALL_PREFIX(but CMAKE_INSTALL_PREFIX will work too)
set (PREFIX           "${CMAKE_INSTALL_PREFIX}")
set (DATADIR          "${PREFIX}/share/corebird/")
set (GETTEXT_PACKAGE  "corebird")
set (VERSION          0.1)

configure_file (${CMAKE_SOURCE_DIR}/src/util/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/util/Config.vala)

include (ValaVersion)
include (ValaPrecompile)
include (GSettings)

find_package(Vala REQUIRED)
ensure_vala_version("0.20" MINIMUM)


add_subdirectory (po)
add_subdirectory (assets)
add_subdirectory (ui)
add_subdirectory (sql)


set (DEPS glib-2.0;
      gtk+-3.0;
      gio-2.0;
      rest-0.7;
      sqlheavy-0.2;
      gee-0.8;
      json-glib-1.0;
      libnotify;
      sqlite3;
      libsoup-2.4;
      gmodule-2.0;
)

find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED ${DEPS})

add_definitions(${DEPS_CFLAGS} "-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")
link_directories(${DEPS_LIBRARY_DIRS})


set (VALA_SOURCE
  src/Corebird.vala
  src/MainWindow.vala
  src/Tweet.vala
  src/Settings.vala
  src/FirstRunWindow.vala
  src/Twitter.vala
  src/ComposeTweetWindow.vala
  src/SettingsDialog.vala
  src/NotificationManager.vala
  src/ITimeline.vala
  src/HomeTimeline.vala
  src/MentionsTimeline.vala
  src/SearchTimeline.vala
  src/User.vala
  src/ProfileDialog.vala
  src/LoaderThread.vala
  src/IPage.vala
  src/ProfilePage.vala
  src/InlineMediaDownloader.vala
  src/UserStream.vala
  src/DeltaUpdater.vala
  src/WarningService.vala
  src/IMessageReceiver.vala
  src/ITwitterItem.vala
  src/Account.vala
  src/widgets/ImageDialog.vala
  src/widgets/ImageBox.vala
  src/widgets/ImageLabel.vala
  src/widgets/TweetTextView.vala
  src/widgets/ImageButton.vala
  src/widgets/ScrollWidget.vala
  src/widgets/TextButton.vala
  src/widgets/TweetInfoWidget.vala
  src/widgets/ProfileWidget.vala
  src/widgets/BadgeRadioToolButton.vala
  src/widgets/InvisibilityBin.vala
  src/widgets/ImageOverlay.vala
  src/list/TweetListEntry.vala
  src/list/NewFollowerEntry.vala
  src/list/ProgressEntry.vala
  src/util/UIBuilder.vala
  src/util/Utils.vala
  src/util/Benchmark.vala
  src/util/Config.vala
  src/util/WidgetReplacer.vala
  src/egglistbox/egg-list-box.c
  src/resources.c
)

vala_precompile(VALA_C
  ${VALA_SOURCE}
PACKAGES
  ${DEPS}
  egglistbox
OPTIONS
  -g
  --thread
  --target-glib=2.32
  --enable-checking
  --vapidir=src/egglistbox/
  --disable-warnings
  --gresources=resources.xml
)

add_executable(corebird ${VALA_C})
target_link_libraries(corebird ${DEPS_LIBRARIES})

# GSettings
add_schema ("org.baedert.corebird.gschema.xml")

install (TARGETS corebird RUNTIME DESTINATION bin)

