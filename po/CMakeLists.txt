

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
    GLADEFILES
    "ui/*.ui"
    GSETTINGSFILES
    "org.baedert.corebird.gschema.xml"
    WORKING_DIRECTORY
    "../"
    )
  option(UPDATE_PO "Update .po files." ON)
  if(UPDATE_PO)
    set(NOUPDATE)
  else()
    set(NOUPDATE "NOUPDATE")
  endif()
  gettext_create_translations("${potfile}"
    ALL
    ${NOUPDATE}
    POFILES
    "de.po"
    "en_AU.po"
    "es.po"
    "nl.po"
    "zh_CN.po")
endif()
