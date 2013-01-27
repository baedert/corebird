
cmake_minimum_required (VERSION 2.6)
project (egglistbox) 


find_package(PkgConfig)

pkg_check_modules (DEPS REQUIRED "gtk+-3.0 >= 3.4.0 glib-2.0 >= 2.31.10")
add_definitions(${DEPS_CFLAGS})


add_library (egglistbox egg-list-box.c)
target_link_libraries(egglistbox ${DEPS})


#install (TARGETS libegglistbox DESTINATION bin)
#install (FILES egg-list-box.h DESTINATION include)