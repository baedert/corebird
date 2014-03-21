


void no_download () {
  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  InlineMediaDownloader.try_load_media.begin (t, "https://google.de", () => {
    // No media should have been added
    assert (t.media == null);
    assert (t.media_thumb == null);
    assert (t.inline_media == null);
  });
}


void media_name () {
  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  string path = InlineMediaDownloader.get_media_path (t, "http://foobar.com/nanana.jpg");
  message ("path: %s", path);
  assert (path == Dirs.cache ("assets/media/0_1.jpeg"));

  path = InlineMediaDownloader.get_media_path (t, "http://bla.com/nanana");
  message ("path: %s", path);
  assert (path == Dirs.cache ("assets/media/0_1.png"));

  path = InlineMediaDownloader.get_media_path (t, "http://bla.com/foobar.png");
  message ("path: %s", path);
  assert (path == Dirs.cache ("assets/media/0_1.png"));
}



int main (string[] args) {
  GLib.Test.init (ref args);
  Settings.init ();
  GLib.Test.add_func ("/media/no-download", no_download);
  GLib.Test.add_func ("/media/name", media_name);
  return GLib.Test.run ();
}
