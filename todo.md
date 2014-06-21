



# Video todo

 - Resize the window/GtkDrawingArea to the video's size. This
   is especially interesting for "animated gifs" since we don't
   know their real size
 - Stop download/play when the window gets closed while downloading
 - [x] Media preview in tweet info page
 - Multiple media in compose window


## Possible improvements

 - Maintain a in-memory hashmap between video urls (media.url, not media.thumb\_url)
   and temporary files so we can refer to them again without saving them persistently.
 - Use the mouse wheel to adjust volume when playing a vine (?)
 - Support saving also for videos (?)
