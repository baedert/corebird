SUBDIRS = rest

%-$(API_VERSION).pc: %.pc
	$(AM_V_GEN)cp $< $@

pkgconfigdir   = $(libdir)/pkgconfig
pkgconfig_DATA = rest.pc

CLEANFILES = $(pkgconfig_DATA)

DISTCHECK_CONFIGURE_FLAGS = --enable-gtk-doc

ACLOCAL_AMFLAGS = -I build ${ACLOCAL_FLAGS}

all-local: rest.pc
