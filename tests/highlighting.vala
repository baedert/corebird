

void mention () {
  Gtk.TextBuffer buffer = new Gtk.TextBuffer (null);
  buffer.apply_tag.connect ((buffer, tag, start, end) => {
    string s = buffer.get_text (start, end, false);
    assert (s == "@bla");
  });
  buffer.create_tag ("mention",  null);
  buffer.set_text ("A @bla B");
  TweetUtils.annotate_text (buffer);
}




void underline () {
  Gtk.TextBuffer buffer = new Gtk.TextBuffer (null);
  buffer.apply_tag.connect ((buffer, tag, start, end) => {
    string s = buffer.get_text (start, end, false);
    message ("Underline mention: %s", s);
    assert (s == "@bla_foo");
  });
  buffer.create_tag ("mention",  null);
  buffer.set_text ("A @bla_foo B");
  TweetUtils.annotate_text (buffer);
}

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
  GLib.Test.add_func ("/highlighting/underline", underline);
  GLib.Test.add_func ("/highlighting/mention", mention);

  GLib.Test.run ();
}
