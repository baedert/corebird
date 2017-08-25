AC_INIT([corebird],[1.6],[mail@baedert.org])

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
AC_ARG_ENABLE(video, AS_HELP_STRING([--disable-video], [Disable video support]),, enable_video=yes)
AM_CONDITIONAL([DISABLE_VIDEO], [ test "$enable_video" != "yes"])

# --disable-gst-check
AC_ARG_ENABLE(gst_check, AS_HELP_STRING([--disable-gst-check], [Disable check for needed gstreamer elements]),, enable_gst_check=yes)
AM_CONDITIONAL([DISABLE_GST_CHECK], [ test "$enable_gst_check" != "yes"])

# --disable-spellcheck
AC_ARG_ENABLE(spellcheck, AS_HELP_STRING([--disable-spellcheck], [Disable spellchecking support]),, enable_spellcheck=yes)
AM_CONDITIONAL([DISABLE_SPELLCHECK], [ test "$enable_spellcheck" = "yes"])



pkg_modules="gtk+-3.0 >= 3.20
             glib-2.0 >= 2.44
             libsoup-2.4
             json-glib-1.0
             sqlite3"

if test "$enable_video" != "no"; then
  pkg_modules="$pkg_modules gstreamer-video-1.0 >= 1.6"
fi

if test "$enable_spellcheck" != "no"; then
  pkg_modules="$pkg_modules gspell-1 >= 1.0"
fi

PKG_CHECK_MODULES(CB, [$pkg_modules])

# We do this again for librest. TODO: Do this only once.
PKG_CHECK_MODULES(SOUP, libsoup-2.4 >= 2.42)
PKG_CHECK_MODULES(GLIB, glib-2.0 >= 2.38)


CB_VALA_FLAGS=" \
  --pkg gtk+-3.0 \
  --pkg json-glib-1.0 \
  --pkg sqlite3 \
  --pkg libsoup-2.4 \
  --pkg glib-2.0 \
  --target-glib=2.44"


AC_SUBST(CB_CFLAGS)
AC_SUBST(CB_LIBS)
AC_SUBST(CB_VALA_FLAGS)


# Check for valac >= 0.34, which binds gtk_popover_popup
# as well as if that function exists in gtk+
AM_PROG_VALAC([0.34.0], [
AC_CHECK_LIB([gtk-3], [gtk_popover_popup],
             [CB_VALA_FLAGS="$CB_VALA_FLAGS -D GTK322"],
            )
])

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

if test "$enable_video" != "no"; then
  CB_VALA_FLAGS="$CB_VALA_FLAGS \
                 -D VIDEO \
                 --pkg gstreamer-video-1.0"
  CB_CFLAGS="$CB_CFLAGS -D VIDEO"
fi

if test "$enable_debug" = "yes"; then
  CB_VALA_FLAGS="$CB_VALA_FLAGS -D DEBUG"
  CB_CFLAGS="$CB_CFLAGS -D DEBUG -D G_DISABLE_CAST_CHECKS"
fi

if test "$enable_spellcheck" != "no"; then
  CB_VALA_FLAGS="$CB_VALA_FLAGS -D SPELLCHECK --pkg gspell-1"
  CB_CFLAGS="$CB_CFLAGS -D SPELLCHECK"
fi

if test "$enable_gst_check" != "no"; then
  # Check for gtksink
  GST_ELEMENT_CHECK([gtksink], [1.0], [], [])
fi


# Gettext stuff
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"], [Gettext Package])
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.19.7])
AC_SUBST([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"])


AC_CONFIG_FILES([
Makefile
src/Makefile
data/Makefile
data/hicolor/Makefile
data/hicolor/256x256/Makefile
data/hicolor/256x256/apps/Makefile
data/hicolor/128x128/Makefile
data/hicolor/128x128/apps/Makefile
data/hicolor/96x96/Makefile
data/hicolor/96x96/apps/Makefile
data/hicolor/64x64/Makefile
data/hicolor/64x64/apps/Makefile
data/hicolor/48x48/Makefile
data/hicolor/48x48/apps/Makefile
data/hicolor/32x32/Makefile
data/hicolor/32x32/apps/Makefile
data/hicolor/24x24/Makefile
data/hicolor/24x24/apps/Makefile
data/hicolor/16x16/Makefile
data/hicolor/16x16/apps/Makefile
po/Makefile.in
tests/Makefile
])


AC_OUTPUT

VALAC_VERSION=$($VALAC --version)

echo "
                Corebird  $VERSION
                  Prefix: ${prefix}
           Vala Compiler: ${VALAC} ${CB_VALA_FLAGS}
           valac version: ${VALAC_VERSION}
              C Compiler: ${CC} ${CFLAGS}
               Debugging: $enable_debug
           Video enabled: $enable_video
       Gst check enabled: $enable_gst_check
   Spellchecking enabled: $enable_spellcheck
"
