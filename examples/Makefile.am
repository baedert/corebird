
AM_CPPFLAGS = $(CB_CFLAGS) -I$(top_srcdir)/src

noinst_PROGRAMS = tle mm_widget ab_widget crop_dialog lle aib


tle_SOURCES = tle.vala resources.c
tle_LDADD = $(top_builddir)/src/libcorebird.la
tle_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

mm_widget_SOURCES = mm_widget.vala resources.c
mm_widget_LDADD = $(top_builddir)/src/libcorebird.la
mm_widget_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

ab_widget_SOURCES = ab_widget.vala resources.c
ab_widget_LDADD = $(top_builddir)/src/libcorebird.la
ab_widget_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

crop_dialog_SOURCES = crop_dialog.vala resources.c
crop_dialog_LDADD = $(top_builddir)/src/libcorebird.la
crop_dialog_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

lle_SOURCES = lle.vala resources.c
lle_LDADD = $(top_builddir)/src/libcorebird.la
lle_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

aib_SOURCES = aib.vala resources.c
aib_LDADD = $(top_builddir)/src/libcorebird.la
aib_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


GRESDEPS = $(top_srcdir)/$1 $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir) $(top_srcdir)/$1)
resource_deps = $(call GRESDEPS,resources.xml)
resources.c: $(resource_deps)
	$(GLIB_COMPILE_RESOURCES) $(top_srcdir)/resources.xml --target=resources.c --generate-source --sourcedir=$(top_srcdir)


EXTRA_DIST = tle.vala \
             mm_widget.vala \
             ab_widget.vala \
						 crop_dialog.vala \
						 lle.vala \
						 aib.vala
