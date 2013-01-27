cmake_minimum_required(VERSION 2.6)
project("Corebrid" C)

list(APPEND CMAKE_MODULE_PATH
	${CMAKE_SOURCE_DIR}/build/
)

set (CMAKE_C_FLAGS "-g -Wall -Wno-incompatible-pointer-types -Wno-unused-value -Wno-unused-function -Wno-unused-variable -Wno-format-invalid-specifier ")


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
	src/TweetList.vala
	src/SettingsDialog.vala
	src/NotificationManager.vala
	src/containers/SearchContainer.vala
	src/containers/StreamContainer.vala
	src/containers/MentionsContainer.vala
	src/containers/FavoriteContainer.vala
	src/containers/TweetContainer.vala
	src/User.vala
	src/ProfileDialog.vala
	src/LoaderThread.vala
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
	src/widgets/PaneWidget.vala
	src/widgets/TweetListEntry.vala
	src/widgets/TweetInfoWidget.vala
	src/util/UIBuilder.vala
	src/util/Utils.vala
	src/util/Benchmark.vala
	src/sql/Query.vala
	src/sql/InsertQuery.vala
PACKAGES
	${DEPS}
OPTIONS
	-g
	-v
	-X -v
	--enable-mem-profiler
	--cc=clang
	--thread 
	--target-glib=2.32
	--enable-checking
	--vapidir=src/egglistbox/
CUSTOM_VAPIS
	src/egglistbox/egglistbox.vapi
)
include_directories("src/egglistbox")
#add_subdirectory("src/egglistbox")

add_executable(Corebird ${VALA_C})
target_link_libraries(Corebird ${DEPS_LIBRARIES})

# GSettings
include (GSettings)
add_schema("org.baedert.corebird.gschema.xml")
