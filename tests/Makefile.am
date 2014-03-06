AM_CPPFLAGS = $(CB_CFLAGS) -I$(top_srcdir)/src

TESTS = check_test
check_PROGRAMS = $(TESTS)

check_test_SOURCES = check_test.vala
check_test_LDADD = $(top_builddir)/src/libcorebird.la
check_test_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@


CLEANFILES = *.c
