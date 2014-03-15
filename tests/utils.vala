


void file_type () {
  string p = "foobar.png";
  assert (Utils.get_file_type (p) == "png");

  p = ".hidden.bar";
  assert (Utils.get_file_type (p) == "bar");

  p = "foo";
  assert (Utils.get_file_type (p) == "");

  p = "some.pointy.name.txt";
  assert (Utils.get_file_type (p) == "txt");

}


int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/utils/file-type", file_type);


  return GLib.Test.run ();
}
