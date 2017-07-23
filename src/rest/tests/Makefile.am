TESTS = proxy proxy-continuous threaded oauth oauth-async oauth2 flickr lastfm xml custom-serialize
# TODO: fix this test case
XFAIL_TESTS = xml

AM_CPPFLAGS = $(SOUP_CFLAGS) -I$(top_srcdir) $(GCOV_CFLAGS)
AM_LDFLAGS = $(SOUP_LIBS) $(GCOV_LDFLAGS) \
	     ../rest/librest-@API_VERSION@.la ../rest-extras/librest-extras-@API_VERSION@.la

check_PROGRAMS = $(TESTS)

proxy_SOURCES = proxy.c
proxy_continuous_SOURCES = proxy-continuous.c
threaded_SOURCES = threaded.c
oauth_SOURCES = oauth.c
oauth_async_SOURCES = oauth-async.c
oauth2_SOURCES = oauth2.c
flickr_SOURCES = flickr.c
lastfm_SOURCES = lastfm.c
xml_SOURCES = xml.c
custom_serialize_SOURCES = custom-serialize.c
