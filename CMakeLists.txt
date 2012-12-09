cmake_minimum_required(VERSION 2.6)
project("Corebrid" C)

list(APPEND CMAKE_MODULE_PATH
	${CMAKE_SOURCE_DIR}/build/
)

set (CMAKE_C_FLAGS "-g -Wall -Wno-incompatible-pointer-types -Wno-unused-value -Wno-unused-function -Wno-unused-variable")
set (CMAKE_C_COMPILER "clang")


find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16" MINIMUM)
include(ValaPrecompile)

# Actual C Code
find_package(PkgConfig)
pkg_check_modules(GLIB REQUIRED glib-2.0)
pkg_check_modules(GTK REQUIRED gtk+-3.0)
pkg_check_modules(GIO REQUIRED gio-2.0)
pkg_check_modules(REST REQUIRED rest-0.7)
pkg_check_modules(SQLHEAVY REQUIRED sqlheavy-0.2)
pkg_check_modules(GMODULE REQUIRED gmodule-2.0)
pkg_check_modules(GEE REQUIRED gee-1.0)
pkg_check_modules(JSON REQUIRED json-glib-1.0)
add_definitions(
	${GLIB_CFLAGS} ${GLIB_FLAGS_OTHER}	
	${GTK_CFLAGS} ${GTK_FLAGS_OTHER}
	${GIO_CFLAGS} ${GIO_FLAGS_OTHER}
	${REST_CFLAGS} ${REST_FLAGS_OTHER}
	${SQLHEAVY_CFLAGS} ${SQLHEAVY_FLAGS_OTHER}
	${GMODULE_CFLAGS} ${GMODULE_FLAGS_OTHER}
	${GEE_CFLAGS} ${GEE_FLAGS_OTHER}
	${JSON_CFLAGS} ${JSON_FLAGS_OTHER}
)
link_libraries(
	${GLIB_LIBRARIES}
	${GTK_LIBRARIES}
	${GIO_LIBRARIES}
	${REST_LIBRARIES}
	${SQLHEAVY_LIBRARIES}
	${GMODULE_LIBRARIES}
	${GEE_LIBRARIES}
	${JSON_LIBRARIES}
)
link_directories(
	${GLIB_LIBRARY_DIRS}
	${GTK_LIBRARY_DIRS}
	${GIO_LIBRARY_DIRS}
	${REST_LIBRARY_DIRS}
	${SQLHEAVY_LIBRARY_DIRS}
	${GMODULE_LIBRARY_DIRS}
	${GEE_LIBRARY_DIRS}
	${JSON_LIBRARY_DIRS}
)


vala_precompile(VALA_C
	src/Corebird.vala
	src/MainWindow.vala
	src/Tweet.vala
	src/Settings.vala
	src/FirstRunWindow.vala
	src/Twitter.vala
	src/NewTweetWindow.vala
	src/Utils.vala
	src/TweetList.vala
	src/TweetListEntry.vala
	src/SettingsDialog.vala
	src/containers/SearchContainer.vala
	src/containers/StreamContainer.vala
	src/containers/MentionsContainer.vala
	src/containers/FavoriteContainer.vala
	src/User.vala
	src/ProfileDialog.vala
	src/ProgressItem.vala
	src/Benchmark.vala
	src/widgets/ImageBox.vala
	src/widgets/ImageLabel.vala
	src/widgets/TweetTextView.vala
	src/widgets/ImageButton.vala
	src/widgets/ScrollWidget.vala
	src/LoaderThread.vala
PACKAGES
	glib-2.0
	gtk+-3.0
	gio-2.0
	rest-0.7
	sqlheavy-0.2
	gmodule-2.0
	gee-1.0
	json-glib-1.0
OPTIONS
	-g
	--thread 
	--target-glib=2.32
	--enable-checking
)


add_executable(Corebird ${VALA_C})
target_link_libraries(Corebird ${DEPS_LIBRARIES})

