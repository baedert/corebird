# Corebird

This is the readme for the current *development version*. If you're looking for one of the stable releases, check the "releases" link at the top of this page.

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=baedert&url=http://github.com/baedert/corebird&title=corebird&language=vala&tags=github&category=software)

## Shortcuts

| Key                | Description                                                                                                                                 |
| :-----:            | :-----------                                                                                                                                |
| `Ctrl + t`         | Compose Tweet                                                                                                                               |
| `Back`             | Go one page back (this can be triggered via the back button on the keyboard, the back thumb button on the mouse or  `Alt + Left`)           |
| `Forward`          | Go one page forward (this can be triggered via the forward button on the keyboard, the forward thumb button on the mouse or  `Alt + Right`) |
| `Alt + num`        | Go to page `num` (between 1 and 7 at the moment)                                                                                            |
| `Ctrl + Shift + s` | Show/Hide sidebar                                                                                                                           |
| `Ctrl + p`         | Show account settings                                                                                                                       |
| `Ctrl + k`         | Show account list                                                                                                                           |
| `Ctrl + Shift + p` | Show application settings                                                                                                                   |


  When a tweet is focused (via keynav):

  - `r`  - reply
  - `tt` - retweet
  - `f`  - favorite
  - `dd` - delete
  - `Return` - Show tweet details


## Will this work on distribution XYZ?
  I don't know. If you can satisfy all the dependencies, probably yes but
  you'd most likely still have to compile and install it from source (that is,
  if no one else makes packages).

## Packages
  Here you find packages for your distribution:
  - Ubuntu 15.10: [GetDeb](http://www.getdeb.net/app/Corebird)

## Translations
  Since February 2014, there's a [Corebird project on Transifex](https://www.transifex.com/projects/p/corebird)

## Contributing

  All contributions are welcome (artword, design, code, just ideas, etc.) but if you're planning to
  actively change something bigger, talk to me first.


## Dependencies
 - `gtk+-3.0 >= 3.16`
 - `glib-2.0 >= 2.44`
 - `rest-0.7` (`>= 0.7.91` for image uploads)
 - `json-glib-1.0`
 - `sqlite3`
 - `libsoup-2.4`
 - `intltool >= 0.40`
 - `libgee-0.8`
 - `vala >= 0.26` (makedep)
 - `automake >= 1.14` (makedep)
 - `gstreamer-1.0` (disable via --disable-video, default enabled)
 - `gst-plugins-bad-1.0 >= 1.6` (disable via --disable-video, default enabled)
 - `gst-plugins-good-1.0` (disable via --disable-video, default enabled)
 - `gst-libav-1.0` (disable via --disable-video, default enabled)

Note that the above packages are just rough estimations, the actual package names on your distribution may vary.

If you pass `--disable-video` to the configure script, you don't need any gstreamer dependency but  won't be able to view any videos (i.e. no vines and no twitter gifs).

## Compiling

```
./autogen.sh --prefix=/usr
make
make install
```

