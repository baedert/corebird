#!/bin/sh

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

ORIGDIR=`pwd`
cd $srcdir

# Automake requires that ChangeLog exist.
touch ChangeLog
touch config.rpath
mkdir -p m4

rm -f .version
AUTOPOINT='intltoolize --automake --copy' autoreconf -v --install --force || exit 1
cd $ORIGDIR || exit $?

if test -z "$NOCONFIGURE"; then
    $srcdir/configure "$@"
fi

