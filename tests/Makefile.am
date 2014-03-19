AM_CPPFLAGS = $(CB_CFLAGS) -I$(top_srcdir)/src

TESTS = \
				tweet_length   \
				media utils    \
				inthistory     \
				usercounter    \
				tweet_entities
check_PROGRAMS = $(TESTS)

tweet_length_SOURCES = tweet_length.vala
tweet_length_LDADD = $(top_builddir)/src/libcorebird.la
tweet_length_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


media_SOURCES = inlinemediadownloader.vala
media_LDADD = $(top_builddir)/src/libcorebird.la
media_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


utils_SOURCES = utils.vala
utils_LDADD = $(top_builddir)/src/libcorebird.la
utils_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


inthistory_SOURCES = inthistory.vala
inthistory_LDADD = $(top_builddir)/src/libcorebird.la
inthistory_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

usercounter_SOURCES = usercounter.vala
usercounter_LDADD = $(top_builddir)/src/libcorebird.la
usercounter_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


tweet_entities_SOURCES = tweet_entities.vala
tweet_entities_LDADD = $(top_builddir)/src/libcorebird.la
tweet_entities_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


CLEANFILES = *.c
