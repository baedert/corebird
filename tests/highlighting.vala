

 // UTIL {{{

Gtk.TextBuffer create_buffer () {
  var buffer = new Gtk.TextBuffer (null);
  buffer.create_tag ("mention");
  buffer.create_tag ("link");
  buffer.create_tag ("hashtag");

  return buffer;
}

// }}}

void normal () {
  Gtk.TextBuffer buffer = create_buffer ();
  buffer.set_text ("foobar @blabla");

  buffer.apply_tag.connect ((tag, start, end) => {
    string mention = buffer.get_text (start, end, false);
    assert (mention == "@blabla");
    assert (tag.name == "mention");
  });

  TweetUtils.annotate_text (buffer);
}


void main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/highlighting/normal", normal);

  GLib.Test.run ();
}
