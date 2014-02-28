
SUBDIRS = symbolics

desktopdir = $(prefix)/share/applications
desktop_in_files = corebird.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

appdatadir = $(prefix)/share/appdata
appdata_in_files = corebird.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)
@INTLTOOL_XML_RULE@

if ENABLE_CATALOG
  catalogdir = $(prefix)/share/glade/catalogs/
  catalog_DATA = corebird-catalog.xml
endif

gsettings_SCHEMAS = org.baedert.corebird.gschema.xml



EXTRA_DIST = \
						 corebird.desktop.in \
						 $(desktop_in_files) \
						 $(appdata_in_files) \
						 org.baedert.corebird.gschema.xml 



DISTCLEANFILES = \
								 $(desktop_DATA) \
								 $(appdata_DATA)
