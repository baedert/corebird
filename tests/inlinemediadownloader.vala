
// UTIL {{{

void delete_file (string filename) {
  if (FileUtils.test (filename, FileTest.EXISTS)) {
    try {
      var f = GLib.File.new_for_path (filename);
      f.delete ();
    } catch (GLib.Error e) {
      warning (e.message);
    }
  }
}

// }}}


//void no_download () {
  //var url = "https://google.com";
  //Tweet t = new Tweet ();
  //t.id = 0;
  //t.user_id = 1;
  //var media_path = InlineMediaDownloader.get_media_path (t, url);
  //delete_file (media_path);
  //InlineMediaDownloader.try_load_media.begin (t, url, () => {
    // No media should have been added
    //assert (t.media == null);
    //assert (t.media_thumb == null);
    //assert (t.inline_media == null);
    //assert (!t.has_inline_media);
    //assert (!FileUtils.test (media_path, FileTest.EXISTS));
  //});
//}


void media_name () {
  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  string path = InlineMediaDownloader.get_media_path (t, "http://foobar.com/nanana.jpg");
  assert (path == Dirs.cache ("assets/media/0_1.jpeg"));

  path = InlineMediaDownloader.get_media_path (t, "http://bla.com/nanana");
  assert (path == Dirs.cache ("assets/media/0_1.png"));

  path = InlineMediaDownloader.get_media_path (t, "http://bla.com/foobar.png");
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
  delete_file (media_path);
  delete_file (Dirs.cache ("assets/media/thumbs/0_1.png"));
  var media = new Media ();
  media.url = url;
  InlineMediaDownloader.load_media.begin (t, media, () => {
    assert (media.path != null);
    assert (media.thumbnail != null);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    main_loop.quit ();
  });

  main_loop.run ();
}


void animation_download () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://i.imgur.com/rgF0Czu.gif";
  Tweet t = new Tweet ();
  t.id = 100;
  t.user_id = 20;
  var media_path = InlineMediaDownloader.get_media_path (t, url);
  delete_file (media_path);
  delete_file (Dirs.cache ("assets/media/thumbs/100_20.png"));
  var media = new Media ();
  media.url = url;

  InlineMediaDownloader.load_media.begin (t, media, () => {
    assert (media.path != null);
    assert (media.path == media_path);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    main_loop.quit ();
  });

  main_loop.run ();
}

void download_twice () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var t = new Tweet ();
  t.id = 300;
  t.user_id = 5;
  var media_path = InlineMediaDownloader.get_media_path (t, url);
  delete_file (media_path);
  delete_file (Dirs.cache ("assets/media/thumbs/300_5.png"));
  var media = new Media ();
  media.url = url;

  InlineMediaDownloader.load_media.begin (t, media, () => {
    assert (media.path != null);
    assert (media.path == media_path);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    InlineMediaDownloader.load_media.begin (t, media, () => {
      // NOTE: We are *not* deleting the just downloaded file here
      assert (media.path == media_path);
      assert (media.thumbnail != null);
      main_loop.quit ();
    });
  });
  main_loop.run ();
}

void no_thumbnail () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var t = new Tweet ();
  t.id = 300;
  t.user_id = 5;
  var media_path = InlineMediaDownloader.get_media_path (t, url);
  var thumb_path = Dirs.cache ("assets/media/thumbs/300_5.png");
  delete_file (media_path);
  delete_file (thumb_path);
  var media = new Media ();
  media.url = url;
  InlineMediaDownloader.load_media.begin (t, media, () => {
    assert (media.path != null);
    assert (media.thumbnail != null);
    assert (media.thumb_path == thumb_path);
    assert (GLib.FileUtils.test (media.thumb_path, GLib.FileTest.EXISTS));
    // Delete the thumbnail
    delete_file (thumb_path);
    // Download again
    InlineMediaDownloader.load_media.begin (t, media, () => {
      assert (media.thumbnail != null);
      assert (media.thumb_path == thumb_path);
      assert (GLib.FileUtils.test (media.thumb_path, GLib.FileTest.EXISTS));
      main_loop.quit ();
    });
  });
  main_loop.run ();
}


void no_media () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var t = new Tweet ();
  t.id = 300;
  t.user_id = 5;
  var media_path = InlineMediaDownloader.get_media_path (t, url);
  var thumb_path  = Dirs.cache ("assets/media/thumbs/300_5.png");
  var media = new Media ();
  media.url = url;
  delete_file (media_path);
  delete_file (thumb_path);

  InlineMediaDownloader.load_media.begin (t, media, () => {
    assert (media.path == media_path);
    assert (media.thumb_path == thumb_path);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    assert (GLib.FileUtils.test (media.thumb_path, GLib.FileTest.EXISTS));
    // Delete the media (not the thumbnail)
    delete_file (media_path);
    assert (!GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    InlineMediaDownloader.load_media.begin (t, media, () => {
      assert (media.path == media_path);
      assert (media.thumb_path == thumb_path);
      assert (media.thumbnail != null);
      assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
      assert (GLib.FileUtils.test (media.thumb_path, GLib.FileTest.EXISTS));
      main_loop.quit ();
    });
  });

  main_loop.run ();
}

void not_reachable () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/adfwer234234wfwer";
  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  var media_path = InlineMediaDownloader.get_media_path (t, url);
  var thumb_path = Dirs.cache ("assets/media/thumbs/0_1.png");
  var media = new Media ();
  media.url = url;
  // first delete the file if it does exist
  delete_file (media_path);
  delete_file (thumb_path);

  InlineMediaDownloader.load_media (t, media, () => {
    assert (media.path == null);
    assert (media.thumb_path == null);
    assert (!GLib.FileUtils.test (media_path, GLib.FileTest.EXISTS));
    main_loop.quit ();
  });

  main_loop.run ();
}

int main (string[] args) {
  GLib.Test.init (ref args);
  //GLib.Environment.set_variable ("G_SETTINGS_BACKEND", "memory", true);
  Settings.init ();
  //GLib.Test.add_func ("/media/no-download", no_download);
  GLib.Test.add_func ("/media/name", media_name);
  GLib.Test.add_func ("/media/normal-download", normal_download);
  GLib.Test.add_func ("/media/animation-download", animation_download);
  GLib.Test.add_func ("/media/download-twice", download_twice);
  GLib.Test.add_func ("/media/no-thumbnail", no_thumbnail);
  GLib.Test.add_func ("/media/no-media", no_media);
  GLib.Test.add_func ("/media/not-reachable", not_reachable);
  return GLib.Test.run ();
}
