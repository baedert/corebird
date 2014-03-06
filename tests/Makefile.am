AM_CPPFLAGS = $(CB_CFLAGS) -I$(top_srcdir)/src

TESTS = tweet_length
check_PROGRAMS = $(TESTS)

tweet_length_SOURCES = tweet_length.vala
tweet_length_LDADD = $(top_builddir)/src/libcorebird.la
tweet_length_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


CLEANFILES = *.c
