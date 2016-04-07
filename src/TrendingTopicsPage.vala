/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2015 Ricardo Borges Junior
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

 [GtkTemplate (ui = "/org/baedert/corebird/ui/trending-topics.ui")]
 public class TrendingTopicsPage : IPage, Gtk.Box {
  public int id { get; set; }
  public unowned Account account {get; set;}
  public unowned MainWindow main_window {get; set;}
  [GtkChild]
  private Gtk.Entry location_entry;
  [GtkChild]
  private Gtk.Button location_button;
  [GtkChild]
  private TweetListBox trend_list;

  private string location_name;
  private bool show_tweet;
  private Gtk.RadioButton radio_button;
  private Collect collect_obj;
  private int n_results = 0;
  private Location avaliable_locations;
  public DeltaUpdater delta_updater;
  private string trend_name;
  private bool update_header = true;
  private GLib.DateTime leave_time = new DateTime.from_unix_utc (0);


  public TrendingTopicsPage (int id, Account account, DeltaUpdater delta_updater) {
    this.id = id;
    this.account = account;
    this.delta_updater = delta_updater;
  }


  public void create_radio_button (Gtk.RadioButton? group) {
    radio_button = new BadgeRadioButton (group, "corebird-trending-topics-symbolic", _("Trending Topics"));
  }


  public Gtk.RadioButton? get_radio_button () {
    return radio_button;
  }


  public void on_join (int page_id, Bundle? args) {
    this.location_name = Settings.default_location ();
    var now = new DateTime.now_local ();

    set_location_completion ();

    location_button.clicked.connect (() => {
      trend_list.remove_all ();
      load_trends (location_entry.get_text ());
    });
    //update every 15 minutes
    TimeSpan difference = now.difference (this.leave_time);
    var minutes = (difference / TimeSpan.MINUTE);
    if(minutes >= 15) {
      trend_list.remove_all ();
      load_trends (location_name);
      this.leave_time = new GLib.DateTime.now_local ();
    }
  }


  public void load_trends (string location_name) {
    collect_obj = new Collect (0);
    collect_obj.finished.connect (show_entries);
    this.avaliable_locations = Location.instance ();
    int32 woeid = avaliable_locations.lookup(location_name);

    var call = account.proxy.new_call ();
    call.set_function ("1.1/trends/place.json");
    call.set_method ("GET");
    call.add_param ("id", woeid.to_string ());
    TweetUtils.load_threaded.begin (call, null, (_, res) => {
      Json.Node? root = null;
      try {
        root = TweetUtils.load_threaded.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        trend_list.set_error (e.message);
        if (!collect_obj.done)
          collect_obj.emit ();

        return;
      }
      var trends = root.get_array ().get_object_element (0).get_array_member ("trends");

      this.show_tweet = Settings.show_popular_trend_tweet ();
      trends.foreach_element ((array, index, node) => {
        var topic = node.get_object ();
        this.trend_name = topic.get_string_member("name");

        if (this.show_tweet) {
          string query = topic.get_string_member ("query");
          load_tweet (query);
          this.trend_list.set_header_func (header_func);
        }
        else {
          var label = header_label (this.trend_name);
          label.show ();
          this.trend_list.add (label);
        }
      });
      if (!collect_obj.done)
        collect_obj.emit ();
    });
  }


  private void load_tweet (string query) {

    var call = account.proxy.new_call ();
    call.set_function ("1.1/search/tweets.json");
    call.set_method ("GET");
    call.add_param ("q", query);
    call.add_param ("count", "1");
    call.add_param ("result_type", "popular");

      Json.Node? root = null;
      Json.Parser parser = new Json.Parser ();
      try {
        call.run();
        parser.load_from_data(call.get_payload ());
        root = parser.get_root ();
      } catch (GLib.Error e) {
        warning (e.message);
        trend_list.set_error (e.message);
        if (!collect_obj.done)
          collect_obj.emit ();

        return;
      }

      var now = new GLib.DateTime.now_local ();
      var statuses = root.get_object().get_array_member ("statuses");
      if (statuses.get_length () == 0 && n_results <= 0)
        n_results = -1;
      else
        n_results += (int)statuses.get_length ();

      if (n_results <= 0)
        trend_list.set_empty ();

      statuses.foreach_element ((array, index, node) => {
        var tweet = new Tweet ();
        tweet.load_from_json (node, now, account);

        var entry = new TweetListEntry (tweet, main_window, account);
        delta_updater.add (entry);
        if (!collect_obj.done)
          entry.visible = false;
        else
          entry.show ();

        trend_list.add (entry);
      });

      if (!collect_obj.done)
        collect_obj.emit ();
  }


  private void show_entries (GLib.Error? e) {
    if (e != null) {
      trend_list.set_error (e.message);
      trend_list.set_empty ();
      return;
    }

    trend_list.@foreach ((w) => w.show ());
  }


  private void header_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
    Gtk.Widget? header = row.get_header ();
    if (before == null && update_header) {
      header = header_label (this.trend_name);
      header.show ();
      row.set_header (header);
      update_header = false;
    }
    if (header == null && this.show_tweet) {
      header = header_label (this.trend_name);
      header.show ();
      row.set_header (header);
    }
  }


  private TextButton header_label (string label_text) {

    TextButton label = new TextButton (label_text);

    label.set_markup ("<span weight=\"bold\" size=\"large\">%s</span>".printf(label_text));
    label.margin = 6;
    label.xalign = 0;

    Bundle bundle = new Bundle ();
    label.clicked.connect ( () => {
      bundle.put_string ("query", label_text);
      this.main_window.main_widget.switch_page (Page.SEARCH, bundle);
    });

    return label;
  }


  public string? get_title () {
    return _("Trending Topics");
  }

  [GtkCallback]
  private void on_location_entry_activate () {
    trend_list.remove_all ();
    load_trends (this.location_entry.get_text ());
  }


  private void set_location_completion (){
    Gtk.EntryCompletion completion = new Gtk.EntryCompletion ();
    this.location_entry.set_completion(completion);

    Gtk.ListStore list_store = new Gtk.ListStore (2, typeof (string), typeof (string));
    completion.set_model (list_store);
    completion.set_text_column (0);
    var cell = new Gtk.CellRendererText ();
    completion.pack_start (cell, false);
    completion.add_attribute (cell, "text", 1);

    Gtk.TreeIter iter;
    this.avaliable_locations = Location.instance ();
    Place place = new Place ();
    string country;
    var locations_array = new Gee.HashMap<string, Place> ();
    locations_array = this.avaliable_locations.get_locations ();

    foreach (var location in locations_array.entries) {
        place = location.value;
        country = place.country;
        list_store.append (out iter);
        list_store.set (iter, 0, location.key, 1, country);
    }
  }


  public void on_leave () { }
 }
