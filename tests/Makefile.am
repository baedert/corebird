AM_CPPFLAGS = \
	$(CB_CFLAGS) \
	-I$(top_builddir)/src \
	-I$(top_srcdir)/src \
	-include $(CONFIG_HEADER) \
	-DDATADIR=\"$(datadir)\" \
	-DPKGDATADIR=\"$(pkgdatadir)\" \
	-g \
	-O0 \
	-Wno-inline \
	-D DEBUG

AM_VALAFLAGS = \
	--enable-checking \
	--enable-experimental \
	--vapidir $(top_builddir)/src \
	--vapidir $(top_srcdir)/vapi \
	--pkg corebird-internal \
	--gresources $(top_srcdir)/corebird.gresource.xml \
	-C \
	-g

TESTS_ENVIRONMENT = GSETTINGS_SCHEMA_DIR=$(abs_top_builddir)/data

TESTS = \
	tweetmodel \
	tweetlength \
	utils \
	bundlehistory \
	usercounter \
	inlinemediadownloader \
	tweetparsing \
	filters \
	texttransform \
	avatardownload \
	friends \
	highlighting

check_PROGRAMS = $(TESTS)

tests_VALASOURCES = \
	tweetmodel.vala \
	tweetlength.vala \
	utils.vala \
	bundlehistory.vala \
	usercounter.vala \
	inlinemediadownloader.vala \
	tweetparsing.vala \
	filters.vala \
	texttransform.vala \
	avatardownload.vala \
	friends.vala \
	highlighting.vala

$(tests_VALASOURCES:.vala=.c): tests_vala.stamp

tests_vala.stamp: $(tests_VALASOURCES) $(top_builddir)/src/libcorebird.la $(top_builddir)/src/corebird.vapi Makefile
	for s in $(filter %.vala,$^); do \
		$(VALAC) \
			$(AM_VALAFLAGS) $(CB_VALA_FLAGS) \
			--pkg corebird \
			--enable-deprecated \
			$$s; \
	done; \
	touch $@

resource_deps = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir) $(top_srcdir)/corebird.gresource.xml)
corebird-resources.c: $(top_srcdir)/corebird.gresource.xml $(resource_deps) Makefile
	XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --generate --sourcedir=$(top_srcdir) --c-name corebird $<



nodist_tweetmodel_SOURCES = tweetmodel.c
tweetmodel_LDADD = $(top_builddir)/src/libcorebird.la

nodist_tweetlength_SOURCES = tweetlength.c
tweetlength_LDADD = $(top_builddir)/src/libcorebird.la

nodist_utils_SOURCES = utils.c
utils_LDADD = $(top_builddir)/src/libcorebird.la

nodist_bundlehistory_SOURCES = bundlehistory.c
bundlehistory_LDADD = $(top_builddir)/src/libcorebird.la

nodist_usercounter_SOURCES = usercounter.c corebird-resources.c
usercounter_LDADD = $(top_builddir)/src/libcorebird.la

nodist_inlinemediadownloader_SOURCES = inlinemediadownloader.c
inlinemediadownloader_LDADD = $(top_builddir)/src/libcorebird.la

nodist_tweetparsing_SOURCES = tweetparsing.c corebird-resources.c
tweetparsing_LDADD = $(top_builddir)/src/libcorebird.la

nodist_filters_SOURCES = filters.c corebird-resources.c
filters_LDADD = $(top_builddir)/src/libcorebird.la

nodist_highlighting_SOURCES = highlighting.c
highlighting_LDADD = $(top_builddir)/src/libcorebird.la

nodist_friends_SOURCES = friends.c corebird-resources.c
friends_LDADD = $(top_builddir)/src/libcorebird.la

nodist_texttransform_SOURCES = texttransform.c
texttransform_LDADD = $(top_builddir)/src/libcorebird.la

nodist_avatardownload_SOURCES = avatardownload.c corebird-resources.c
avatardownload_LDADD = $(top_builddir)/src/libcorebird.la

CLEANFILES = \
	tests_vala.stamp \
	corebird-resources.c \
	$(tests_VALASOURCES:.vala=.c)

EXTRA_DIST = \
	$(tests_VALASOURCES)
