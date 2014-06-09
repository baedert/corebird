AUTOMAKE_OPTIONS = subdir-objects

AM_CPPFLAGS = $(CB_CFLAGS) -I$(top_srcdir)/src

bin_PROGRAMS = tle mm_widget


tle_SOURCES = tle.vala $(top_srcdir)/src/resources.c
tle_LDADD = $(top_builddir)/src/libcorebird.la
tle_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


mm_widget_SOURCES = mm_widget.vala $(top_srcdir)/src/resources.c
mm_widget_LDADD = $(top_builddir)/src/libcorebird.la
mm_widget_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@
