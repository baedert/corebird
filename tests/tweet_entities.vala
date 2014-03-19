

void real_text () {


}




int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/tweet-entities/real-text", real_text);

  return GLib.Test.run ();
}
