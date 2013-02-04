cmake_minimum_required(VERSION 2.6)
project("Corebrid" C)

list(APPEND CMAKE_MODULE_PATH
	${CMAKE_SOURCE_DIR}/build/
)

# Enable coloring
set (CMAKE_COLOR_MAKEFILE ON)
# set (CMAKE_VERBOSE_MAKEFILE ON)

set (CMAKE_C_FLAGS "-g")
set (CMAKE_C_FLAGS "-Wall")
set (CMAKE_C_FLAGS "-Wno-incompatible-pointer-types")
set (CMAKE_C_FLAGS "-Wno-unused-value")
set (CMAKE_C_FLAGS "-Wno-unused-function")
set (CMAKE_C_FLAGS "-Wno-unused-variable")
set (CMAKE_C_FLAGS "-Wno-deprecated-declarations")
set (CMAKE_C_FLAGS "-I src/egglistbox/")


find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16" MINIMUM)
include(ValaPrecompile)


set (DEPS glib-2.0;
		  gtk+-3.0;
		  gio-2.0;
		  rest-0.7;
		  sqlheavy-0.2;
		  gmodule-2.0;
		  gee-1.0;
		  json-glib-1.0;
		  libnotify;
		  sqlite3;
		  libsoup-2.4;
)

find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED ${DEPS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})



vala_precompile(VALA_C
	src/Corebird.vala
	src/MainWindow.vala
	src/Tweet.vala
	src/Settings.vala
	src/FirstRunWindow.vala
	src/Twitter.vala
	src/NewTweetWindow.vala
	src/SettingsDialog.vala
	src/NotificationManager.vala
	src/ITimeline.vala
	src/HomeTimeline.vala
	src/MentionsTimeline.vala
	src/User.vala
	src/ProfileDialog.vala
	src/LoaderThread.vala
	src/IPage.vala
	src/ProfilePage.vala
	src/widgets/ImageBox.vala
	src/widgets/ImageLabel.vala
	src/widgets/TweetTextView.vala
	src/widgets/ImageButton.vala
	src/widgets/ScrollWidget.vala
	src/widgets/PreferencesDialog.vala
	src/widgets/ProgressItem.vala
	src/widgets/TextButton.vala
	src/widgets/ArrowButton.vala
	src/widgets/TestToolButton.vala
	src/widgets/IPaneWidget.vala
	src/widgets/TweetListEntry.vala
	src/widgets/TweetInfoWidget.vala
	src/widgets/ProfileWidget.vala
	src/util/UIBuilder.vala
	src/util/Utils.vala
	src/util/Benchmark.vala
	src/egglistbox/egg-list-box.c
PACKAGES
	${DEPS}
	egglistbox
OPTIONS
	-g
	--thread 
	--target-glib=2.32
	--enable-checking
	--vapidir=src/egglistbox/
	-X '-I src/egglistbox/'
)

add_executable(Corebird ${VALA_C})
target_link_libraries(Corebird ${DEPS_LIBRARIES})

# GSettings
include (GSettings)
add_schema("org.baedert.corebird.gschema.xml")
