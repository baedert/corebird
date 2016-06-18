AM_CPPFLAGS = \
	$(CB_CFLAGS) \
	-I$(top_builddir)/src \
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
	avatardownload.vala

C_SOURCES = $(top_builddir)/src/Types.c \
	$(top_builddir)/src/Media.c \
	$(top_builddir)/src/MediaDownloader.c \
	$(top_builddir)/src/TextTransform.c

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

nodist_tweetmodel_SOURCES = tweetmodel.c $(C_SOURCES)
tweetmodel_LDADD = $(top_builddir)/src/libcorebird.la

nodist_tweetlength_SOURCES = tweetlength.c $(C_SOURCES)
tweetlength_LDADD = $(top_builddir)/src/libcorebird.la

nodist_utils_SOURCES = utils.c $(C_SOURCES)
utils_LDADD = $(top_builddir)/src/libcorebird.la

nodist_bundlehistory_SOURCES = bundlehistory.c $(C_SOURCES)
bundlehistory_LDADD = $(top_builddir)/src/libcorebird.la

nodist_usercounter_SOURCES = usercounter.c ../src/corebird-resources.c $(C_SOURCES)
usercounter_LDADD = $(top_builddir)/src/libcorebird.la

nodist_inlinemediadownloader_SOURCES = inlinemediadownloader.c $(C_SOURCES)
inlinemediadownloader_LDADD = $(top_builddir)/src/libcorebird.la

nodist_tweetparsing_SOURCES = tweetparsing.c ../src/corebird-resources.c $(C_SOURCES)
tweetparsing_LDADD = $(top_builddir)/src/libcorebird.la

nodist_filters_SOURCES = filters.c ../src/corebird-resources.c $(C_SOURCES)
filters_LDADD = $(top_builddir)/src/libcorebird.la

nodist_highlighting_SOURCES = highlighting.c $(C_SOURCES)
highlighting_LDADD = $(top_builddir)/src/libcorebird.la

nodist_friends_SOURCES = friends.c $(C_SOURCES)
friends_LDADD = $(top_builddir)/src/libcorebird.la

nodist_texttransform_SOURCES = texttransform.c $(C_SOURCES)
texttransform_LDADD = $(top_builddir)/src/libcorebird.la

nodist_avatardownload_SOURCES = avatardownload.c ../src/corebird-resources.c $(C_SOURCES)
avatardownload_LDADD = $(top_builddir)/src/libcorebird.la

EXTRA_DIST = \
	$(tests_VALASOURCES)
