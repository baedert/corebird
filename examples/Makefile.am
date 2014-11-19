
AM_CPPFLAGS = $(CB_CFLAGS) -I$(top_srcdir)/src

noinst_PROGRAMS = tle mm_widget ab_widget crop_dialog lle aib


tle_SOURCES = tle.vala $(top_srcdir)/src/resources.c
tle_LDADD = $(top_builddir)/src/libcorebird.la
tle_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


mm_widget_SOURCES = mm_widget.vala $(top_srcdir)/src/resources.c
mm_widget_LDADD = $(top_builddir)/src/libcorebird.la
mm_widget_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

ab_widget_SOURCES = ab_widget.vala $(top_srcdir)/src/resources.c
ab_widget_LDADD = $(top_builddir)/src/libcorebird.la
ab_widget_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


crop_dialog_SOURCES = crop_dialog.vala $(top_srcdir)/src/resources.c
crop_dialog_LDADD = $(top_builddir)/src/libcorebird.la
crop_dialog_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


lle_SOURCES = lle.vala $(top_srcdir)/src/resources.c
lle_LDADD = $(top_builddir)/src/libcorebird.la
lle_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

aib_SOURCES = aib.vala $(top_srcdir)/src/resources.c
aib_LDADD = $(top_builddir)/src/libcorebird.la
aib_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


EXTRA_DIST = tle.vala \
             mm_widget.vala \
             ab_widget.vala \
						 crop_dialog.vala \
						 lle.vala \
						 aib.vala
