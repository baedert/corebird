install (FILES corebird.desktop            DESTINATION ${PREFIX}/share/applications/)
install (FILES corebird.appdata.xml        DESTINATION ${PREFIX}/share/appdata/)
install (FILES corebird.1                  DESTINATION ${PREFIX}/share/man/man1/)

if (CATALOG)
  install (FILES corebird-catalog.xml DESTINATION ${PREFIX}/share/glade/catalogs/)
endif (CATALOG)

