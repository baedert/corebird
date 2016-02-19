

void simple () {
  var loop = new GLib.MainLoop ();
  Twitter.get ().init ();

  Cairo.Surface? surface = null;
  surface = Twitter.get ().get_avatar (10, "http://i.imgur.com/GzdoOMu.jpg", (ava) => {
    assert (ava != null);

    loop.quit ();
  });

  assert (surface == null);

  loop.run ();
}

void cached () {
  var loop = new GLib.MainLoop ();
  Twitter.get ().init ();

  Cairo.Surface? surface = null;
  surface = Twitter.get ().get_avatar (10, "http://i.imgur.com/GzdoOMu.jpg", (ava) => {
    assert (ava != null);

    surface = Twitter.get ().get_avatar (10, "http://i.imgur.com/GzdoOMu.jpg", (ava) => {
      assert_not_reached ();
    });
    assert (surface != null);
    assert (surface == ava);

    loop.quit ();
  });

  assert (surface == null);

  loop.run ();
}

void double_download ()
{
  var loop = new GLib.MainLoop ();
  Twitter.get ().init ();

  Cairo.Surface? surface = null;
  Cairo.Surface? surface2 = null;
  surface = Twitter.get ().get_avatar (10, "http://i.imgur.com/GzdoOMu.jpg", (ava) => {
    assert (ava != null);
    surface = ava;
    loop.quit ();
  });
  assert (surface == null);

  surface2 = Twitter.get ().get_avatar (10, "http://i.imgur.com/GzdoOMu.jpg", (ava) => {
    assert (ava != null);
    surface2 = ava;
    assert (ava != null);
    assert (surface != null);
    assert (surface == surface2);
  });
  assert (surface2 == null); // Being downloaded by the previous call

  loop.run ();
}

int main (string[] args) {
  GLib.Test.init (ref args);
  Gtk.init (ref args);
  Utils.init_soup_session ();

  GLib.Test.add_func ("/avatar-download/simple", simple);
  GLib.Test.add_func ("/avatar-download/cached", cached);
  GLib.Test.add_func ("/avatar-download/double_download", double_download);

  /* We can't test load_avatar_for_user_id here since we can't
     properly use Accounts and their proxies... */


  return GLib.Test.run ();
}
