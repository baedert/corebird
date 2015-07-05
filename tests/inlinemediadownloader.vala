
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
  Media m = new Media ();
  m.id = 5;
  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;

  m.url = "http://foobar.com/nananana.jpg";
  string path = InlineMediaDownloader.get_media_path (t, m);
  assert (path == Dirs.cache ("assets/media/0_1_5.jpeg"));

  m.url = "http://bla.com/nananana";
  path = InlineMediaDownloader.get_media_path (t, m);
  assert (path == Dirs.cache ("assets/media/0_1_5.png"));

  m.url = "http://bla.com/foobar.png";
  path = InlineMediaDownloader.get_media_path (t, m);
  assert (path == Dirs.cache ("assets/media/0_1_5.png"));

  t.is_retweet = true;
  t.rt_id = 10;
  path = InlineMediaDownloader.get_media_path (t, m);
  assert (path == Dirs.cache ("assets/media/10_1_5.png"));
}


void normal_download () {
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var main_loop = new GLib.MainLoop ();
  var media = new Media ();
  media.url = url;
  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  t.medias = new Media[1];
  t.medias[0] = media;
  var media_path = InlineMediaDownloader.get_media_path (t, media);
  var thumb_path = InlineMediaDownloader.get_thumb_path (t, media);
  // first delete the file if it does exist
  delete_file (media_path);
  delete_file (thumb_path);
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
  var media = new Media ();
  media.url = url;

  Tweet t = new Tweet ();
  t.id = 100;
  t.user_id = 20;
  t.medias = new Media[1];
  t.medias[0] = media;

  var media_path = InlineMediaDownloader.get_media_path (t, media);
  var thumb_path = InlineMediaDownloader.get_thumb_path (t, media);
  delete_file (media_path);
  delete_file (thumb_path);

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
  var media = new Media ();
  media.url = url;

  var t = new Tweet ();
  t.id = 300;
  t.user_id = 5;
  t.medias = new Media[1];
  t.medias[0] = media;

  var media_path = InlineMediaDownloader.get_media_path (t, media);
  var thumb_path = InlineMediaDownloader.get_thumb_path (t, media);
  delete_file (media_path);
  delete_file (thumb_path);

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
  var media = new Media ();
  media.url = url;

  var t = new Tweet ();
  t.id = 300;
  t.user_id = 5;

  t.medias = new Media[1];
  t.medias[0] = media;

  var media_path = InlineMediaDownloader.get_media_path (t, media);
  var thumb_path = InlineMediaDownloader.get_thumb_path (t, media);
  delete_file (media_path);
  delete_file (thumb_path);

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
  var media = new Media ();
  media.url = url;

  var t = new Tweet ();
  t.id = 300;
  t.user_id = 5;
  t.medias = new Media[1];
  t.medias[0] = media;


  var media_path = InlineMediaDownloader.get_media_path (t, media);
  var thumb_path = InlineMediaDownloader.get_thumb_path (t, media);
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
  var media = new Media ();
  media.url = url;

  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  t.medias = new Media[1];
  t.medias[0] = media;


  var media_path = InlineMediaDownloader.get_media_path (t, media);
  var thumb_path = InlineMediaDownloader.get_thumb_path (t, media);
  // first delete the file if it does exist
  delete_file (media_path);
  delete_file (thumb_path);

  InlineMediaDownloader.load_media.begin (t, media, () => {
    //assert (media.thumb_path == null);
    //assert (!GLib.FileUtils.test (media_path, GLib.FileTest.EXISTS));
    main_loop.quit ();
  });

  main_loop.run ();
}

void too_big () {
  var main_loop = new GLib.MainLoop ();
  Settings.get ().set_double ("max-media-size", 0.0);
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var media = new Media ();
  media.url = url;

  Tweet t = new Tweet ();
  t.id = 0;
  t.user_id = 1;
  t.medias = new Media[1];
  t.medias[0] = media;

  var media_path = InlineMediaDownloader.get_media_path (t, media);
  var thumb_path = InlineMediaDownloader.get_thumb_path (t, media);
  // first delete the file if it does exist
  delete_file (media_path);
  delete_file (thumb_path);

  InlineMediaDownloader.load_media.begin (t, media, () => {
    // gets set anyway
    assert (media.path == media_path);
    assert (media.thumb_path == thumb_path);
    assert (media.thumbnail == null);
    // should be marked invalid
    assert (media.invalid);
    main_loop.quit ();
    Settings.get ().revert ();
  });

  main_loop.run ();
}

int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Environment.set_variable ("GSETTINGS_BACKEND", "memory", true);
  Settings.init ();
  Dirs.create_dirs ();
  Utils.init_soup_session ();
  //GLib.Test.add_func ("/media/no-download", no_download);
  GLib.Test.add_func ("/media/name", media_name);
  GLib.Test.add_func ("/media/normal-download", normal_download);
  GLib.Test.add_func ("/media/animation-download", animation_download);
  GLib.Test.add_func ("/media/download-twice", download_twice);
  GLib.Test.add_func ("/media/no-thumbnail", no_thumbnail);
  GLib.Test.add_func ("/media/no-media", no_media);
  GLib.Test.add_func ("/media/not-reachable", not_reachable);
  GLib.Test.add_func ("/media/too_big", too_big);

  return GLib.Test.run ();
}
