AM_CPPFLAGS = $(CB_CFLAGS) -I$(top_srcdir)/src

TESTS = tweet_length media utils inthistory
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


CLEANFILES = *.c
