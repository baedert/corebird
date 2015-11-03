AM_CPPFLAGS = \
	$(CB_CFLAGS) \
	-I$(top_builddir)/src \
	-include $(CONFIG_HEADER) \
	-DDATADIR=\"$(datadir)\" \
	-DPKGDATADIR=\"$(pkgdatadir)\"

AM_VALAFLAGS = \
	--enable-checking \
	--enable-experimental \
	--vapidir $(top_builddir)/src \
	--vapidir $(top_srcdir)/vapi \
	--gresources $(top_srcdir)/corebird.gresource.xml \
	-C \
	-g

TESTS_ENVIRONMENT = GSETTINGS_SCHEMA_DIR=$(abs_top_builddir)/data

TESTS = \
	tweetmodel \
	tweet_length \
	utils \
	bundlehistory \
	usercounter \
	media \
	tweet_parsing \
	filters \
	highlighting \
	friends \
	texttransform

check_PROGRAMS = $(TESTS)

tests_VALASOURCES = \
	tweet_length.vala \
	inlinemediadownloader.vala \
	utils.vala \
	bundlehistory.vala \
	usercounter.vala \
	filters.vala \
	tweet_parsing.vala \
	highlighting.vala \
	friends.vala \
	tweetmodel.vala \
	texttransform.vala

$(tests_VALASOURCES:.vala=.c): tests_vala.stamp

tests_vala.stamp: $(tests_VALASOURCES) $(top_builddir)/src/libcorebird.la $(top_builddir)/src/corebird.vapi Makefile
	for s in $(filter %.vala,$^); do \
		$(VALAC) \
			$(AM_VALAFLAGS) $(CB_VALA_FLAGS) \
			--pkg corebird \
			$$s; \
	done; \
	touch $@

nodist_tweet_length_SOURCES = tweet_length.c
tweet_length_LDADD = $(top_builddir)/src/libcorebird.la

nodist_media_SOURCES = inlinemediadownloader.c
media_LDADD = $(top_builddir)/src/libcorebird.la

nodist_utils_SOURCES = utils.c
utils_LDADD = $(top_builddir)/src/libcorebird.la

nodist_bundlehistory_SOURCES = bundlehistory.c
bundlehistory_LDADD = $(top_builddir)/src/libcorebird.la

nodist_usercounter_SOURCES = usercounter.c ../src/corebird-resources.c
usercounter_LDADD = $(top_builddir)/src/libcorebird.la

nodist_filters_SOURCES = filters.c ../src/corebird-resources.c
filters_LDADD = $(top_builddir)/src/libcorebird.la

nodist_tweet_parsing_SOURCES = tweet_parsing.c ../src/corebird-resources.c
tweet_parsing_LDADD = $(top_builddir)/src/libcorebird.la

nodist_highlighting_SOURCES = highlighting.c
highlighting_LDADD = $(top_builddir)/src/libcorebird.la

nodist_friends_SOURCES = friends.c
friends_LDADD = $(top_builddir)/src/libcorebird.la

nodist_tweetmodel_SOURCES = tweetmodel.c
tweetmodel_LDADD = $(top_builddir)/src/libcorebird.la

nodist_texttransform_SOURCES = texttransform.c
texttransform_LDADD = $(top_builddir)/src/libcorebird.la

EXTRA_DIST = \
	$(tests_VALASOURCES)
