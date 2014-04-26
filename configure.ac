AC_INIT([corebird],[0.7],[mail@baedert.org])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([foreign no-dist-gzip dist-bzip2])

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

#AM_MAINTAINER_MODE

LT_INIT
AC_PROG_CC
AC_PROG_CC_STDC
AM_PROG_VALAC([0.24])
AC_PROG_INSTALL
IT_PROG_INTLTOOL([0.40])


# Vala Packages {{{
pkg_modules="gtk+-3.0 >= 3.10
             glib-2.0 >= 2.40
             rest-0.7
             libsoup-2.4
             gee-0.8
             json-glib-1.0
             sqlite3"
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
  --gresources=../resources.xml \
  --vapidir=../vapi/ \
  --thread \
  --enable-checking"
# }}}

AC_SUBST(CB_CFLAGS)
AC_SUBST(CB_LIBS)
AC_SUBST(CB_VALA_FLAGS)

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)



# --enable-catalog
AC_ARG_ENABLE(catalog, AC_HELP_STRING([--enable-catalog], [Install Glade catalog]),, enable_catalog=no)
AM_CONDITIONAL([ENABLE_CATALOG], [ test "$enable_catalog" = "yes" ])

# --enable-debug
AC_ARG_ENABLE(debug, AS_HELP_STRING([--enable-debug], [Enable debugging]),, enable_debug=no)
AM_CONDITIONAL([ENABLE_DEBUG], [ test "$enable_debug" = "yes"])

if test "$enable_debug" = "yes"; then
  CB_VALA_FLAGS="$CB_VALA_FLAGS -D DEBUG"
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
                 data/symbolics/Makefile
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

echo "
             Corebird  $VERSION
               Prefix: ${prefix}
        Vala Compiler: ${VALAC}
           C Compiler: ${CC} ${CFLAGS}
              Catalog: $enable_catalog
            Debugging: $enable_debug
"
