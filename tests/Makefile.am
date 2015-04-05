AM_CPPFLAGS = $(CB_CFLAGS) -I$(top_srcdir)/src

TESTS = \
				tweet_length   \
				utils          \
				bundlehistory  \
				usercounter    \
				media          \
				tweet_parsing  \
				filters        \
				sql            \
				multimedia     \
				highlighting   \
				friends        \
				texttransform
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

bundlehistory_SOURCES = bundlehistory.vala
bundlehistory_LDADD = $(top_builddir)/src/libcorebird.la
bundlehistory_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

usercounter_SOURCES = usercounter.vala
usercounter_LDADD = $(top_builddir)/src/libcorebird.la
usercounter_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

filters_SOURCES = filters.vala resources.c
filters_LDADD = $(top_builddir)/src/libcorebird.la
filters_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

sql_SOURCES = sql.vala
sql_LDADD = $(top_builddir)/src/libcorebird.la
sql_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

tweet_parsing_SOURCES = tweet_parsing.vala resources.c
tweet_parsing_LDADD = $(top_builddir)/src/libcorebird.la
tweet_parsing_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

multimedia_SOURCES = multimedia.vala resources.c
multimedia_LDADD = $(top_builddir)/src/libcorebird.la
multimedia_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

highlighting_SOURCES = highlighting.vala
highlighting_LDADD = $(top_builddir)/src/libcorebird.la
highlighting_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

friends_SOURCES = friends.vala
friends_LDADD = $(top_builddir)/src/libcorebird.la
friends_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

texttransform_SOURCES = texttransform.vala
texttransform_LDADD = $(top_builddir)/src/libcorebird.la
texttransform_VALAFLAGS = $(top_builddir)/src/corebird.vapi @CB_VALA_FLAGS@

GRESDEPS = $(top_srcdir)/$1 $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir) $(top_srcdir)/$1)
resource_deps = $(call GRESDEPS,resources.xml)
resources.c: $(resource_deps)
	$(GLIB_COMPILE_RESOURCES) $(top_srcdir)/resources.xml --target=resources.c --generate-source --sourcedir=$(top_srcdir)


CLEANFILES = *.c
