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


public enum Page {
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
public unowned string __class_name (GLib.Object o) {
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

int twitter_item_sort_func (Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
  if(((Cb.TwitterItem)a).get_sort_factor () < ((Cb.TwitterItem)b).get_sort_factor ())
    return 1;
  return -1;
}

int twitter_item_sort_func_inv (Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
  if(((Cb.TwitterItem)a).get_sort_factor () < ((Cb.TwitterItem)b).get_sort_factor ())
    return -1;
  return 1;
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

inline double ease_out_cubic (double t) {
  double p = t - 1;
  return p * p * p +1;
}

namespace Utils {
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
    if (time.get_year () == now.get_year ()) {
      //If 'time' was over 24 hours ago, we just return that
      return "%d %s".printf (time.get_day_of_month (), month);
    } else {
      return "%d %s %d".printf (time.get_day_of_month (), month, time.get_year ());
    }
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

    /* Hacky way to get the label selectable */
    ((Gtk.Label)(((Gtk.Container)dialog.get_message_area ()).get_children ().nth_data (0))).set_selectable (true);

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

    if (root.has_member ("errors") &&
        root.get_member ("errors").get_node_type () == Json.NodeType.VALUE) {
      message (json_data);
      show_error_dialog (root.get_member ("errors").get_string (), transient_for);
      return;
    }

    if (!root.has_member ("errors")) {
      show_error_dialog (error_message, transient_for);
      return;
    }

    var errors = root.get_array_member ("errors");
    if (errors.get_length () == 1) {
      var err = errors.get_object_element (0);
      sb.append (err.get_int_member ("code").to_string ()).append (": ")
        .append (err.get_string_member ("message"))
        .append ("(").append (file).append (":").append (line.to_string ()).append (")");
    } else if (errors.get_length () > 1) {
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


  public Cb.Filter create_persistent_filter (string content, Account account) {
    int id = (int)account.db.insert ("filters")
                               .val ("content", content)
                               .run();
    Cb.Filter f = new Cb.Filter (content);
    f.set_id (id);
    account.add_filter (f);

    return f;
  }

  public string get_media_display_name (Cb.Media media) {
    unowned string url = media.target_url ?? media.url;
    int last_slash_index = url.last_index_of_char ('/');

    string filename = url.substring (last_slash_index + 1);
    filename = filename.replace (":orig", "");

    int last_dot_index = filename.last_index_of_char ('.');
    if (last_dot_index == -1) {
      // No file extension, guess!
      if (media.is_video ()) {
        filename += ".mp4";
      } else {
        filename += ".jpg";
      }
    }

    return filename;
  }

  public async void download_file (string url, GLib.OutputStream out_stream) {
    var msg = new Soup.Message ("GET", url);
    GLib.SourceFunc cb = download_file.callback;

    SOUP_SESSION.queue_message (msg, (_s, _msg) => {
      try {
        var in_stream = new MemoryInputStream.from_data (_msg.response_body.data,
                                                         GLib.g_free);

        out_stream.splice (in_stream,
                           GLib.OutputStreamSpliceFlags.CLOSE_SOURCE |
                           GLib.OutputStreamSpliceFlags.CLOSE_TARGET,
                           null);
      } catch (GLib.Error e) {
        warning (e.message);
      } finally {
        cb ();
      }
    });
    yield;
  }
}
