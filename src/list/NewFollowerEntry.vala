
using Gtk;


class NewFollowerEntry : Gtk.Box, ITwitterItem {
  private int64 date;
  public int64 sort_factor{
    get { return date; }
  }
  public bool seen{get;set; default=true;}

  private Image follow_image = new Gtk.Image.from_file(DATADIR+"/follower.png");
  private Box right_box = new Box(Orientation.VERTICAL, 3);

  public NewFollowerEntry (Json.Object root) {
    GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 5);
    this.date = Utils.parse_date (root.get_string_member("created_at")).to_unix();
    // source is the new follower
    Json.Object source = root.get_object_member ("source");
    string avatar_url = source.get_string_member("profile_image_url");

    Label l = new Label("@%s followed you".printf(source.get_string_member("screen_name")));

    follow_image.valign = Align.START;
    this.pack_start(follow_image, false, false);

    l.xalign = 0.0f;
    l.yalign = 0.0f;
    right_box.pack_end(l, true, true);
    this.pack_start(right_box, true, true);


    this.show_all();
  }

}
