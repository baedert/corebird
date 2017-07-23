CLEANFILES =

lib_sources = \
	rest-param.c			\
	rest-params.c			\
	rest-proxy.c 			\
	rest-proxy-auth.c		\
	rest-proxy-auth-private.h	\
	rest-proxy-call.c		\
	rest-proxy-call-private.h	\
	rest-main.c			\
	rest-private.h			\
	oauth-proxy.c			\
	oauth-proxy-call.c		\
	oauth-proxy-private.h 		\
	oauth2-proxy.c			\
	oauth2-proxy-call.c		\
	oauth2-proxy-private.h 		\
	sha1.c				\
	sha1.h
lib_headers = \
	rest-param.h		\
	rest-params.h		\
	rest-proxy.h		\
	rest-proxy-auth.h	\
	rest-proxy-call.h	\
	oauth-proxy.h		\
	oauth-proxy-call.h	\
	oauth2-proxy.h		\
	oauth2-proxy-call.h

EXTRA_DIST = \
	rest-marshal.txt

lib_LTLIBRARIES = librest.la
librest_la_CFLAGS = $(GLIB_CFLAGS) $(GTHREAD_CFLAGS) \
		    $(SOUP_CFLAGS)
		    -I$(top_srcdir) -Wall -DG_LOG_DOMAIN=\"Rest\"
librest_la_LDFLAGS = -no-undefined
librest_la_LIBADD = $(GLIB_LIBS) $(GTHREAD_LIBS) \
                    $(SOUP_LIBS)
librest_la_SOURCES = $(lib_sources) $(lib_headers)
nodist_librest_la_SOURCES = $(nodist_lib_sources)
librest_la_HEADERS = $(lib_headers)
librest_ladir = $(includedir)/rest/rest

# Test suite
TESTS = test-runner
check_PROGRAMS = test-runner

test_runner_SOURCES = test-runner.c $(lib_sources) $(nodist_lib_sources) $(lib_headers)
test_runner_CFLAGS = -DBUILD_TESTS $(librest__la_CFLAGS) $(GCOV_CFLAGS)
test_runner_LDFLAGS = $(librest_la_LIBADD) $(GCOV_LDFLAGS)
