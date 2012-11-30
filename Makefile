FILES = src/Corebird.vala \
		src/MainWindow.vala \
		src/Tweet.vala \
		src/Settings.vala \
		src/FirstRunWindow.vala \
		src/Twitter.vala \
		src/NewTweetWindow.vala \
		src/Utils.vala \
		src/TweetList.vala \
		src/TweetListEntry.vala \
		src/SettingsDialog.vala \
		src/containers/SearchContainer.vala \
		src/containers/StreamContainer.vala \
		src/containers/MentionsContainer.vala \
		src/ImageLabel.vala \
		src/User.vala



LIBS =  --pkg gio-2.0 \
		--pkg gee-1.0 \
		--pkg libsoup-2.4 \
		--pkg rest-0.7 \
		--pkg gtk+-3.0 \
		--pkg sqlheavy-0.2 \
		--pkg json-glib-1.0 \
		--pkg libsoup-2.4 \
		--pkg gmodule-2.0

NAME = Corebird
CC = clang
PARAMS = -X -Wno-incompatible-pointer-types -X -Wno-unused-value -g

all: compile

compile: $(FILES)
	valac --enable-checking --cc=$(CC) $(PARAMS) $(LIBS)  $(FILES) -o $(NAME)


settings: org.baedert.corebird.gschema.xml
	sudo cp org.baedert.corebird.gschema.xml /usr/share/glib-2.0/schemas
	sudo glib-compile-schemas /usr/share/glib-2.0/schemas
