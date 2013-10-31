

include(Gettext)
if(XGETTEXT_FOUND)
  set(potfile "${CMAKE_CURRENT_SOURCE_DIR}/corebird.pot")
  gettext_create_pot("${potfile}"
    SRCFILES
    "src/*.vala"
    "src/widgets/*.vala"
    "src/list/*.vala"
    "src/util/*.vala"
    "src/window/*.vala"
    GSETTINGSFILES
    "org.baedert.corebird.gschema.xml"
    GLADEFILES
    "ui/*.ui"
    WORKING_DIRECTORY
    "../"
    )
  option(UPDATE_PO "Update .po files." ON)
  if(UPDATE_PO)
    set(NOUPDATE)
  else()
    set(NOUPDATE "NOUPDATE")
  endif()
  gettext_create_translations("${potfile}" ALL ${NOUPDATE})
endif()
