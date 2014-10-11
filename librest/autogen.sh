#!/bin/sh

set -e

test -n "$srcdir" || srcdir=`dirname "$0"`
test -n "$srcdir" || srcdir=.

olddir=`pwd`
cd "$srcdir"

GTKDOCIZE=`which gtkdocize`
if test -z $GTKDOCIZE; then
  echo "*** No gtk-doc support ***"
  echo "EXTRA_DIST =" > gtk-doc.make
  echo "CLEANFILES =" >> gtk-doc.make
else
  gtkdocize --flavour no-tmpl || exit 1
fi

ACLOCAL="${ACLOCAL-aclocal} $ACLOCAL_FLAGS" autoreconf -v -i

cd "$olddir"

test -n "$NOCONFIGURE" || "$srcdir/configure" "$@"
