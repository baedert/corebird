executable('tweetstates',
  'tweetstates.vala',
  cb_resources,
  dependencies: cb_dep,
  vala_args: [
    meson.source_root() + '/vapi/corebird-internal.vapi',
    '--gresources=' + meson.source_root() + '/corebird.gresource.xml',
  ]
)
