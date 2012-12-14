
# Corebird Specification

## Introduction
Corebird is a new native Twitter client for the linux desktop written with Gtk+.


## Features
* Native Gtk+3.x GUI
* Uses GLib/Gtk+'s newest APIs to provide perfect desktop integration and the best UX possible.
* No stupid webkit for tweet rendering
* Can be minimized to the tray
* Notification integration
* relatively well adjustable
* Localized

### Undecided
* Multi-Account support?
* Column support?
 


## Inspiration

* [TweetBot](https://itunes.apple.com/de/app/tweetbot-for-twitter/id557168941?mt=12)
* [DanRabbit's Twitter Client Mockup](http://danrabbit.deviantart.com/art/Twitter-333689268)
* [Twitter For Mac](http://a1991.phobos.apple.com/us/r1000/030/Purple/54/2d/b0/mzl.ifsvcyku.800x500-75.jpg)
* [Dribble](http://dribbble.s3.amazonaws.com/users/30071/screenshots/666701/attachments/58662/Timeline.png)
* [Settings Dialog](http://elementaryos.org/sites/default/files/user/5/Screenshot%20from%202012-03-11%2000%3A00%3A40.png)


## TODO
* Find someone to make a few UI-Prototypes(or make them yourself in Glade...)
* Find someone to make an Icon(or make a crappy one yourself...)
* Also, find someone to make some icons for use in the app(send, home, mentions, ...)
* Localice via gettext
* Implement auto-completion of 
    * Followers/followings
    * Most trending topics(special and cool)

## Release plan
* Ende Januar 2013: Beta-test mit ausgewählten Testern
* Wenn der Beta-Test gut läuft, dann finales Release mitte März 2013


## Consider
* Let the user choose an application for opening images/videos
    * youtube-viewer

## Feature completion
* <s>Highlight &  implement links in tweets</s>
* Load user's last X tweets in the profiles
* <s>Make the settings window work FFS</s>
* <s>Implement search</s>
* <s>Use progress indicators in search</s>
* Add batches to the toolbar icons(?)