
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


void media_name () {
  Media m = new Media ();
  m.id = 5;

  Tweet t = new Tweet ();
  t.source_tweet = new MiniTweet ();
  t.source_tweet.author = UserIdentity ();
  t.id = 0;
  t.source_tweet.author.id = 1;

  m.url = "http://foobar.com/nananana.jpg";
  string path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, m);
  assert (path == Dirs.cache ("assets/media/0_1_5.jpeg"));

  m.url = "http://bla.com/nananana";
  path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, m);
  assert (path == Dirs.cache ("assets/media/0_1_5.png"));

  m.url = "http://bla.com/foobar.png";
  path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, m);
  assert (path == Dirs.cache ("assets/media/0_1_5.png"));

  t.retweeted_tweet = new MiniTweet ();
  t.source_tweet.id = 10;
  path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, m);
  assert (path == Dirs.cache ("assets/media/10_1_5.png"));
}


void normal_download () {
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var main_loop = new GLib.MainLoop ();
  var media = new Media ();
  media.url = url;
  Tweet t = new Tweet ();
  t.source_tweet = new MiniTweet ();
  t.source_tweet.id = 0;
  t.source_tweet.author = UserIdentity ();
  t.id = 0;
  t.source_tweet.author.id = 1;
  t.source_tweet.medias = new Media[1];
  t.source_tweet.medias[0] = media;
  var media_path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, media);
  // first delete the file if it does exist
  delete_file (media_path);
    InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
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
  t.source_tweet = new MiniTweet ();
  t.source_tweet.id = 100;
  t.source_tweet.author = UserIdentity ();
  t.id = 100;

  t.source_tweet.author.id = 20;
  t.source_tweet.medias = new Media[1];
  t.source_tweet.medias[0] = media;

  var media_path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, media);
  delete_file (media_path);

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
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

  Tweet t = new Tweet ();
  t.source_tweet = new MiniTweet ();
  t.source_tweet.id = 300;
  t.source_tweet.author = UserIdentity ();
  t.id = 300;
  t.source_tweet.author.id = 5;



  t.source_tweet.medias = new Media[1];
  t.source_tweet.medias[0] = media;

  var media_path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, media);
  delete_file (media_path);

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    assert (media.path != null);
    assert (media.path == media_path);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
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



  Tweet t = new Tweet ();
  t.source_tweet = new MiniTweet ();
  t.source_tweet.id = 300;
  t.source_tweet.author = UserIdentity ();
  t.id = 300;
  t.source_tweet.author.id = 5;

  t.source_tweet.medias = new Media[1];
  t.source_tweet.medias[0] = media;


  var media_path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, media);
  delete_file (media_path);

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    assert (media.path != null);
    assert (media.thumbnail != null);
    // Delete the thumbnail
    // Download again
    InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
                                                   //assert (false);
      assert (media.thumbnail != null);
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




  Tweet t = new Tweet ();
  t.source_tweet = new MiniTweet ();
  t.source_tweet.id = 300;
  t.source_tweet.author = UserIdentity ();
  t.id = 300;
  t.source_tweet.author.id = 5;

  t.source_tweet.medias = new Media[1];
  t.source_tweet.medias[0] = media;



  var media_path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, media);
  delete_file (media_path);

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    assert (media.path == media_path);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    // Delete the media (not the thumbnail)
    delete_file (media_path);
    assert (!GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
      assert (media.path == media_path);
      assert (media.thumbnail != null);
      assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
      main_loop.quit ();
    });
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
  t.source_tweet = new MiniTweet ();
  t.source_tweet.id = 0;
  t.source_tweet.author = UserIdentity ();
  t.id = 0;
  t.source_tweet.author.id = 1;

  t.source_tweet.medias = new Media[1];
  t.source_tweet.medias[0] = media;





  var media_path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, media);
  // first delete the file if it does exist
  delete_file (media_path);

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    // gets set anyway
    assert (media.path == media_path);
    assert (media.thumbnail == null);
    // should be marked invalid
    assert (media.invalid);
    main_loop.quit ();
    Settings.get ().revert ();
  });

  main_loop.run ();
}

void double_download () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var media = new Media ();
  media.url = url;

  Tweet t = new Tweet ();
  t.source_tweet = new MiniTweet ();
  t.source_tweet.id = 0;
  t.source_tweet.author = UserIdentity ();
  t.id = 0;
  t.source_tweet.author.id = 1;

  t.source_tweet.medias = new Media[1];
  t.source_tweet.medias[0] = media;



  var media_path = InlineMediaDownloader.get ().get_media_path (t.source_tweet, media);
  // first delete the file if it does exist
  delete_file (media_path);

  var collect_obj = new Collect (5);

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    message ("First callback");
    assert (media.path == media_path);
    assert (media.thumbnail != null);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    assert (!media.invalid);
    collect_obj.emit ();
  });

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    message ("Second callback");
    assert (media.path == media_path);
    assert (media.thumbnail != null);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    assert (!media.invalid);
    collect_obj.emit ();
  });
  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    message ("Second callback");
    assert (media.path == media_path);
    assert (media.thumbnail != null);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    assert (!media.invalid);
    collect_obj.emit ();
  });
  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    message ("Second callback");
    assert (media.path == media_path);
    assert (media.thumbnail != null);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    assert (!media.invalid);
    collect_obj.emit ();
  });
  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    message ("Second callback");
    assert (media.path == media_path);
    assert (media.thumbnail != null);
    assert (GLib.FileUtils.test (media.path, GLib.FileTest.EXISTS));
    assert (!media.invalid);
    collect_obj.emit ();
  });

  collect_obj.finished.connect (() => {
    main_loop.quit ();
  });

  main_loop.run ();
  assert (collect_obj.done);
}



int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Environment.set_variable ("GSETTINGS_BACKEND", "memory", true);
  Gtk.init (ref args);
  Settings.init ();
  Dirs.create_dirs ();
  Utils.init_soup_session ();
  GLib.Test.add_func ("/media/name", media_name);
  GLib.Test.add_func ("/media/normal-download", normal_download);
  GLib.Test.add_func ("/media/animation-download", animation_download);
  GLib.Test.add_func ("/media/download-twice", download_twice);
  GLib.Test.add_func ("/media/no-thumbnail", no_thumbnail);
  GLib.Test.add_func ("/media/no-media", no_media);
  GLib.Test.add_func ("/media/double_download", double_download);
  /* Keep this one at the bottom! */
  GLib.Test.add_func ("/media/too_big", too_big);

  return GLib.Test.run ();
}
