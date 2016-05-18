ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = src ui data po tests

EXTRA_DIST = \
	vapi/config.vapi \
	vapi/gstreamer-1.0.vapi \
	corebird.gresource.xml


update-translations: po/corebird.pot
	@tx pull --all --force --skip
	@tx push --source
