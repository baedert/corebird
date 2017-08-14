
tests = [
  'avatarcache',
  'avatardownload',
  'bundlehistory',
  'filters',
  'friends',
  'highlighting',
  'inlinemediadownloader',
  'texttransform',
  'tweetlength',
  'tweetmodel',
  'tweetparsing',
  'twitteritem',
  'usercounter',
  'utils',
]

foreach test_name : tests
  testcase = executable(
    test_name,
    test_name + '.vala',
    meson.source_root() + '/vapi/corebird-internal.vapi',
    meson.source_root() + '/vapi/rest-0.7.vapi',
    cb_resources,
    dependencies: cb_dep,
    vala_args: [
      '--gresources=' + meson.source_root() + '/corebird.gresource.xml',
    ],
  )
  test(test_name, testcase)
endforeach
