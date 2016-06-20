
AM_CPPFLAGS = \
	$(CB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	-DDATADIR=\"$(datadir)\" \
	-DPKGDATADIR=\"$(pkgdatadir)\" \
	-O0 \
	-fno-omit-frame-pointer


AM_VALAFLAGS = \
	--thread \
	--enable-deprecated \
	--enable-checking \
	--enable-experimental \
	--vapidir $(builddir) \
	--vapidir $(top_srcdir)/vapi \
	--basedir $(srcdir) \
	--directory $(builddir) \
	--gresources $(top_srcdir)/corebird.gresource.xml \
	$(top_srcdir)/vapi/config.vapi \
	$(top_srcdir)/vapi/corebird-internal.vapi \
	-C \
	$(NULL)

BUILT_SOURCES = \
	corebird.h \
	corebird-resources.c

bin_PROGRAMS = corebird
noinst_LTLIBRARIES = libcorebird.la

libcorebird_la_VALASOURCES = \
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
	Tweet.vala \
	IPage.vala \
	UserCounter.vala \
	DefaultTimeline.vala \
	DMThreadsPage.vala \
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
	UserEventReceiver.vala \
	SnippetManager.vala \
	DMManager.vala \
	widgets/TweetListBox.vala \
	widgets/MaxSizeContainer.vala \
	widgets/ScrollWidget.vala \
	widgets/TextButton.vala \
	widgets/DoubleTapButton.vala \
	widgets/ReplyEntry.vala \
	widgets/PixbufButton.vala \
	widgets/BadgeRadioButton.vala \
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
	widgets/FollowButton.vala \
	widgets/SurfaceProgress.vala \
	widgets/MediaButton.vala \
	widgets/ComposeImageManager.vala \
	util/TweetUtils.vala \
	util/Utils.vala \
	util/BundleHistory.vala \
	util/UserCompletion.vala \
	util/WeakRef.vala \
	util/Dirs.vala \
	util/Bundle.vala \
	util/UserUtils.vala \
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
	window/FileSelector.vala \
	sql/Database.vala \
	sql/InsertStatement.vala \
	sql/UpdateStatement.vala \
	sql/SelectStatement.vala \
	async/Collect.vala \
	async/ComposeJob.vala \
	model/TweetModel.vala \
	model/DMThreadsModel.vala

nodist_libcorebird_la_SOURCES = \
	libcorebird_la_vala.stamp \
	$(libcorebird_la_VALASOURCES:.vala=.c)

corebird.h corebird.vapi: libcorebird_la_vala.stamp
$(libcorebird_la_VALASOURCES:.vala=.c): libcorebird_la_vala.stamp


corebird_SOURCES = Media.c Media.h MediaDownloader.c MediaDownloader.h Types.c Types.h TextTransform.c TextTransform.h

libcorebird_la_vala.stamp: $(libcorebird_la_VALASOURCES) Makefile
	@$(VALAC) \
		$(AM_VALAFLAGS) $(CB_VALA_FLAGS) \
		-H corebird.h \
		--library corebird \
		--vapi corebird.vapi \
		$(filter %.vala %.c,$^)
	touch $@

libcorebird_la_LIBADD = $(CB_LIBS)

corebird_VALASOURCES = \
	main.vala


nodist_corebird_SOURCES = \
	corebird_vala.stamp \
	corebird-resources.c \
	$(corebird_VALASOURCES:.vala=.c)

corebird_LDADD = \
	$(CB_LIBS) \
	$(builddir)/libcorebird.la

corebird_VALAFLAGS = \
	$(CB_VALA_FLAGS) \
	corebird.vapi

$(corebird_VALASOURCES:.vala=.c): corebird_vala.stamp

corebird_vala.stamp: $(builddir)/libcorebird.la $(builddir)/corebird.vapi $(corebird_VALASOURCES) Makefile
	@$(VALAC) \
		$(AM_VALAFLAGS) $(CB_VALA_FLAGS) \
		--pkg corebird \
		$(filter %.vala %.c,$^)
	touch $@

resource_deps = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir) $(top_srcdir)/corebird.gresource.xml)
corebird-resources.c: $(top_srcdir)/corebird.gresource.xml $(resource_deps) Makefile
	XMLLINT=$(XMLLINT) $(GLIB_COMPILE_RESOURCES) --target $@ --generate --sourcedir=$(top_srcdir) --c-name corebird $<

CLEANFILES = \
	libcorebird_la_vala.stamp \
	corebird_vala.stamp \
	$(nodist_libcorebird_la_SOURCES) \
	$(nodist_corebird_SOURCES) \
	corebird.vapi \
	corebird.h

EXTRA_DIST = \
	$(libcorebird_la_VALASOURCES) \
	$(corebird_VALASOURCES) \
	$(resource_deps)
