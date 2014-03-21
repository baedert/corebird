


void no_download () {
  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  InlineMediaDownloader.try_load_media.begin (t, "https://google.de", () => {
    // No media should have been added
    assert (t.media == null);
    assert (t.media_thumb == null);
    assert (t.inline_media == null);
    assert (!t.has_inline_media);
    // TODO: Delete file first, then check that it does not exist.
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


void normal_download () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  var media_path = InlineMediaDownloader.get_media_path (t, url);
  // first delete the file if it does exist
  {
    var media_file = GLib.File.new_for_path (media_path);
    if (media_file.query_exists ()) {
      try {
        media_file.delete ();
      } catch (GLib.Error e) {
        critical (e.message);
      }
    }

    media_file = GLib.File.new_for_path (Dirs.cache ("assets/media/thumbs/0_1.png"));
    if (media_file.query_exists ()) {
      try {
        media_file.delete ();
      } catch (GLib.Error e) {
        critical (e.message);
      }
    }
  }

  InlineMediaDownloader.try_load_media.begin (t, url, (o, res) => {
      //error ("try_load_media callback");
    assert (t.media != null);
    assert (t.media_thumb != null);
    assert (t.inline_media != null);
    assert (GLib.FileUtils.test (t.media, GLib.FileTest.EXISTS));
    main_loop.quit ();
  });

  main_loop.run ();
}



int main (string[] args) {
  GLib.Test.init (ref args);
  //GLib.Environment.set_variable ("G_SETTINGS_BACKEND", "memory", true);
  Settings.init ();
  GLib.Test.add_func ("/media/no-download", no_download);
  GLib.Test.add_func ("/media/name", media_name);
  GLib.Test.add_func ("/media/normal-download", normal_download);
  return GLib.Test.run ();
}
