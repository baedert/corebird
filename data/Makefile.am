iconprefix=$(datarootdir)/icons/hicolor/
SUBDIRS = 256x256 128x128 96x96 64x64 48x48 32x32 24x24 16x16

desktopdir = $(datarootdir)/applications
desktop_in_files = org.baedert.corebird.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

appdatadir = $(datarootdir)/appdata
appdata_in_files = org.baedert.corebird.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)
@INTLTOOL_XML_RULE@

man_MANS = corebird.1

gsettings_SCHEMAS = org.baedert.corebird.gschema.xml
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

gschemas.compiled: Makefile $(gsettings_SCHEMAS:.xml=.valid)
	$(AM_V_GEN) $(GLIB_COMPILE_SCHEMAS) --targetdir=$(builddir) $(builddir)


dbusservicedir = $(datadir)/dbus-1/services
dbusservice_DATA = org.baedert.corebird.service

org.baedert.corebird.service: Makefile
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
		echo 'Name=org.baedert.corebird'; \
		echo 'Exec=${bindir}/corebird --gapplication-service') > $@.tmp && \
		mv $@.tmp $@


EXTRA_DIST = \
	$(desktop_in_files) \
	$(appdata_in_files) \
	org.baedert.corebird.gschema.xml.in \
	$(man_MANS)

CLEANFILES = \
	$(gsettings_SCHEMAS) \
	gschemas.compiled \
	org.baedert.corebird.gschema.valid \
	$(desktop_DATA) \
	$(dbusservice_DATA) \
	$(appdata_DATA)

all-local: gschemas.compiled
