AC_INIT([corebird],[1.0],[mail@baedert.org])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([foreign no-dist-gzip dist-bzip2])

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

#AM_MAINTAINER_MODE

LT_INIT
AC_PROG_CC
AC_PROG_CC_STDC
AM_PROG_VALAC([0.26])
AC_PROG_INSTALL
IT_PROG_INTLTOOL([0.40])






# --enable-debug
AC_ARG_ENABLE(debug, AS_HELP_STRING([--enable-debug], [Enable debugging]),, enable_debug=no)
AM_CONDITIONAL([ENABLE_DEBUG], [ test "$enable_debug" = "yes"])

# --disable-video
AC_ARG_ENABLE(video, AS_HELP_STRING([--disable-video], [Disable video support]),, disable_video=no)
AM_CONDITIONAL([DISABLE_VIDEO], [ test "$disable_video" = "yes"])




# Vala Packages {{{
pkg_modules="gtk+-3.0 >= 3.16
             glib-2.0 >= 2.44
             rest-0.7
             libsoup-2.4
             gee-0.8
             json-glib-1.0
             sqlite3"

if test "$disable_video" = "no"; then
  pkg_modules="$pkg_modules gstreamer-video-1.0 gdk-x11-3.0"
fi

PKG_CHECK_MODULES(CB, [$pkg_modules])


CB_VALA_FLAGS=" \
  --pkg gtk+-3.0 \
  --pkg json-glib-1.0 \
  --pkg rest-0.7 \
  --pkg gee-0.8 \
  --pkg sqlite3 \
  --pkg libsoup-2.4 \
  --pkg glib-2.0 \
  --target-glib=2.38 \
  --gresources=\$(top_srcdir)/resources.xml \
  --vapidir=\$(top_srcdir)/vapi/ \
  --thread \
  --enable-checking \
  --enable-experimental"


# }}}

AC_SUBST(CB_CFLAGS)
AC_SUBST(CB_LIBS)
AC_SUBST(CB_VALA_FLAGS)

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)


if test "${CC}" = "clang"; then
  CB_CFLAGS="$CB_CFLAGS -Wno-incompatible-pointer-types -Wno-incompatible-pointer-types-discards-qualifiers"
fi

if test "$disable_video" = "no"; then
  CB_VALA_FLAGS="$CB_VALA_FLAGS \
                 -D VIDEO \
                 --pkg gstreamer-video-1.0 \
                 --pkg gdk-x11-3.0"
fi

if test "$enable_debug" = "yes"; then
  CB_VALA_FLAGS="$CB_VALA_FLAGS -D DEBUG -g"
fi


GLIB_GSETTINGS


# Gettext stuff
GETTEXT_PACKAGE=corebird
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"], [Gettext Package])
AC_SUBST(GETTEXT_PACKAGE)
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.18.3])
AM_GLIB_GNU_GETTEXT



AC_CONFIG_FILES([Makefile
                 src/Makefile
                 ui/Makefile
                 data/Makefile
                 data/org.baedert.corebird.desktop.in
                 assets/Makefile
                 assets/128x128/Makefile
                 assets/96x96/Makefile
                 assets/64x64/Makefile
                 assets/48x48/Makefile
                 assets/32x32/Makefile
                 assets/24x24/Makefile
                 assets/16x16/Makefile
                 po/Makefile.in
                 sql/Makefile
                 sql/accounts/Makefile
                 sql/init/Makefile
                 tests/Makefile
                 src/util/Config.vala])


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
"
