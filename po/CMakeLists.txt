
set (TRANSLATED
	en_US
)


IF (XGETTEXT_FOUND)
    GETTEXT_CREATE_TRANSLATIONS(${GETTEXT_PACKAGE}.pot ALL ${TRANSLATED}
	    COMMENT "Creating translations.")
ELSE ()
    message(STATUS "xgettext not found")
ENDIF()