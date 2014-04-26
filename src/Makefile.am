
AM_CPPFLAGS = $(CB_CFLAGS) \
							-Wno-incompatible-pointer-types-discards-qualifiers \
							-Wno-format-security \
							-Wno-unused-value \
							-Wno-incompatible-pointer-types


AUTOMAKE_OPTIONS = subdir-objects


bin_PROGRAMS = corebird
noinst_LTLIBRARIES = libcorebird.la


libcorebird_la_VALASOURCES = \
			Corebird.vala \
			MainWindow.vala \
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
			WarningService.vala \
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
			widgets/AccountInfoWidget.vala \
			widgets/AspectImage.vala \
			widgets/BgBox.vala \
			widgets/UserListsWidget.vala \
			widgets/ReplyIndicator.vala \
			util/TweetUtils.vala \
			util/Utils.vala \
			util/IntHistory.vala \
			util/UserCompletion.vala \
			util/WidgetReplacer.vala \
			util/Config.vala \
			util/WeakRef.vala \
			util/Dirs.vala \
			list/TweetListEntry.vala \
			list/DMListEntry.vala \
			list/UserListEntry.vala \
			list/AccountListEntry.vala \
			list/DMThreadEntry.vala \
			list/StartConversationEntry.vala \
			list/ListListEntry.vala \
			list/NewListEntry.vala \
			list/FilterListEntry.vala \
			list/UserFilterEntry.vala \
			window/ComposeTweetWindow.vala \
			window/SettingsDialog.vala \
			window/ImageDialog.vala \
			window/RemoveAccountDialog.vala \
			window/UserListDialog.vala \
			window/ModifyFilterDialog.vala \
			sql/Database.vala \
			sql/Statement.vala \
			sql/UpdateStatement.vala \
			sql/SelectStatement.vala

libcorebird_la_SOURCES =  \
			$(libcorebird_la_VALASOURCES)

corebird.vapi: libcorebird.la

libcorebird_la_LIBADD = @CB_LIBS@
libcorebird_la_VALAFLAGS = --vapi=corebird.vapi --header corebird.h @CB_VALA_FLAGS@

corebird${EXEEXT}: corebird.vapi
corebird_SOURCES = main.vala resources.c
corebird_LDADD = libcorebird.la @CB_LIBS@
corebird_VALAFLAGS = corebird.vapi @CB_VALA_FLAGS@

resources.c: ../resources.xml ../ui/*.ui
	$(GLIB_COMPILE_RESOURCES) ../resources.xml --target=resources.c --generate-source --sourcedir=../

CLEANFILES = *.h *.c *.o *.stamp resources.c libcorebird.la corebird corebird.vapi
#EXTRA_DIST = $(cb_resources_deps)
