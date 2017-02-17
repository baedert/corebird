void simple () {
  var surface = new Cairo.ImageSurface (Cairo.Format.A8, 2, 2);
  var cache = new Cb.AvatarCache ();

  assert (cache.get_n_entries () == 0);
  cache.add (1337, surface, "some_url");
  assert (cache.get_n_entries () == 1);

  cache.increase_refcount_for_surface (surface);
  assert (cache.get_n_entries () == 1);

  cache.decrease_refcount_for_surface (surface);
  assert (cache.get_n_entries () == 0);
}

void deferred_surface () {
  var surface = new Cairo.ImageSurface (Cairo.Format.A8, 2, 2);
  var cache = new Cb.AvatarCache ();

  cache.add (1337, null, "some_url");
  assert (cache.get_n_entries () == 1);

  bool found;
  var cached_surface = cache.get_surface_for_id (1337, out found);
  assert (cached_surface == null);
  assert (found);

  cache.set_avatar (1337, surface, "some_url");
  assert (cache.get_n_entries () == 1);
  cache.increase_refcount_for_surface (surface);

  cached_surface = cache.get_surface_for_id (1337, out found);
  assert (cached_surface == surface);
  assert (found);

  cache.decrease_refcount_for_surface (surface);
  assert (cache.get_n_entries () == 0);

  cached_surface = cache.get_surface_for_id (1337, out found);
  assert (cached_surface == null);
  assert (!found);
}

int main (string[] args) {
  GLib.Test.init (ref args);

  GLib.Test.add_func ("/avatarcache/simple", simple);
  GLib.Test.add_func ("/avatarcache/deferred_surface", deferred_surface);

  return GLib.Test.run ();
}
