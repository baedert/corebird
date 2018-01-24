
tests = [
  'avatarcache',
  'avatardownload',
  'bundlehistory',
  'dmmanager',
  'filters',
  'friends',
  'inlinemediadownloader',
  'texttransform',
  'tweetmodel',
  'tweetparsing',
  'twitteritem',
  'usercompletionmodel',
  'usercounter',
  'utils',
]

foreach test_name : tests
  testcase = executable(
    test_name,
    test_name + '.vala',
    meson.source_root() + '/vapi/corebird-internal.vapi',
    meson.source_root() + '/vapi/gd-model-list-box.vapi',
    meson.source_root() + '/vapi/rest-0.7.vapi',
    cb_resources,
    dependencies: cb_dep,
    vala_args: [
      '--gresources=' + meson.source_root() + '/corebird.gresource.xml',
    ],
  )
  test(test_name, testcase)
endforeach
