
AM_CPPFLAGS = \
	$(CB_CFLAGS) \
	-I$(top_builddir)/src \
	-I$(top_srcdir)/src \
	-include $(CONFIG_HEADER) \
	-DDATADIR=\"$(datadir)\" \
	-DPKGDATADIR=\"$(pkgdatadir)\" \
	-D DEBUG

AM_VALAFLAGS = \
	--enable-checking \
	--enable-experimental \
	--vapidir $(top_builddir)/src \
	--vapidir $(top_srcdir)/vapi \
	--pkg corebird-internal \
	--enable-deprecated \
	--gresources $(top_srcdir)/corebird.gresource.xml \
	-C \
	-g



bin_PROGRAMS = tweetstates

tweetstates_vala.stamp:$(top_builddir)/src/libcorebird.la $(top_builddir)/src/corebird.vapi $(tweetstates_VALASOURCES) Makefile
	@$(VALAC) \
		$(AM_VALAFLAGS) $(CB_VALA_FLAGS) \
		--pkg corebird \
		$(filter %.vala %.c,$^)
	touch $@


resource_deps = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir) $(top_srcdir)/corebird.gresource.xml)
corebird-resources.c: $(top_srcdir)/corebird.gresource.xml $(resource_deps) Makefile
	XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --generate --sourcedir=$(top_srcdir) --c-name corebird $<


$(tweetstates_VALASOURCES:.vala=.c): tweetstates_vala.stamp



tweetstates_VALASOURCES = tweetstates.vala
tweetstates_SOURCES = \
	$(tweetstates_VALASOURCES:.vala=.c) \
	corebird-resources.c
tweetstates_LDADD = \
	$(CB_LIBS) \
	$(top_builddir)/src/libcorebird.la
