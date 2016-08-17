project('corebird', 'vala', 'c')
gnome = import('gnome')

add_global_arguments(['--enable-deprecated',
                      '--enable-experimental',
                      '--enable-checking'],
                      language: 'vala')

add_global_arguments(['-DGETTEXT_PACKAGE="corebird"'],
                     language: 'c')


gtkdep     = dependency('gtk+-3.0', version: '>= 3.16')
glibdep    = dependency('glib-2.0', version: '>= 2.44')
librestdep = dependency('rest-0.7', version: '>= 0.7.93')
jsondep    = dependency('json-glib-1.0')
sqlitedep  = dependency('sqlite3')
soupdep    = dependency('libsoup-2.4')

resources = gnome.compile_resources(
  'corebird-resources',
  'corebird.gresource.xml',
  source_dir: '.'
)

valasources = [
  'src/main.vala',
  'src/Account.vala',
  'src/Corebird.vala',
  'src/DefaultTimeline.vala',
  'src/DeltaUpdater.vala',
  'src/DMManager.vala',
  'src/DMPage.vala',
  'src/DMThreadsPage.vala',
  'src/FavoritesTimeline.vala',
  'src/FilterPage.vala',
  'src/Filter.vala',
  'src/HomeTimeline.vala',
  'src/IMessageReceiver.vala',
  'src/IPage.vala',
  'src/ITwitterItem.vala',
  'src/ListsPage.vala',
  'src/ListStatusesPage.vala',
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
  'src/UserCounter.vala',
  'src/UserEventReceiver.vala',
  'src/UserStream.vala',
  'src/window/AboutDialog.vala',
  'src/window/AccountDialog.vala',
  'src/window/ComposeTweetWindow.vala',
  'src/window/FileSelector.vala',
  'src/window/ImageCropDialog.vala',
  'src/window/MediaDialog.vala',
  'src/window/ModifyFilterDialog.vala',
  'src/window/ModifySnippetDialog.vala',
  'src/window/SettingsDialog.vala',
  'src/window/UserListDialog.vala',
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
  'src/widgets/MediaImageWidget.vala',
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
  'src/model/TweetModel.vala',
  'src/model/DMThreadsModel.vala',
  'src/util/Benchmark.vala',
  'src/util/BundleHistory.vala',
  'src/util/Bundle.vala',
  'src/util/Dirs.vala',
  'src/util/TweetUtils.vala',
  'src/util/UserCompletion.vala',
  'src/util/UserUtils.vala',
  'src/util/Utils.vala',
  'src/util/WeakRef.vala',
  'src/async/Collect.vala',
  'src/async/ComposeJob.vala',
  'src/sql/Database.vala',
  'src/sql/InsertStatement.vala',
  'src/sql/SelectStatement.vala',
  'src/sql/UpdateStatement.vala',

  'vapi/corebird-internal.vapi',
  'vapi/config.vapi',

  'src/CbTweet.c',
  'src/Media.c',
  'src/MediaDownloader.c',
  'src/TextTransform.c',
  'src/Types.c',

  resources
]

configure_file(input: 'src/config.h.meson', output: 'config.h', configuration: configuration_data())

executable('corebird', valasources,
           dependencies: [glibdep, gtkdep, librestdep, jsondep, sqlitedep, soupdep],
           vala_args: ['--vapidir=vapi/',
                       '--gresources=' + meson.current_source_dir() + '/corebird.gresource.xml'],
           c_args: ['-I' + meson.current_source_dir() + '/src',
                    '-I' + meson.current_source_dir()])
#                    '-include config.h'])
