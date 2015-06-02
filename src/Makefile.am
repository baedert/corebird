
AM_CPPFLAGS = $(CB_CFLAGS) \
							-Wno-format-security \
							-Wno-unused-value


AUTOMAKE_OPTIONS = subdir-objects
BUILT_SOURCES = libcorebird_la_vala.stamp

bin_PROGRAMS = corebird
noinst_LTLIBRARIES = libcorebird.la

# Sources {{{
cb_sources = \
			Corebird.vala \
			MainWindow.vala \
			MainWidget.vala \
			Account.vala \
			HomeTimeline.vala \
			MentionsTimeline.vala \
			SearchPage.vala \
			DMPage.vala \
			DeltaUpdater.vala \
			ITwitterItem.vala \
			UserStream.vala \
			IMessageReceiver.vala \
			ITimeline.vala \
			Tweet.vala \
			IPage.vala \
			UserCounter.vala \
			DefaultTimeline.vala \
			DMThreadsPage.vala \
			InlineMediaDownloader.vala \
			Settings.vala \
			NotificationManager.vala \
			Twitter.vala \
			ProfilePage.vala \
			TweetInfoPage.vala \
			ListStatusesPage.vala \
			ListsPage.vala \
			FavoritesTimeline.vala \
			Filter.vala \
			FilterPage.vala \
			Media.vala \
			UserEventReceiver.vala \
			SnippetManager.vala \
			widgets/TweetListBox.vala \
			widgets/MaxSizeContainer.vala \
			widgets/ScrollWidget.vala \
			widgets/TextButton.vala \
			widgets/DoubleTapButton.vala \
			widgets/ReplyEntry.vala \
			widgets/PixbufButton.vala \
			widgets/BadgeRadioToolButton.vala \
			widgets/DMPlaceholderBox.vala \
			widgets/AccountCreateWidget.vala \
			widgets/AspectImage.vala \
			widgets/UserListsWidget.vala \
			widgets/ReplyIndicator.vala \
			widgets/MultiMediaWidget.vala \
			widgets/AvatarWidget.vala \
			widgets/AvatarBannerWidget.vala \
			widgets/MediaImageWidget.vala \
			widgets/MediaVideoWidget.vala \
			widgets/CropWidget.vala \
			widgets/AddImageButton.vala \
			widgets/CompletionTextView.vala \
			widgets/LazyMenuButton.vala \
			widgets/ImpostorWidget.vala \
			util/TweetUtils.vala \
			util/Utils.vala \
			util/BundleHistory.vala \
			util/UserCompletion.vala \
			util/Config.vala \
			util/WeakRef.vala \
			util/Dirs.vala \
			util/Bundle.vala \
			util/TextTransform.vala \
			list/TweetListEntry.vala \
			list/DMListEntry.vala \
			list/UserListEntry.vala \
			list/DMThreadEntry.vala \
			list/StartConversationEntry.vala \
			list/ListListEntry.vala \
			list/NewListEntry.vala \
			list/FilterListEntry.vala \
			list/UserFilterEntry.vala \
			list/AddListEntry.vala \
			list/ProgressEntry.vala \
			list/SnippetListEntry.vala \
			window/ComposeTweetWindow.vala \
			window/SettingsDialog.vala \
			window/UserListDialog.vala \
			window/ModifyFilterDialog.vala \
			window/AboutDialog.vala \
			window/AccountDialog.vala \
			window/MediaDialog.vala \
			window/ImageCropDialog.vala \
			window/ModifySnippetDialog.vala \
			sql/Database.vala \
			sql/Statement.vala \
			sql/UpdateStatement.vala \
			sql/SelectStatement.vala \
			async/Collect.vala \
			model/TweetModel.vala
# }}}

corebird.vapi libcorebird_la_vala.stamp corebird.h: $(cb_sources)
	@$(VALAC) $^ --vapi=corebird.vapi -C --header corebird.h @CB_VALA_FLAGS@
	touch corebird.vapi libcorebird_la_vala.stamp corebird.h

#corebird.h corebird.vapi: libcorebird_la_vala.stamp

libcorebird_la_LIBADD = @CB_LIBS@
libcorebird_la_VALASOURCES = $(cb_sources)
libcorebird_la_SOURCES = libcorebird_la_vala.stamp \
												 $(cb_sources:.vala=.c)

corebird_SOURCES = main.vala resources.c
corebird_LDADD = libcorebird.la @CB_LIBS@
corebird_VALAFLAGS = corebird.vapi @CB_VALA_FLAGS@
main.vala: corebird.vapi corebird.h


GRESDEPS = $(top_srcdir)/$1 $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir) $(top_srcdir)/$1)
resource_deps = $(call GRESDEPS,resources.xml)
resources.c: $(resource_deps)
	$(GLIB_COMPILE_RESOURCES) $(top_srcdir)/resources.xml --target=resources.c --generate-source --sourcedir=$(top_srcdir)

CLEANFILES = *.h *.c *.o *.stamp resources.c libcorebird.la corebird corebird.vapi corebird.h
EXTRA_DIST = $(cb_sources) \
						 corebird.h
