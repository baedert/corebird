
class TestItem : GLib.Object, Cb.TwitterItem {
  int64 timestamp;
  int64 sort_factor;
  GLib.TimeSpan last_timediff;

  public TestItem (int64 a, int64 b) {
    timestamp = a;
    sort_factor = b;
  }

  public int64 get_sort_factor () {
    return sort_factor;
  }

  public int64 get_timestamp () {
    return timestamp;
  }

  public int update_time_delta (GLib.DateTime? now = null) {
    return 0;
  }

  public void set_last_set_timediff (GLib.TimeSpan span) {
    this.last_timediff = span;
  }

  public GLib.TimeSpan get_last_set_timediff () {
    return this.last_timediff;
  }
}


void simple () {
  var a = new TestItem (1, 2);
  var b = new TestItem (10, 20);

  assert (a.get_timestamp () == 1);
  assert (a.get_sort_factor () == 2);

  assert (b.get_timestamp () == 10);
  assert (b.get_sort_factor () == 20);

  a.set_last_set_timediff (100);
  b.set_last_set_timediff (1000);

  message ("a: %s", a.get_last_set_timediff ().to_string ());
  message ("b: %s", b.get_last_set_timediff ().to_string ());

  assert (a.get_last_set_timediff () == 100);
  assert (b.get_last_set_timediff () == 1000);
}

int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/tweetitem/simple", simple);

  return GLib.Test.run ();
}
