ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = src ui data assets po tests sql
EXTRA_DIST = config.rpath  \
						 intltool-extract.in \
						 intltool-merge.in \
						 intltool-update.in \
						 resources.xml

DISTCLEANFILES = \
								 intltool-extract \
								 intltool-merge \
								 intltool-update \
								 po/.intltool-merge-cache

AUTOMAKE_OPTIONS = subdir-objects
