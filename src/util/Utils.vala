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


enum Page {
  STREAM = 0,
  MENTIONS,
  FAVORITES,
  DM_THREADS,
  LISTS,
  FILTERS,
  SEARCH,
  PROFILE,
  TWEET_INFO,
  DM,
  LIST_STATUSES,

  PREVIOUS = 1024,
  NEXT = 2048
}

static Soup.Session SOUP_SESSION = null;

const int TRANSITION_DURATION = 200 * 1000;

#if DEBUG
public string __class_name (GLib.Object o) {
  return GLib.Type.from_instance (o).name ();
}
#endif

void default_header_func (Gtk.ListBoxRow  row,
                          Gtk.ListBoxRow? row_before)
{
  if (row_before == null) {
    row.set_header (null);
    return;
  }

  Gtk.Widget? header = row.get_header ();
  if (header != null) {
    return;
  }

  header = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
  header.show ();
  row.set_header (header);
}



Cairo.Surface? load_surface (string path)
{
  try {
    var p = new Gdk.Pixbuf.from_file (path);
    var s = Gdk.cairo_surface_create_from_pixbuf (p, 1, null);
    return s;
  } catch (GLib.Error e) {
    warning (e.message);
    return null;
  }
}


void write_surface (Cairo.Surface surface,
                    string        path)
{
  var status = surface.write_to_png (path);

  if (status != Cairo.Status.SUCCESS) {
    warning ("Could not write surface to '%s': %s", path, status.to_string ());
  }
}

Cairo.Surface scale_surface (Cairo.ImageSurface input,
                             int                output_width,
                             int                output_height)
{
  int old_width  = input.get_width ();
  int old_height = input.get_height ();

  if (old_width == output_width && old_height == output_height)
    return input;

  Cairo.Surface new_surface = new Cairo.Surface.similar_image (input, Cairo.Format.ARGB32,
                                                               output_width, output_height);


  /* http://lists.cairographics.org/archives/cairo/2006-January/006178.html */

  Cairo.Context ct = new Cairo.Context (new_surface);

  ct.scale ((double)output_width / old_width, (double)output_height / old_height);
  ct.set_source_surface (input, 0, 0);
  ct.get_source ().set_extend (Cairo.Extend.PAD);
  ct.set_operator (Cairo.Operator.SOURCE);
  ct.paint ();

  return new_surface;
}


inline double ease_out_cubic (double t) {
  double p = t - 1;
  return p * p * p +1;
}

string rest_call_to_string (Rest.ProxyCall call)
{
  StringBuilder builder = new StringBuilder ();
  builder.append (call.get_method ());
  builder.append (" ");
  builder.append (call.get_function ());

  GLib.HashTable<string, string> params = call.get_params ().as_string_hash_table ();

  if (params.size () > 0) {
    builder.append ("?");

    foreach (unowned string key in params.get_keys ()) {
      // This doesn't work for the last param but whatever.
      builder.append (key).append ("=").append (params.get (key)).append ("&");
    }
  }

  return builder.str;
}


namespace Utils {
  /**
  * Parses a date given by Twitter in the form 'Wed Jun 20 19:01:28 +0000 2012'
  * and creates a GLib.DateTime in the local time zone to work with.
  *
  * @return The given date as GLib.DateTime in the current time zone.
  */
  GLib.DateTime parse_date (string input) {
    if (input.length == 0) {
      return new GLib.DateTime.now_local ();
    }
    string month_str = input.substring (4, 3);
    int day          = int.parse (input.substring (8, 2));
    int year         = int.parse (input.substring (input.length - 4));
    string timezone  = input.substring (20, 5);

    int month = -1;
    switch (month_str) {
      case "Jan": month = 1;  break;
      case "Feb": month = 2;  break;
      case "Mar": month = 3;  break;
      case "Apr": month = 4;  break;
      case "May": month = 5;  break;
      case "Jun": month = 6;  break;
      case "Jul": month = 7;  break;
      case "Aug": month = 8;  break;
      case "Sep": month = 9;  break;
      case "Oct": month = 10; break;
      case "Nov": month = 11; break;
      case "Dec": month = 12; break;
    }

    int hour   = int.parse (input.substring (11, 2));
    int minute = int.parse (input.substring (14, 2));
    int second = int.parse (input.substring (17, 2));
    GLib.DateTime dt = new GLib.DateTime (new GLib.TimeZone(timezone),
                                          year, month, day, hour, minute, second);
    return dt.to_timezone (new TimeZone.local ());
  }

  /**
   * Calculates an easily human-readable version of the time difference between
   * time and now.
   * Example: "5m" or "3h" or "26m" or "16 Nov"
   */
  public string get_time_delta (GLib.DateTime time, GLib.DateTime now) {
    //diff is the time difference in microseconds
    GLib.TimeSpan diff = now.difference (time);

    int minutes = (int)(diff / 1000.0 / 1000.0 / 60.0);
    if (minutes == 0)
      return _("Now");
    else if (minutes < 60)
      return _("%dm").printf (minutes);

    int hours = (int)(minutes / 60.0);
    if (hours < 24)
      return _("%dh").printf (hours);

    string month = time.format ("%b");
    //If 'time' was over 24 hours ago, we just return that
    return "%d %s".printf (time.get_day_of_month (), month);
  }


  /**
   * Extracts the actual filename out of a given path.
   * E.g. for /home/foo/bar.png, it will return "bar.png"
   *
   * @return The filename of the given path, and nothing else.
   */
  string get_file_name (string path) {
    return path.substring (path.last_index_of_char ('/') + 1);
  }

  /**
   * Extracts the file type from the given path.
   * E.g. for http://foo.org/bar/bla.png, this will just return "png"
   */
  public string get_file_type (string path) {
    string filename = get_file_name (path);
    if (filename.index_of_char ('.') == -1)
      return "";
    string type = filename.substring (filename.last_index_of_char ('.') + 1);
    type = type.down ();
    if (type == "jpg")
      return "jpeg";
    return type;
  }

  /**
   * Shows an error dialog with the given error message
   *
   * @param message The error message to show
   */
  void show_error_dialog (string message, Gtk.Window? transient_for) {
    var dialog = new Gtk.MessageDialog (transient_for, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                        Gtk.MessageType.ERROR, Gtk.ButtonsType.OK,
                                        "%s", message);

    dialog.response.connect ((id) => {
      if (id == Gtk.ResponseType.OK)
        dialog.destroy ();
    });

    dialog.show ();
  }

  /**
   * Shows the given json error object in an error dialog.
   * Example object data:
   * {"errors":[{"message":"Could not authenticate you","code":32}]
   *
   * @param json_data The json data to show
   * @param alternative If the given json data is not valid,
   *                    show this alternative error message.
   */
  void show_error_object (string?     json_data,
                          string      alternative,
                          int         line,
                          string      file,
                          Gtk.Window? transient_for = null) {
    string error_message = "Exception: %s in %s:%d".printf (alternative, file, line);
    if (json_data == null) {
      show_error_dialog (error_message, transient_for);
      return;
    }

    var parser = new Json.Parser ();
    StringBuilder sb = new StringBuilder ();
    try {
      parser.load_from_data (json_data);
    } catch (GLib.Error e) {
      show_error_dialog (error_message, transient_for);
      return;
    }

    if (parser.get_root ().get_node_type () != Json.NodeType.OBJECT) {
      show_error_dialog (error_message, transient_for);
      return;
    }

    var root = parser.get_root ().get_object ();
    if (root.has_member ("error") &&
        root.get_member ("error").get_node_type () == Json.NodeType.VALUE) {
      message (json_data);
      show_error_dialog (root.get_member ("error").get_string (), transient_for);
      return;
    }

    if (root.get_member ("errors").get_node_type () == Json.NodeType.VALUE) {
      message (json_data);
      show_error_dialog (root.get_member ("errors").get_string (), transient_for);
      return;
    }

    var errors = root.get_array_member ("errors");
    if (errors.get_length () == 1) {
      var err = errors.get_object_element (0);
      sb.append (err.get_int_member ("code").to_string ()).append (": ")
        .append (err.get_string_member ("message"))
        .append ("(").append (file).append (":").append (line.to_string ()).append (")");
    } else {
      sb.append ("<ul>");
      errors.foreach_element ((arr, index, node) => {
        var obj = node.get_object ();
        sb.append ("<li>").append (obj.get_int_member ("code").to_string ())
          .append (": ")
          .append (obj.get_string_member ("message")).append ("</li>");
      });
      sb.append ("</ul>");
    }
    error_message = sb.str;

    critical (json_data);
    show_error_dialog (error_message, transient_for);
  }

  async Gdk.Pixbuf? download_pixbuf (string            url,
                                     GLib.Cancellable? cancellable = null) {

    Gdk.Pixbuf? result = null;
    var msg = new Soup.Message ("GET", url);
    GLib.SourceFunc cb = download_pixbuf.callback;

    SOUP_SESSION.queue_message (msg, (_s, _msg) => {
      if (cancellable.is_cancelled ()) {
        cb ();
        return;
      }
      try {
        var in_stream = new MemoryInputStream.from_data (_msg.response_body.data,
                                                         GLib.g_free);
        result = new Gdk.Pixbuf.from_stream (in_stream, cancellable);
      } catch (GLib.Error e) {
        warning (e.message);
      } finally {
        cb ();
      }
    });
    yield;

    return result;
  }

  string unescape_html (string input) {
    string back = input.replace ("&lt;", "<");
    back = back.replace ("&gt;", ">");
    back = back.replace ("&amp;", "&");
    return back;
  }


  public void load_custom_icons () {
    var icon_theme  = Gtk.IconTheme.get_default ();
    icon_theme.add_resource_path ("/org/baedert/corebird/data/");
  }

  public void load_custom_css () {
    var provider = new Gtk.CssProvider ();
    provider.load_from_resource ("/org/baedert/corebird/ui/style.css");
    Gtk.StyleContext.add_provider_for_screen ((!)Gdk.Screen.get_default (),
                                              provider,
                                              Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
  }

  public void init_soup_session () {
    assert (SOUP_SESSION == null);
    SOUP_SESSION = new Soup.Session ();
  }

  string capitalize (string s) {
    string back = s;
    if (s.get_char (0).islower ()) {
      back = s.get_char (0).toupper ().to_string () + s.substring (1);
    }
    return back;
  }

  public int get_json_array_size (Json.Object node, string object_name) {
    if (!node.has_member (object_name))
      return 0;

    return (int)node.get_array_member (object_name).get_length ();
  }

  /**
   * Checks if @value is existing in @node and if it is, non-null.
   *
   * Returns TRUE if the @value does both exist and is non-null.
   */
  public bool usable_json_value (Json.Object node, string value_name) {
    if (!node.has_member (value_name))
        return false;

    return !node.get_null_member (value_name);
  }

  public void update_startup_account (string old_screen_name,
                                      string new_screen_name) {
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    string[] new_startup_accounts = new string[startup_accounts.length];

    for (int i = 0; i < startup_accounts.length; i ++) {
      if (startup_accounts[i] != old_screen_name)
        new_startup_accounts[i] = startup_accounts[i];
      else
        new_startup_accounts[i] = new_screen_name;
    }

    Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
  }


  public Filter create_persistent_filter (string content, Account account) {
    int id = (int)account.db.insert ("filters")
                               .val ("content", content)
                               .run();
    Filter f = new Filter (content);
    f.id = id;
    account.add_filter (f);

    return f;
  }
}
