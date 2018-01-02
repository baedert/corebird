void simple () {
  var texture = Twitter.no_avatar;
  var cache = new Cb.AvatarCache ();

  assert (cache.get_n_entries () == 0);
  cache.add (1337, texture, "some_url");
  assert (cache.get_n_entries () == 1);

  cache.increase_refcount_for_texture (texture);
  assert (cache.get_n_entries () == 1);

  cache.decrease_refcount_for_texture (texture);
  assert (cache.get_n_entries () == 0);
}

void deferred_texture () {
  var texture = Twitter.no_avatar;
  var cache = new Cb.AvatarCache ();

  cache.add (1337, null, "some_url");
  assert (cache.get_n_entries () == 1);

  bool found;
  var cached_texture = cache.get_texture_for_id (1337, out found);
  assert (cached_texture == null);
  assert (found);

  cache.set_avatar (1337, texture, "some_url");
  assert (cache.get_n_entries () == 1);
  cache.increase_refcount_for_texture (texture);

  cached_texture = cache.get_texture_for_id (1337, out found);
  assert (cached_texture == texture);
  assert (found);

  cache.decrease_refcount_for_texture (texture);
  assert (cache.get_n_entries () == 0);

  cached_texture = cache.get_texture_for_id (1337, out found);
  assert (cached_texture == null);
  assert (!found);
}

int main (string[] args) {
  GLib.Test.init (ref args);
  Twitter.get ().init ();

  GLib.Test.add_func ("/avatarcache/simple", simple);
  GLib.Test.add_func ("/avatarcache/deferred_texture", deferred_texture);

  return GLib.Test.run ();
}
