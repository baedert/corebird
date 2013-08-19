# Gettext support: Create/Update pot file and
#
# To use: INCLUDE(Gettext)
#
# Most of the gettext support code is from FindGettext.cmake of cmake,
# but it is included here because:
#
# 1. Some system like RHEL5 does not have FindGettext.cmake
# 2. Bug of GETTEXT_CREATE_TRANSLATIONS make it unable to be include in 'All'
# 3. It does not support xgettext
#
#===================================================================
# Constants:
#  XGETTEXT_OPTIONS_DEFAULT: Default xgettext option:
#===================================================================
# Variables:
#  XGETTEXT_OPTIONS: Options pass to xgettext
#      Default:  XGETTEXT_OPTIONS_DEFAULT
#  GETTEXT_MSGMERGE_EXECUTABLE: the full path to the msgmerge tool.
#  GETTEXT_MSGFMT_EXECUTABLE: the full path to the msgfmt tool.
#  GETTEXT_FOUND: True if gettext has been found.
#  XGETTEXT_EXECUTABLE: the full path to the xgettext.
#  XGETTEXT_FOUND: True if xgettext has been found.
#
#===================================================================
# Macros:
# GETTEXT_CREATE_POT(potFile
#    [OPTION xgettext_options]
#    SRC list_of_source_file_that_contains_msgid
# )
#
# Generate .pot file.
#    OPTION xgettext_options: Override XGETTEXT_OPTIONS
#
# * Produced targets: pot_file
#
#-------------------------------------------------------------------
# GETTEXT_CREATE_TRANSLATIONS ( outputFile [ALL] locale1 ... localeN
#     [COMMENT comment] )
#
#     This will create a target "translations" which will convert the
#     given input po files into the binary output mo file. If the
#     ALL option is used, the translations will also be created when
#     building the default target.
#
# * Produced targets: translations
#-------------------------------------------------------------------

FIND_PROGRAM(GETTEXT_MSGMERGE_EXECUTABLE msgmerge)
FIND_PROGRAM(GETTEXT_MSGFMT_EXECUTABLE msgfmt)
FIND_PROGRAM(GETTEXT_MSGCAT_EXECUTABLE msgcat)
FIND_PROGRAM(XGETTEXT_EXECUTABLE xgettext)

SET(XGETTEXT_OPTIONS_DEFAULT
    --language=C --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 -s
    --escape --add-comments="/" --package-name=${PROJECT_NAME} --package-version=${VERSION})

IF (GETTEXT_MSGMERGE_EXECUTABLE AND GETTEXT_MSGFMT_EXECUTABLE AND GETTEXT_MSGCAT_EXECUTABLE)
    SET(GETTEXT_FOUND TRUE)
ELSE (GETTEXT_MSGMERGE_EXECUTABLE AND GETTEXT_MSGFMT_EXECUTABLE)
    SET(GETTEXT_FOUND FALSE)
    IF (GetText_REQUIRED)
	MESSAGE(FATAL_ERROR "GetText not found")
    ENDIF (GetText_REQUIRED)
ENDIF (GETTEXT_MSGMERGE_EXECUTABLE AND GETTEXT_MSGFMT_EXECUTABLE AND GETTEXT_MSGCAT_EXECUTABLE)

IF(XGETTEXT_EXECUTABLE)
    SET(XGETTEXT_FOUND TRUE)
ELSE(XGETTEXT_EXECUTABLE)
    MESSAGE(STATUS "xgettext not found.")
    SET(XGETTTEXT_FOUND FALSE)
ENDIF(XGETTEXT_EXECUTABLE)

IF(NOT DEFINED XGETTEXT_OPTIONS)
    SET(XGETTEXT_OPTIONS ${XGETTEXT_OPTIONS_DEFAULT})
ENDIF(NOT DEFINED XGETTEXT_OPTIONS)

IF(XGETTEXT_FOUND)
    MACRO(GETTEXT_CREATE_POT _potFile _pot_options )
	SET(_xgettext_options_list)
	SET(_src_list)
	SET(_src_list_abs)
	SET(_glade_list)
	SET(_glade_list_abs)
	SET(_stage "SRC")
	FOREACH(_pot_option ${_pot_options} ${ARGN})
		IF(_pot_option STREQUAL "OPTION")
			SET(_stage "OPTION")
		ELSEIF(_pot_option STREQUAL "SRC")
			SET(_stage "SRC")
		ELSEIF(_pot_option STREQUAL "GLADE")
			SET(_stage "GLADE")
		ELSE(_pot_option STREQUAL "OPTION")
			IF(_stage STREQUAL "OPTION")
				SET(_xgettext_options_list ${_xgettext_options_list} ${_pot_option})
			ELSEIF(_stage STREQUAL "GLADE")
				FILE(RELATIVE_PATH _relFile ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_SOURCE_DIR}/${_pot_option})
				GET_FILENAME_COMPONENT(_absFile ${_pot_option} ABSOLUTE)
				SET(_glade_list ${_glade_list} ${_relFile})
				SET(_glade_list_abs ${_glade_list_abs} ${_absFile})
			ELSEIF(_stage STREQUAL "SRC")
				FILE(RELATIVE_PATH _relFile ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${_pot_option})
				GET_FILENAME_COMPONENT(_absFile ${_pot_option} ABSOLUTE)
				SET(_src_list ${_src_list} ${_relFile})
				SET(_src_list_abs ${_src_list_abs} ${_absFile})
			ENDIF(_stage STREQUAL "OPTION")
		ENDIF(_pot_option STREQUAL "OPTION")
	ENDFOREACH(_pot_option ${_pot_options} ${ARGN})

	IF (_xgettext_options_list)
	    SET(_xgettext_options ${_xgettext_options_list})
	ELSE(_xgettext_options_list)
	    SET(_xgettext_options ${XGETTEXT_OPTIONS})
	ENDIF(_xgettext_options_list)

	#MESSAGE("${XGETTEXT_EXECUTABLE} ${_xgettext_options_list} -o ${_potFile} ${_src_list}")
	ADD_CUSTOM_COMMAND(OUTPUT pot_file
	    COMMAND ${XGETTEXT_EXECUTABLE} ${_xgettext_options} -o ${_potFile} ${_src_list}
	    DEPENDS ${_src_list_abs} ${GLADE_FILES}
	    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
	    )

	ADD_CUSTOM_TARGET(pot_file
	    COMMAND ${XGETTEXT_EXECUTABLE} ${_xgettext_options_list} -o _source.pot ${_src_list}
	    COMMAND ${XGETTEXT_EXECUTABLE} --language=Glade --omit-header -o _glade.pot ${_glade_list}
	    COMMAND ${GETTEXT_MSGCAT_EXECUTABLE} -o ${_potFile} --use-first _source.pot _glade.pot
	    DEPENDS ${_src_list_abs}
	    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
	    COMMENT "Extract translatable messages to ${_potFile}"
	    )
    ENDMACRO(GETTEXT_CREATE_POT _potFile _pot_options)


    MACRO(GETTEXT_CREATE_TRANSLATIONS _potFile _firstLang)
	SET(_gmoFiles)
	GET_FILENAME_COMPONENT(_potBasename ${_potFile} NAME_WE)
	GET_FILENAME_COMPONENT(_absPotFile ${_potFile} ABSOLUTE)

	SET(_addToAll)
	SET(_is_comment FALSE)

	FOREACH (_currentLang ${_firstLang} ${ARGN})
	    IF(_currentLang STREQUAL "ALL")
		SET(_addToAll "ALL")
	    ELSEIF(_currentLang STREQUAL "COMMENT")
		SET(_is_comment TRUE)
	    ELSEIF(_is_comment)
		SET(_is_comment FALSE)
		SET(_comment ${_currentLang})
	    ELSE()
		SET(_lang ${_currentLang})
		GET_FILENAME_COMPONENT(_absFile ${_currentLang}.po ABSOLUTE)
		GET_FILENAME_COMPONENT(_abs_PATH ${_absFile} PATH)
		SET(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_lang}.mo)

		#MESSAGE("_absFile=${_absFile} _abs_PATH=${_abs_PATH} _lang=${_lang} curr_bin=${CMAKE_CURRENT_BINARY_DIR}")
		ADD_CUSTOM_COMMAND(
		    OUTPUT ${_gmoFile}
		    COMMAND ${GETTEXT_MSGMERGE_EXECUTABLE} --quiet --update --backup=none -s ${_absFile} ${_absPotFile}
		    COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} -o ${_gmoFile} ${_absFile}
		    DEPENDS ${_absPotFile} ${_absFile}
		    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		    )

		INSTALL(FILES ${_gmoFile} DESTINATION share/locale/${_lang}/LC_MESSAGES RENAME ${_potBasename}.mo)
		SET(_gmoFiles ${_gmoFiles} ${_gmoFile})
	    ENDIF()
	ENDFOREACH (_currentLang )

	IF(DEFINED _comment)
	    ADD_CUSTOM_TARGET(translations ${_addToAll} DEPENDS ${_gmoFiles} COMMENT ${_comment})
	ELSE(DEFINED _comment)
	    ADD_CUSTOM_TARGET(translations ${_addToAll} DEPENDS ${_gmoFiles})
	ENDIF(DEFINED _comment)
    ENDMACRO(GETTEXT_CREATE_TRANSLATIONS )
ENDIF(XGETTEXT_FOUND)



