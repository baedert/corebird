
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
    var media2 = new Cb.Media ();
    media2.url = url;
    Cb.MediaDownloader.get_default ().load_async.begin (media2, () => {
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

  media = new Cb.Media ();
  media.url = url;
  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });

  media = new Cb.Media ();
  media.url = url;
  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });

  media = new Cb.Media ();
  media.url = url;
  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });

  media = new Cb.Media ();
  media.url = url;
  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    assert (!media.invalid);
    collect_obj.emit ();
  });

  media = new Cb.Media ();
  media.url = url;
  collect_obj.finished.connect (() => {
    main_loop.quit ();
  });

  main_loop.run ();
  assert (collect_obj.done);
}

void shutdown () {
  var main_loop = new GLib.MainLoop ();
  var url = "http://pbs.twimg.com/media/BiHRjmFCYAAEKFg.png";
  var media = new Cb.Media ();
  media.url = url;

  Cb.MediaDownloader.get_default ().load_async.begin (media, () => {
    var media2 = new Cb.Media ();
    media2.url = url;
    Cb.MediaDownloader.get_default ().load_async.begin (media2);
    Cb.MediaDownloader.get_default ().shutdown ();
    main_loop.quit ();
  });

  main_loop.run ();
}


int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Environment.set_variable ("GSETTINGS_BACKEND", "memory", true);
  Gtk.init ();
  Settings.init ();
  Dirs.create_dirs ();
  Utils.init_soup_session ();
  GLib.Test.add_func ("/media/normal-download", normal_download);
  GLib.Test.add_func ("/media/animation-download", animation_download);
  GLib.Test.add_func ("/media/download-twice", download_twice);
  GLib.Test.add_func ("/media/double-download", double_download);
  GLib.Test.add_func ("/media/shutdown", shutdown);



  int retval = GLib.Test.run ();

  Cb.MediaDownloader.get_default ().shutdown ();

  return retval;
}
