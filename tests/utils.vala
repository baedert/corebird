


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


void time_delta () {
  var now = new GLib.DateTime.now_local ();
  var then = now.add (-GLib.TimeSpan.MINUTE * 3);
  string delta = Utils.get_time_delta (then, now);
  assert (delta == "3m");

  then = now;
  delta = Utils.get_time_delta (then, now);
  assert (delta == "Now");

  then = now.add (-GLib.TimeSpan.HOUR * 20);
  delta = Utils.get_time_delta (then, now);
  assert (delta == "20h");

}



int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/utils/file-type", file_type);
  GLib.Test.add_func ("/utils/time-delta", time_delta);


  return GLib.Test.run ();
}
