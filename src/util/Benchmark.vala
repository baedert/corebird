





namespace Benchmark {
  public class Bench {
    public string name;
    public GLib.DateTime first;
    public void stop () {
      var ts = new GLib.DateTime.now_local ().difference (first);
      int64 ms = (ts / 1000);

      message (@"$(this.name) took $ms ms");
    }
  }


  public Bench start (string name) {
    var b = new Bench ();

    b.name = name;
    b.first = new GLib.DateTime.now_local ();
    return b;
  }
}
