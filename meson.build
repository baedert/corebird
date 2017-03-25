project('Corebird', ['vala', 'c'],
        version: '1.4.2')

gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="corebird"', language: 'c')
add_global_arguments('-DDATADIR="' + get_option('datadir') + '"', language: 'c')
add_global_arguments('-DG_LOG_DOMAIN="corebird"', language: 'c')
add_global_arguments('--enable-deprecated', language: 'vala')
add_global_arguments('-D', 'GTK322', language: 'vala')

srcdir = include_directories('src')

min_glib_version = '2.44'

glib_dep = dependency('glib-2.0', version: '>=' + min_glib_version)
gtk_dep  = dependency('gtk+-3.0', version: '>=3.18')
json_dep = dependency('json-glib-1.0')
rest_dep = dependency('rest-0.7', version: '>=0.7.91')
sql_dep  = dependency('sqlite3')
soup_dep = dependency('libsoup-2.4')

if (rest_dep.version() >= '0.8.1')
  add_global_arguments('-D', 'REST081', language: 'vala')
  add_global_arguments('-DREST081', language: 'c')
endif

cb_deps = [
  glib_dep,
  gtk_dep,
  json_dep,
  rest_dep,
  sql_dep,
  soup_dep
]

enable_debug = get_option('debug')
if (enable_debug)
  add_global_arguments('-g', language: 'c')
  add_global_arguments('-DDEBUG', language: 'c')
  add_global_arguments('-DG_DISABLE_CAST_CHECKS', language: 'c')
  add_global_arguments('-D', 'DEBUG', language: 'vala')
endif

enable_video = get_option('video')
if (enable_video)
  add_global_arguments('-DVIDEO', language: 'c')
  add_global_arguments('-D', 'VIDEO', language: 'vala')
  cb_deps += [dependency('gstreamer-video-1.0', version: '>= 1.6')]
endif

enable_spellcheck = get_option('spellcheck')
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
  'src/FavoritesTimeline.vala',
  'src/FilterPage.vala',
  'src/HomeTimeline.vala',
  'src/IMessageReceiver.vala',
  'src/IPage.vala',
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
  'src/list/FavImageRow.vala',
  'src/model/DMThreadsModel.vala',
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
  'src/CbTextTransform.c',
  'src/CbMedia.c',
  'src/CbMediaDownloader.c',
  'src/CbTypes.c',
  'src/CbUserCounter.c',
  'src/CbFilter.c',
  'src/CbAvatarCache.c',
  'src/CbMediaImageWidget.c',
  'src/CbTweetModel.c',
  'src/CbTwitterItem.c',
  'src/CbDeltaUpdater.c',
  'src/CbUtils.c',
  'vapi/corebird-internal.vapi'
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
  dependencies: cb_deps,
  include_directories: srcdir,
  vala_args: [
    meson.source_root() + '/vapi/config.vapi',
    '--target-glib=' + min_glib_version,
    '--vapidir=' + meson.source_root() + '/vapi/',
    '--gresources=' + meson.source_root() + '/corebird.gresource.xml',
    '--enable-experimental'
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
  ],
  install: true
)

subdir('data')
subdir('po')
subdir('tests')
