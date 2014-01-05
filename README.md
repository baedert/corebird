
# Corebird

## Shortcuts

| Key                   | Description                                                                                                                                |
| :-----:               | :-----------                                                                                                                               |
| `Ctrl + t`,`Ctrl + n` | Compose Tweet                                                                                                                              |
| `Back`                | Go one page back(this can be triggered via tha back button on the keyboard, the back thumb button on the mouse or  `Alt + Left`)           |
| `Forward`             | Go one page forward(this can be triggered via tha forward button on the keyboard, the forward thumb button on the mouse or  `Alt + Right`) |
| `Alt + num`           | Go to page `num`(between 1 and 5 at the moment)                                                                                            |
| `Ctrl + Shift + s`    | Show/Hide sidebar                                                                                                                          |


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


## Dependencies
 - `gtk+-3.0 >= 3.9`
 - `glib-2.0 >= 2.38`
 - `rest-0.7`
 - `json-glib-1.0`
 - `libnotify`
 - `sqlite3`
 - `libsoup-2.4`
 - `vala >= 0.22` (makedep)
 - `cmake >= 2.6` (makedep)

## Compiling

```
cmake . -DCMAKE_INSTALL_PREFIX=/usr
make
make install
```

