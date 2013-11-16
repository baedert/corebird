install (FILES corebird.desktop            DESTINATION ${PREFIX}/share/applications/)
install (FILES fontawesome-webfont.ttf     DESTINATION ${PREFIX}/share/fonts/TTF/)
install (FILES corebird.appdata.xml        DESTINATION ${PREFIX}/share/appdata/)

if (CATALOG)
  install (FILES corebird-catalog.xml DESTINATION ${PREFIX}/share/glade/catalogs/)
endif (CATALOG)

