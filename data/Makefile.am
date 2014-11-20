
SUBDIRS = symbolics

desktopdir = $(prefix)/share/applications
desktop_in_files = org.baedert.corebird.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

appdatadir = $(prefix)/share/appdata
appdata_in_files = org.baedert.corebird.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)
@INTLTOOL_XML_RULE@

man_MANS = corebird.1

gsettings_SCHEMAS = org.baedert.corebird.gschema.xml
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

EXTRA_DIST = \
						 org.baedert.corebird.desktop.in \
						 $(desktop_in_files) \
						 $(appdata_in_files) \
						 org.baedert.corebird.gschema.xml.in \
						 $(man_MANS)

DISTCLEANFILES = \
								 $(desktop_DATA) \
								 $(appdata_DATA)
