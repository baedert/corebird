
# Corebird Specification

## Introduction
Corebird is a new native Twitter client for the linux desktop written with Gtk+.


## Features
* Native Gtk+3.x GUI
* Uses GLib/Gtk+'s newest APIs to provide perfect desktop integration and the best UX possible.
* No stupid webkit for tweet rendering
* Can be minimized to tray
* Notification integration  
* relatively well adjustable
* Localized (See common questions on developer.gnome.org)

### Undecided
* Multi-Account support?
* Column support?



## Inspiration

* [TweetBot](https://itunes.apple.com/de/app/tweetbot-for-twitter/id557168941?mt=12)
* [DanRabbit's Twitter Client Mockup](http://danrabbit.deviantart.com/art/Twitter-333689268)
* [Twitter For Mac](http://a1991.phobos.apple.com/us/r1000/030/Purple/54/2d/b0/mzl.ifsvcyku.800x500-75.jpg)
* [Dribble](http://dribbble.s3.amazonaws.com/users/30071/screenshots/666701/attachments/58662/Timeline.png)
* [Settings Dialog](http://elementaryos.org/sites/default/files/user/5/Screenshot%20from%202012-03-11%2000%3A00%3A40.png)
* [Osfoora For Mac](http://osfoora.com/mac/)


## ToDo
* Find someone to make an Icon(or make a crappy one yourself...)
* Also, find someone to make some icons for use in the app(send, home, mentions, ...)
* Localize via gettext
* Implement auto-completion of
    * Followers/followings
    * Most trending topics(special and cool)

## Release plan
* Ende Februar 2013: Beta-test mit ausgewählten Testern
    * Bl1nk
    * Heinz
    * ?
    * Use bitbucket/issue-tracker for bugs 
* Wenn der Beta-Test gut läuft, dann finales Release mitte März 2013


## Consider
* Let the user choose an application for opening images/videos     
    * youtube-viewer 
* Let the user choose if he wants to open e.g. the details to a tweet open
   in a new window(good for tiling wms) or in a side pane in the 
   main window(good for floating wms).
* Extend the style.css to style everything entirely so the app gets its
   own style all over?

## Feature completion
* Load user's last X tweets in the profiles
* Add badges to the toolbar icons(?)
* Make nickname and hashtag highlighting work again
* Implement inline media
* implement stupid side pane FFS
* Ask the librest maintainer about the patches
* Experiment with lazy loading(loading new tweets when the user
   hits the end of the list)


# Coding Specification

## Tweets
Tweets get loaded as Json from the Twitter Servers and thus need to be parsed. Also, they need to be
stored(cached) in the SQLite Database, so they need to be written(and read from the database) again.

The text of a Tweet gets saved in its 'natural' state, meaning the actual form that gets sent from the
Twitter server.
Problems:

* That form sucks because the links in there are a no-go because they t.co doesn't tell the user anything.
   However, replacing those links with their actual destination also sucks because that would mean that any
   information regarding the length of the tweet will disappear completely.
   Saving all links in a Tweet also sucks because that means we need to create an extra SQL table just for
   that, also it would make loading/displaying Tweets a lot slower.
