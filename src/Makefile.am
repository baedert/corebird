
AM_CPPFLAGS = $(CB_CFLAGS) \
							-Wno-incompatible-pointer-types-discards-qualifiers \
							-Wno-format-security \
							-Wno-unused-value \
							-Wno-incompatible-pointer-types


AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = corebird

corebird_SOURCES = \
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
			widgets/TweetListBox.vala \
			widgets/MaxSizeContainer.vala \
			widgets/ImageLabel.vala \
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
			util/TweetUtils.vala \
			util/Utils.vala \
			util/IntHistory.vala \
			util/UserCompletion.vala \
			util/WidgetReplacer.vala \
			util/Config.vala \
			util/WeakRef.vala \
			list/TweetListEntry.vala \
			list/DMListEntry.vala \
			list/UserListEntry.vala \
			list/AccountListEntry.vala \
		  list/DMThreadEntry.vala \
			list/StartConversationEntry.vala \
			window/ComposeTweetWindow.vala \
			window/SettingsDialog.vala \
			window/ImageDialog.vala \
			window/RemoveAccountDialog.vala \
			sql/Database.vala \
			sql/Statement.vala \
			sql/UpdateStatement.vala \
			sql/SelectStatement.vala \
			resources.c

corebird_LDADD = $(CB_LIBS)
corebird_VALAFLAGS = @CB_VALA_FLAGS@

resources.c: ../resources.xml
	glib-compile-resources ../resources.xml --target=resources.c --generate-source --sourcedir=../

CLEANFILES = *.h *.c *.stamp
