
void normal_download () {
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var main_loop = new GLib.MainLoop ();
  var media = new Cb.Media ();
  media.url = url;

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    main_loop.quit ();
  });

  main_loop.run ();
}


void animation_download () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://i.imgur.com/rgF0Czu.gif";
  var media = new Cb.Media ();
  media.url = url;

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    main_loop.quit ();
  });

  main_loop.run ();
}

void download_twice () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var media = new Cb.Media ();
  media.url = url;

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
      main_loop.quit ();
    });
  });

  main_loop.run ();
}

void no_thumbnail () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var media = new Cb.Media ();
  media.url = url;

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
      main_loop.quit ();
    });
  });
  main_loop.run ();
}


void no_media () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var media = new Cb.Media ();
  media.url = url;

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
      main_loop.quit ();
    });
  });

  main_loop.run ();
}

void double_download () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var media = new Cb.Media ();
  media.url = url;

  var collect_obj = new Collect (5);

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });


  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
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

  return GLib.Test.run ();
}
