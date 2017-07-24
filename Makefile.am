ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = src data po tests

EXTRA_DIST = \
	vapi/config.vapi \
	vapi/rest-0.7.vapi \
	vapi/corebird-internal.vapi \
	corebird.gresource.xml


update-translations: po/corebird.pot
	@tx pull --all --force --skip --minimum-perc=1
	@tx push --source
