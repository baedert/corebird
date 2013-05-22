
using Gtk;


class NewFollowerEntry : Gtk.Box, ITwitterItem {
  private int64 date;
  public int64 sort_factor{
    get { return date; }
  }

  public NewFollowerEntry (Json.Object root) {
    GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 5);
    this.date = Utils.parse_date (root.get_string_member("created_at")).to_unix();
    // source is the new follower
    Json.Object source = root.get_object_member ("source");
    string avatar_url = source.get_string_member("profile_image_url");

    Label l = new Label("@%s followed you".printf(source.get_string_member("screen_name")));
    this.pack_start(l, false, false);


    this.show_all();
  }

}
