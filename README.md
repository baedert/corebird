
# Corebird

## Shortcuts

| Key                | Description                                                                                                                                |
| :-----:            | :-----------                                                                                                                               |
| `Ctrl + t`         | Compose Tweet                                                                                                                              |
| `Back`             | Go one page back(this can be triggered via tha back button on the keyboard, the back thumb button on the mouse or  `Alt + Left`)           |
| `Forward`          | Go one page forward(this can be triggered via tha forward button on the keyboard, the forward thumb button on the mouse or  `Alt + Right`) |
| `Alt + num`        | Go to page `num`(between 1 and 7 at the moment)                                                                                            |
| `Ctrl + Shift + s` | Show/Hide sidebar                                                                                                                          |


  When a tweet is focused(via keynav):

  - `r`  - reply
  - `tt` - retweet
  - `f`  - favorite
  - `dd` - delete
  - `Return` - Show tweet details


## Will this work on distrubution XYZ?
  I don't know. If you can satisfy all the dependencies, probably yes but
  you'd most likely still have to compile and install it from source(that is,
  if no one else makes packages).


## But but... something is not right!
  Open a bug. Writing about it somewhere else(especially in a language I do not understand) won't help.

## Translations
  Since February 2014, there's a [Corebird project on Transifex](https://www.transifex.com/organization/corebird/dashboard/corebird)


## Dependencies
 - `gtk+-3.0 >= 3.12`
 - `glib-2.0 >= 2.40`
 - `rest-0.7` (`>= 0.7.91` for image uploads)
 - `json-glib-1.0`
 - `sqlite3`
 - `libsoup-2.4`
 - `intltool >= 0.40`
 - `libgee-0.8`
 - `vala >= 0.22` (makedep)
 - `automake >= 1.14` (makedep)
 - `gstreamer` (disable via --disable-video)
 - `gst-plugins-bad` (disable via --disable-video)

If you pass`--disable-video`

## Compiling

```
./autogen.sh --prefix=/usr
make
make install
```

