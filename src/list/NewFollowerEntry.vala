
using Gtk;


class NewFollowerEntry : Gtk.Box, ITwitterItem {
  public static const int TYPE = 2;
  private int64 date;
  public int64 sort_factor{
    get { return date; }
  }
  public bool seen{get;set; default=true;}

  private int count = 0;
  private string[] followers = new string[5];
  private Image follow_image = new Gtk.Image.from_file(DATADIR+"/follower.png");
  private Box right_box = new Box(Orientation.VERTICAL, 3);
  private Box avatar_box = new Box(Orientation.HORIZONTAL, 5);
  private Label follow_text = new Label("bla bla bla");

  public NewFollowerEntry () {
    GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 5);


    follow_image.valign = Align.START;
    this.pack_start(follow_image, false, false);


    right_box.pack_start(avatar_box, true, false);

    follow_text.xalign = 0.0f;
    follow_text.yalign = 0.0f;
    follow_text.use_markup = true;
    right_box.pack_end(follow_text, true, true);
    this.pack_start(right_box, true, true);

    this.show_all();
  }

  /** 
   * "Parses" the given text.
   * Format:
   * COUNT,FOLLOWER1[,FOLLOWER2,…]
   *
   * @param text The text to parse
   */
  public NewFollowerEntry.from_data(string text, int64 sort_factor) {
    this();
    this.date = sort_factor;
    string[] parts = text.split(",");
    int count = int.parse(parts[0]);

    GLib.return_if_fail(parts.length == count+1);
    for(int i = 0; i < count; i++)
      add_follower_from_name (parts[1+i]);

    set_new_label_text();
  }


  public void add_follower (Json.Object root) {
    this.date = Utils.parse_date (root.get_string_member("created_at")).to_unix();
    Json.Object source = root.get_object_member("source");
    string avatar_url = source.get_string_member ("profile_image_url");
    avatar_url = avatar_url.replace("_normal", "_mini");
    string name = source.get_string_member("screen_name");
    string mini_thumb_path = Utils.user_file("assets/avatars/mini_thumb_"+name+".png");
    followers[count] = name;  
  
    ImageButton avatar_button = new ImageButton();
    avatar_box.pack_start(avatar_button, false, false);
    Utils.download_file_async.begin(avatar_url,mini_thumb_path,
    () => {
    // TODO: This sucks
      avatar_button.set_bg(new Gdk.Pixbuf.from_file(mini_thumb_path));
      avatar_button.show();
    });
    count++;
    set_new_label_text();
    save();
  }

  /**
   * @param name The screen_name of the user
   */
  private void add_follower_from_name (string name){
    string mini_thumb_path = Utils.user_file("assets/avatars/mini_thumb_"+name+".png");
    if(FileUtils.test(mini_thumb_path, FileTest.EXISTS)) {
      ImageButton avatar_button = new ImageButton();
      avatar_button.set_bg(new Gdk.Pixbuf.from_file(mini_thumb_path));
      avatar_box.pack_start(avatar_button, false, false);
    }
    followers[count] = name;
    count++;
  }

  // TODO: Use StringBUilder
  private void set_new_label_text() {
    string s = "";
    for(int i = 0; i < count-1; i++)
      s += "<a href='@%s'>@%s</a>,".printf(followers[i], followers[i]);
    
    if(count >= 2)
      s += "<a href='@%s'>@%s</a> and".printf(followers[count-2], followers[count-2]);
    message("Count: %d", count); 
    s += "<a href='@%s'>@%s</a> followed you".printf(followers[count-1], followers[count-1]);
    follow_text.label = s;
  }


  public void save() {
    StringBuilder data = new StringBuilder();
    data.append(count.to_string());
    for(int i = 0; i < count; i++){
      data.append_c(',');
      data.append(followers[i]);
    }
    string s = @"INSERT OR REPLACE INTO `cache`
        (`sort_factor`, `type`, `data`) VALUES ('$date', '$TYPE', '$(data.str)');";
    Corebird.db.execute(s);
  }
}
