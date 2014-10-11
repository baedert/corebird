CLEANFILES = *.o

# For some reason I can't use $(librest_@API_VERSION@_la_SOURCES) in
# test_runner_SOURCES, so we have to do this
lib_sources = \
	glib-compat.h			\
	glib-compat.c			\
	rest-param.c			\
	rest-params.c			\
	rest-proxy.c 			\
	rest-proxy-auth.c		\
	rest-proxy-auth-private.h	\
	rest-proxy-call.c		\
	rest-proxy-call-private.h	\
	rest-main.c			\
	rest-private.h			\
	rest-enum-types.c		\
	oauth-proxy.c			\
	oauth-proxy-call.c		\
	oauth-proxy-private.h 		\
	oauth2-proxy.c			\
	oauth2-proxy-call.c		\
	oauth2-proxy-private.h 		\
	sha1.c				\
	sha1.h
nodist_lib_sources = \
	rest-marshal.h		\
	rest-marshal.c
lib_headers = \
	rest-param.h		\
	rest-params.h		\
	rest-proxy.h		\
	rest-proxy-auth.h	\
	rest-proxy-call.h	\
	rest-enum-types.h	\
	oauth-proxy.h		\
	oauth-proxy-call.h	\
	oauth2-proxy.h		\
	oauth2-proxy-call.h

EXTRA_DIST = \
	rest-marshal.txt

lib_LTLIBRARIES = librest.la
librest_la_CFLAGS = $(GLIB_CFLAGS) $(GTHREAD_CFLAGS) \
		    $(SOUP_CFLAGS) \
		    -I$(top_srcdir)/librest/ -Wall -DG_LOG_DOMAIN=\"Rest\"
#librest_a_LDFLAGS = -no-undefined
librest_la_LIBADD = $(GLIB_LIBS) $(GTHREAD_LIBS) \
                    $(SOUP_LIBS)
librest_la_SOURCES = $(lib_headers) $(lib_sources)
nodist_librest_la_SOURCES = $(nodist_lib_sources)
librest_la_HEADERS = $(lib_headers)
librest_ladir = $(top_srcdir)/librest/rest

rest-enum-types.h: stamp-rest-enum-types.h
	@true

stamp-rest-enum-types.h: rest-proxy.h rest-proxy-call.h Makefile
	$(AM_V_GEN) (cd $(srcdir) && $(GLIB_MKENUMS) \
			--fhead "#ifndef __REST_ENUM_TYPES_H__\n#define __REST_ENUM_TYPES_H__\n\n#include <glib-object.h>\n\nG_BEGIN_DECLS\n" \
			--fprod "/* enumerations from \"@filename@\" */\n" \
			--vhead "GType @enum_name@_get_type (void) G_GNUC_CONST;\n#define REST_TYPE_@ENUMSHORT@ (@enum_name@_get_type())\n" \
			--ftail "G_END_DECLS\n\n#endif /* __REST_ENUM_TYPES_H__ */" rest-proxy.h rest-proxy-call.h) >> xgen-gtbh \
	&& (cmp -s xgen-gtbh rest-enum-types.h || cp xgen-gtbh rest-enum-types.h ) \
	&& rm -f xgen-gtbh \
	&& echo timestamp > $(@F)

rest-enum-types.c: rest-proxy.h rest-proxy-call.h Makefile rest-enum-types.h
	$(AM_V_GEN) (cd $(srcdir) && $(GLIB_MKENUMS) \
			--fhead "#include \"rest-proxy.h\"\n#include \"rest-proxy-call.h\"\n#include \"rest-enum-types.h\"" \
			--fprod "\n/* enumerations from \"@filename@\" */" \
			--vhead "GType\n@enum_name@_get_type (void)\n{\n  static GType etype = 0;\n  if (etype == 0) {\n    static const G@Type@Value values[] = {" \
			--vprod "      { @VALUENAME@, \"@VALUENAME@\", \"@valuenick@\" }," \
			--vtail "      { 0, NULL, NULL }\n    };\n    etype = g_@type@_register_static (\"@EnumName@\", values);\n  }\n  return etype;\n}\n" \
		rest-proxy.h rest-proxy-call.h) > xgen-gtbc \
	&& cp xgen-gtbc rest-enum-types.c  \
	&& rm -f xgen-gtbc

BUILT_SOURCES = rest-marshal.c rest-marshal.h

rest-marshal.c: rest-marshal.txt
	$(AM_V_GEN)echo "#include \"rest-marshal.h\"" > $@ && \
		glib-genmarshal --body $< >> $@ || (rm -f $@ && exit 1)

rest-marshal.h: rest-marshal.txt
	$(AM_V_GEN)glib-genmarshal --header $< > $@ || (rm -f $@ && exit 1)


