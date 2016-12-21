

install_data(
  'org.baedert.corebird.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)
meson.add_install_script('meson_post_install.py')

# Install all application icons in one go
# TODO: This will unfortunately also install the Makefile{.am} files which are still in hicolor/...
install_subdir(
  'hicolor',
  install_dir: join_paths(get_option('datadir'), 'icons')
)
