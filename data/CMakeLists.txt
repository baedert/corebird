install (FILES corebird.desktop            DESTINATION ${PREFIX}/share/applications/)
install (FILES corebird.appdata.xml        DESTINATION ${PREFIX}/share/appdata/)

if (CATALOG)
  install (FILES corebird-catalog.xml DESTINATION ${PREFIX}/share/glade/catalogs/)
endif (CATALOG)

