project('Corebird', ['vala', 'c'])

gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="corebird"', language: 'c')
add_global_arguments('-DDATADIR="' + get_option('datadir') + '"', language: 'c')
add_global_arguments('-DG_LOG_DOMAIN="corebird"', language: 'c')
add_global_arguments('--enable-deprecated', language: 'vala')

srcdir = include_directories('src')

glib_dep = dependency('glib-2.0')
gtk_dep  = dependency('gtk+-3.0')
json_dep = dependency('json-glib-1.0')
rest_dep = dependency('rest-0.7')
sql_dep  = dependency('sqlite3')
soup_dep = dependency('libsoup-2.4')

cb_deps = [
  glib_dep,
  gtk_dep,
  json_dep,
  rest_dep,
  sql_dep,
  soup_dep
]

enable_debug = get_option('enable-debug')
if (enable_debug)
  add_global_arguments('-DDEBUG', language: 'c')
  add_global_arguments('-D', 'DEBUG', language: 'vala')
endif

enable_video = get_option('enable-video')
if (enable_video)
  add_global_arguments('-DVIDEO', language: 'c')
  add_global_arguments('-D', 'VIDEO', language: 'vala')
  cb_deps += [dependency('gstreamer-video-1.0', version: '>= 1.6')]
endif

enable_spellcheck = get_option('enable-spellcheck')
if (enable_spellcheck)
  add_global_arguments('-DSPELLCHECK', language: 'c')
  add_global_arguments('-D', 'SPELLCHECK', language: 'vala')
  cb_deps += [dependency('gspell-1')]
endif


corebird_lib_sources = files([
  'src/Account.vala',
  'src/Corebird.vala',
  'src/DMManager.vala',
  'src/DMPage.vala',
  'src/DMThreadsPage.vala',
  'src/DefaultTimeline.vala',
  'src/DeltaUpdater.vala',
  'src/FavoritesTimeline.vala',
  'src/FilterPage.vala',
  'src/HomeTimeline.vala',
  'src/IMessageReceiver.vala',
  'src/IPage.vala',
  'src/ITwitterItem.vala',
  'src/ListStatusesPage.vala',
  'src/ListsPage.vala',
  'src/MainWidget.vala',
  'src/MainWindow.vala',
  'src/MentionsTimeline.vala',
  'src/NotificationManager.vala',
  'src/ProfilePage.vala',
  'src/SearchPage.vala',
  'src/Settings.vala',
  'src/SnippetManager.vala',
  'src/TweetInfoPage.vala',
  'src/Twitter.vala',
  'src/UserEventReceiver.vala',
  'src/UserStream.vala',
  'src/async/Collect.vala',
  'src/async/ComposeJob.vala',
  'src/list/AddListEntry.vala',
  'src/list/DMListEntry.vala',
  'src/list/DMThreadEntry.vala',
  'src/list/FilterListEntry.vala',
  'src/list/ListListEntry.vala',
  'src/list/NewListEntry.vala',
  'src/list/SnippetListEntry.vala',
  'src/list/StartConversationEntry.vala',
  'src/list/TweetListEntry.vala',
  'src/list/UserFilterEntry.vala',
  'src/list/UserListEntry.vala',
  'src/model/DMThreadsModel.vala',
  'src/model/TweetModel.vala',
  'src/sql/Database.vala',
  'src/sql/InsertStatement.vala',
  'src/sql/SelectStatement.vala',
  'src/sql/UpdateStatement.vala',
  'src/util/Benchmark.vala',
  'src/util/Bundle.vala',
  'src/util/BundleHistory.vala',
  'src/util/Dirs.vala',
  'src/util/TweetUtils.vala',
  'src/util/UserCompletion.vala',
  'src/util/UserUtils.vala',
  'src/util/Utils.vala',
  'src/util/WeakRef.vala',
  'src/widgets/AccountCreateWidget.vala',
  'src/widgets/AddImageButton.vala',
  'src/widgets/AspectImage.vala',
  'src/widgets/AvatarBannerWidget.vala',
  'src/widgets/AvatarWidget.vala',
  'src/widgets/BadgeRadioButton.vala',
  'src/widgets/CompletionTextView.vala',
  'src/widgets/ComposeImageManager.vala',
  'src/widgets/CropWidget.vala',
  'src/widgets/DMPlaceholderBox.vala',
  'src/widgets/DoubleTapButton.vala',
  'src/widgets/FollowButton.vala',
  'src/widgets/ImpostorWidget.vala',
  'src/widgets/LazyMenuButton.vala',
  'src/widgets/MaxSizeContainer.vala',
  'src/widgets/MediaButton.vala',
  'src/widgets/MediaVideoWidget.vala',
  'src/widgets/MultiMediaWidget.vala',
  'src/widgets/PixbufButton.vala',
  'src/widgets/ReplyEntry.vala',
  'src/widgets/ReplyIndicator.vala',
  'src/widgets/ScrollWidget.vala',
  'src/widgets/SurfaceProgress.vala',
  'src/widgets/TextButton.vala',
  'src/widgets/TweetListBox.vala',
  'src/widgets/UserListsWidget.vala',
  'src/window/AboutDialog.vala',
  'src/window/AccountDialog.vala',
  'src/window/ComposeTweetWindow.vala',
  'src/window/MediaDialog.vala',
  'src/window/ModifyFilterDialog.vala',
  'src/window/ModifySnippetDialog.vala',
  'src/window/SettingsDialog.vala',
  'src/window/UserListDialog.vala',

  # C Sources
  'src/CbTweet.c',
  'src/CbTweet.h',
  'src/CbTextTransform.c',
  'src/CbTextTransform.h',
  'src/CbMedia.c',
  'src/CbMedia.h',
  'src/CbMediaDownloader.c',
  'src/CbMediaDownloader.h',
  'src/CbTypes.c',
  'src/CbTypes.h',
  'src/CbUserCounter.h',
  'src/CbUserCounter.c',
  'src/CbFilter.h',
  'src/CbFilter.c',
  'src/CbAvatarCache.h',
  'src/CbAvatarCache.c',
  'src/CbMediaImageWidget.h',
  'src/CbMediaImageWidget.c',
])

# glib resources
cb_resources = gnome.compile_resources(
  'corebird_resources',
  'corebird.gresource.xml',
)

# config.h
cdata = configuration_data()
configure_file(
  input : 'config.h.meson',
  output: 'config.h',
  configuration: cdata
)

# static library (for unit tests)
cb_lib = static_library(
  'libcorebird',
  corebird_lib_sources,
  cb_resources,
  dependencies: cb_deps,
  include_directories: srcdir,
  vala_args: [
    meson.source_root() + '/vapi/corebird-internal.vapi',
    meson.source_root() + '/vapi/config.vapi',
    '--vapidir=vapi/',
    '--target-glib=2.38',
    '--gresources=' + meson.source_root() + '/corebird.gresource.xml',
  ],
)
cb_dep = declare_dependency(
  link_with: cb_lib,
  dependencies: cb_deps,
  include_directories: [srcdir, include_directories('.')],
)


# actual executable
executable(
  'corebird',
  'src/main.vala',
  cb_resources,
  dependencies: [cb_deps, cb_dep],
  include_directories: srcdir,
  vala_args: [
    meson.source_root() + '/vapi/corebird-internal.vapi',
  ]
)

subdir('tests')
subdir('data')
