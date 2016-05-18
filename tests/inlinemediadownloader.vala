
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

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
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

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
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

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
      // NOTE: We are *not* deleting the just downloaded file here
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


  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    // Delete the thumbnail
    // Download again
    InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
                                                   //assert (false);
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



  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
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





  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    // gets set anyway
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




  var collect_obj = new Collect (5);

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });

  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });
  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });
  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });
  InlineMediaDownloader.get ().load_media.begin (t.source_tweet, media, () => {
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
  GLib.Test.add_func ("/media/normal-download", normal_download);
  GLib.Test.add_func ("/media/animation-download", animation_download);
  GLib.Test.add_func ("/media/download-twice", download_twice);
  GLib.Test.add_func ("/media/no-thumbnail", no_thumbnail);
  GLib.Test.add_func ("/media/no-media", no_media);
  GLib.Test.add_func ("/media/double-download", double_download);
  /* Keep this one at the bottom! */
  GLib.Test.add_func ("/media/too-big", too_big);

  return GLib.Test.run ();
}
