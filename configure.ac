AC_INIT([corebird],[1.2],[mail@baedert.org])

AC_PREREQ([2.65])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_SRCDIR([configure.ac])
AM_INIT_AUTOMAKE([1.11 foreign no-dist-gzip dist-xz subdir-objects])

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AM_MAINTAINER_MODE([enable])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_STDC
AC_PROG_INSTALL

LT_PREREQ([2.2.6])
LT_INIT([disable-static])

VALA_MIN_VERSION=0.28.0
AM_PROG_VALAC([$VALA_MIN_VERSION],
  [],
  [AC_MSG_ERROR([valac >= $VALA_MIN_VERSION is required])])

GLIB_GSETTINGS


# --enable-debug
AC_ARG_ENABLE(debug, AS_HELP_STRING([--enable-debug], [Enable debugging]),, enable_debug=no)
AM_CONDITIONAL([ENABLE_DEBUG], [ test "$enable_debug" = "yes"])

# --disable-video
AC_ARG_ENABLE(video, AS_HELP_STRING([--disable-video], [Disable video support]),, disable_video=no)
AM_CONDITIONAL([DISABLE_VIDEO], [ test "$disable_video" = "yes"])

# --disable-gst-check
AC_ARG_ENABLE(gst_check, AS_HELP_STRING([--disable-gst-check], [Disable check for needed gstreamer elements]),, disable_gst_check=no)
AM_CONDITIONAL([DISABLE_GST_CHECK], [ test "$disable_gst_check" = "yes"])



# Vala Packages {{{
pkg_modules="gtk+-3.0 >= 3.16
             glib-2.0 >= 2.44
             rest-0.7 >= 0.7.93
             libsoup-2.4
             json-glib-1.0
             sqlite3"

if test "$disable_video" = "no"; then
  pkg_modules="$pkg_modules gstreamer-video-1.0 >= 1.6"
fi

PKG_CHECK_MODULES(CB, [$pkg_modules])


CB_VALA_FLAGS=" \
  --pkg gtk+-3.0 \
  --pkg json-glib-1.0 \
  --pkg rest-0.7 \
  --pkg sqlite3 \
  --pkg libsoup-2.4 \
  --pkg glib-2.0 \
  --target-glib=2.38"
# }}}

AC_SUBST(CB_CFLAGS)
AC_SUBST(CB_LIBS)
AC_SUBST(CB_VALA_FLAGS)


AC_ARG_VAR([GLIB_COMPILE_RESOURCES],[the glib-compile-resources program])
AC_PATH_PROG([GLIB_COMPILE_RESOURCES],[glib-compile-resources],[])
if test -z "$GLIB_COMPILE_RESOURCES"; then
  AC_MSG_ERROR([glib-compile-resources not found])
fi

AC_ARG_VAR([XMLLINT],[the xmllint program])
AC_PATH_PROG([XMLLINT],[xmllint],[])
if test -z "$XMLLINT"; then
  AC_MSG_ERROR([xmllint not found])
fi


if test "${CC}" = "clang"; then
  CB_CFLAGS="$CB_CFLAGS -Wno-incompatible-pointer-types -Wno-incompatible-pointer-types-discards-qualifiers"
fi

if test "$disable_video" = "no"; then
  CB_VALA_FLAGS="$CB_VALA_FLAGS \
                 -D VIDEO \
                 --pkg gstreamer-video-1.0"
fi

if test "$enable_debug" = "yes"; then
  CB_VALA_FLAGS="$CB_VALA_FLAGS -D DEBUG -g"
fi


if test "$disable_gst_check" = "no"; then
  # Check for gtksink
  GST_ELEMENT_CHECK([gtksink], [1.0], [], [])
fi


# Gettext stuff
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"], [Gettext Package])
AC_SUBST(GETTEXT_PACKAGE)
IT_PROG_INTLTOOL([0.40])


AC_CONFIG_FILES([
Makefile
src/Makefile
ui/Makefile
data/Makefile
data/org.baedert.corebird.desktop.in
data/256x256/Makefile
data/128x128/Makefile
data/96x96/Makefile
data/64x64/Makefile
data/48x48/Makefile
data/32x32/Makefile
data/24x24/Makefile
data/16x16/Makefile
po/Makefile.in
tests/Makefile
])


AC_OUTPUT

VALAC_VERSION=$($VALAC --version)

echo "
             Corebird  $VERSION
               Prefix: ${prefix}
        Vala Compiler: ${VALAC}
        valac version: ${VALAC_VERSION}
           C Compiler: ${CC} ${CFLAGS}
            Debugging: $enable_debug
       Video disabled: $disable_video
   Gst check disabled: $disable_gst_check
"
