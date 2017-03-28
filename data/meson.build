i18n = import('i18n')

install_data(
  'org.baedert.corebird.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)
meson.add_install_script('meson_post_install.py')

i18n.merge_file(
  input:  'org.baedert.corebird.desktop.in',
  output: 'org.baedert.corebird.desktop',
  po_dir: '../po/',
  type:   'desktop',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)
i18n.merge_file(
  input:  'org.baedert.corebird.appdata.xml.in',
  output: 'org.baedert.corebird.appdata.xml',
  po_dir: '../po/',
  type:   'xml',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'appdata')
)

install_man('corebird.1')

# Install all application icons in one go
# TODO: This will unfortunately also install the Makefile{.am} files which are still in hicolor/...
install_subdir(
  'hicolor',
  install_dir: join_paths(get_option('datadir'), 'icons')
)
