
AM_CPPFLAGS = \
	$(CB_CFLAGS) \
	-I$(top_builddir)/src \
	-I$(top_srcdir)/src \
	-include $(CONFIG_HEADER) \
	-DDATADIR=\"$(datadir)\" \
	-DPKGDATADIR=\"$(pkgdatadir)\" \
	-D DEBUG

AM_VALAFLAGS = \
	$(CB_VALA_FLAGS) \
	--enable-checking \
	--enable-experimental \
	--vapidir $(top_builddir)/src \
	--vapidir $(top_srcdir)/vapi \
	--pkg corebird-internal \
	--pkg corebird \
	--enable-deprecated \
	--gresources $(top_srcdir)/corebird.gresource.xml \
	-C \
	-g

resource_deps = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir) $(top_srcdir)/corebird.gresource.xml)
corebird-resources.c: $(top_srcdir)/corebird.gresource.xml $(resource_deps) Makefile
	XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --generate --sourcedir=$(top_srcdir) --c-name corebird $<


noinst_bin_PROGRAMS = \
	tweetstates \
	accountdialog

noinst_bindir = $(abs_top_builddir)

tweetstates_SOURCES = tweetstates.vala corebird-resources.c
tweetstates_LDADD = $(CB_LIBS) $(top_builddir)/src/libcorebird.la

accountdialog_SOURCES = accountdialog.vala corebird-resources.c
accountdialog_LDADD = $(CB_LIBS) $(top_builddir)/src/libcorebird.la

CLEANFILES = corebird-resources.c
