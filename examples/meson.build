executable('tweetstates',
  'tweetstates.vala',
  cb_resources,
  dependencies: cb_dep,
  vala_args: [
    meson.source_root() + '/vapi/corebird-internal.vapi',
    meson.source_root() + '/vapi/rest-0.7.vapi',
    '--gresources=' + meson.source_root() + '/corebird.gresource.xml',
  ]
)
