



using Gtk;

class UserCompletion : GLib.Object {
  public signal void start_completion ();
  public signal void populate_completion (string value);
  private unowned GLib.Object obj;
  private unowned Account account;
  private string name_property_name;
  private int num_results;

  public UserCompletion (Account account, int num_results) {
    this.account = account;
    this.num_results = num_results;
  }

  public void connect_to (GLib.Object obj, string name_property_name) {
    this.obj = obj;
    this.name_property_name = name_property_name;
    obj.notify[name_property_name].connect (prop_changed);
  }

  [CCode (instance_pos = -1)]
  private void prop_changed () {
    string name;
    obj.get (name_property_name, out name);
    start_completion ();

    for (int i = 0; i < 5; i++)
      populate_completion ("foo %d".printf (i));
  }
}
