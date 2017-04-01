
tests = [
  'tweetmodel',
  'tweetlength',
  'utils',
  'bundlehistory',
  'usercounter',
  'inlinemediadownloader',
  'tweetparsing',
  'filters',
  'texttransform',
  'avatardownload',
  'avatarcache',
  'friends',
  'highlighting',
  'twitteritem'
]

foreach test_name : tests
  testcase = executable(
    test_name,
    test_name + '.vala',
    cb_resources,
    dependencies: cb_dep,
    vala_args: [
      meson.source_root() + '/vapi/corebird-internal.vapi',
      '--gresources=' + meson.source_root() + '/corebird.gresource.xml',
    ]
  )
  test(test_name, testcase)
endforeach
