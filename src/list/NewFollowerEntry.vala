/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;


class NewFollowerEntry : Gtk.ListBoxRow, ITwitterItem {
  public static const int TYPE = 2;
  private int64 date;
  public int64 sort_factor{
    get { return date; }
  }
  public bool seen{get;set; default=true;}

  private int64 id;
  private int count = 0;
  private string[] followers  = new string[5];
  private Box main_box        = new Box(Orientation.HORIZONTAL, 5);
  private Image follow_image  = new Gtk.Image.from_file(DATADIR+"/follower.png");
  private Box right_box       = new Box(Orientation.VERTICAL, 3);
  private Box avatar_box      = new Box(Orientation.HORIZONTAL, 5);
  private Label follow_text   = new Label("bla bla bla");

  public NewFollowerEntry () {
    follow_image.valign = Align.START;
    main_box.pack_start(follow_image, false, false);


    right_box.pack_start(avatar_box, true, false);

    follow_text.xalign = 0.0f;
    follow_text.yalign = 0.0f;
    follow_text.use_markup = true;
    follow_text.wrap_mode = Pango.WrapMode.WORD_CHAR;
    right_box.pack_end(follow_text, true, true);
    main_box.pack_start(right_box, true, true);

    this.add (main_box);
    this.show_all();
  }

  /**
   * "Parses" the given text.
   * Format:
   * COUNT,FOLLOWER1[,FOLLOWER2,…]
   *
   * @param text The text to parse
   */
  public NewFollowerEntry.from_data(int id, string text, int64 sort_factor) {
    this();
    this.date = sort_factor;
    this.id = id;
    string[] parts = text.split(",");
    int count = int.parse(parts[0]);

    for(int i = 0; i < count; i++)
      add_follower_from_name (parts[1+i]);

    set_new_label_text();
  }

  /**
   * Add a follower to the NewFollowerEntry.
   *
   * @param root The root Json-object retrieved from Twitter.
   *
   */
  public bool add_follower (Json.Object root) {
    Json.Object source = root.get_object_member("source");
    string name = source.get_string_member("screen_name");

    //If the same user quickly follows/unfollows/follows/… the user, don't show him twice
   for(int i = 0; i < count; i++)
      if(followers[i] == name)
        return false;

    this.date = Utils.parse_date (root.get_string_member("created_at")).to_unix();
    string avatar_url = source.get_string_member ("profile_image_url");
    avatar_url = avatar_url.replace("_normal", "_mini");
        string mini_thumb_path = Utils.user_file("assets/avatars/mini_thumb_"+name+".png");
    followers[count] = name;

    PixbufButton avatar_button = new PixbufButton();
    avatar_box.pack_start(avatar_button, false, false);
    Utils.download_file_async.begin(avatar_url,mini_thumb_path,
    () => {
    // TODO: This sucks
      try {
        avatar_button.set_bg(new Gdk.Pixbuf.from_file(mini_thumb_path));
      } catch (GLib.Error e) {
        warning (e.message);
      }
      avatar_button.show();
    });


    count++;
    set_new_label_text();
    save();
    return true;
  }

  /**
   * @param name The screen_name of the user
   */
  private void add_follower_from_name (string name){
    string mini_thumb_path = Utils.user_file("assets/avatars/mini_thumb_"+name+".png");
    if(FileUtils.test(mini_thumb_path, FileTest.EXISTS)) {
      PixbufButton avatar_button = new PixbufButton();
      try {
        avatar_button.set_bg(new Gdk.Pixbuf.from_file(mini_thumb_path));
      } catch (GLib.Error e) {
        warning (e.message);
      }
      avatar_box.pack_start(avatar_button, false, false);
    }
    followers[count] = name;
    count++;
  }

  /**
   * Recalculates the text of the follow_text GtkLabel
   */
  private void set_new_label_text() {
    string s = "";
    for(int i = 0; i < count-2; i++)
      s += "<a href='@%s'>@%s</a>, ".printf(followers[i], followers[i]);

    if(count >= 2)
      s += "<a href='@%s'>@%s</a> and ".printf(followers[count-2], followers[count-2]);

    s += "<a href='@%s'>@%s</a> followed you".printf(followers[count-1], followers[count-1]);
    follow_text.label = s;
  }

  /**
   *
   * Saves(or updates) the entry in the cache table
   */
  public void save() {
    StringBuilder data = new StringBuilder();
    data.append(count.to_string());
    for(int i = 0; i < count; i++){
      data.append_c(',');
      data.append(followers[i]);
    }
    string param_string = @" INTO `cache` (`sort_factor`, `type`, `data`) VALUES ('$date', '$TYPE', '$(data.str)');";

    try {
      if(id == -1){
        SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db,
                    "INSERT"+param_string);
        this.id = q.execute_insert();
      } else {
        Corebird.db.execute(
         @"INSERT OR REPLACE INTO `cache` (`id`, `sort_factor`, `type`, `data`) VALUES ('$id', '$date', '$TYPE', '$(data.str)');");
      }
    } catch (SQLHeavy.Error e) {
      critical (e.message);
    }
  }
}
