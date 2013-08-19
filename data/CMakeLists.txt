install (FILES corebird.desktop            DESTINATION ${PREFIX}/share/applications/)

if (CATALOG)
  message ("CATALOG: ON")
  install (FILES corebird-catalog.xml DESTINATION ${PREFIX}/share/glade/catalogs/)
endif (CATALOG)

