
include (Translations)

add_translations_directory("${GETTEXT_PACKAGE}")
add_translations_catalog("${GETTEXT_PACKAGE}"
	../src
	../src/widgets
	../src/util
	../ui
)

