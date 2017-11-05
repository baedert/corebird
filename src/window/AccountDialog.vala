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

[GtkTemplate (ui = "/org/baedert/corebird/ui/account-dialog.ui")]
public class AccountDialog : Gtk.Window {
  private const int MAX_DESCRIPTION_LENGTH = 160;
  private const string PAGE_NORMAL = "normal";
  private const string PAGE_DELETE = "delete";
  [GtkChild]
  private Gtk.Entry name_entry;
  [GtkChild]
  private AvatarBannerWidget avatar_banner_widget;
  [GtkChild]
  private Gtk.Stack delete_stack;
  [GtkChild]
  private Gtk.Switch autostart_switch;
  [GtkChild]
  private Gtk.Entry website_entry;
  [GtkChild]
  private Cb.TextView description_text_view;
  [GtkChild]
  private CropWidget crop_widget;
  [GtkChild]
  private Gtk.Stack content_stack;
  [GtkChild]
  private Gtk.Box info_box;
  [GtkChild]
  private Gtk.Label error_label;
  [GtkChild]
  private Gtk.Button save_button;
  private Gtk.Label description_length_label;

  private unowned Account account;
  private string old_user_name;
  private string old_description;
  private string old_website;
  private Gdk.Pixbuf? new_avatar = null;
  private Gdk.Pixbuf? new_banner = null;

  private int old_width = 0;
  private int old_height = 0;

  private bool account_was_not_initied = false;


  public AccountDialog (Account account) {
    this.account = account;
    name_entry.text = account.name;
    avatar_banner_widget.set_account (account);
    description_text_view.set_account (account);
    set_transient_data (account.website, account.description);

    autostart_switch.freeze_notify ();
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    foreach (unowned string acc in startup_accounts) {
      if (acc == this.account.screen_name) {
        autostart_switch.active = true;
        break;
      }
    }
    autostart_switch.thaw_notify ();

    avatar_banner_widget.avatar_changed.connect ((p) => {
       new_avatar = p;
    });

    avatar_banner_widget.banner_changed.connect ((b) => {
      new_banner = b;
    });

    if (account.proxy == null) {
      account_was_not_initied = true;
      account.init_proxy ();
      account.query_user_info_by_screen_name.begin (null, (obj, res) => {
        set_transient_data (account.website, account.description);
      });
    }

    Gtk.AccelGroup ag = new Gtk.AccelGroup ();
    ag.connect (Gdk.Key.Escape, 0, Gtk.AccelFlags.LOCKED, escape_pressed_cb);

    description_text_view.changed.connect (update_description_length);

    this.add_accel_group (ag);

    warning ("The length label here looks stupid");
    description_length_label = new Gtk.Label ("");
    description_length_label.get_style_context ().add_class ("dim-label");
    description_text_view.add_widget (description_length_label);
    this.update_description_length ();
  }

  private void update_description_length () {
    int length = description_text_view.get_text ().length;
    description_length_label.label = "%d/160".printf (length);

    if (length > MAX_DESCRIPTION_LENGTH) {
      save_button.sensitive = false;
    } else {
      save_button.sensitive = true;
    }
  }

  public override void destroy () {
    if (account != null) {
      if (account_was_not_initied) {
        account.uninit ();
      }

      account = null;
    }

    base.destroy ();
  }

  private bool escape_pressed_cb () {
    this.destroy ();
    return Gdk.EVENT_STOP;
  }

  private void set_transient_data (string? website, string? description) {
    website_entry.text = account.website ?? "";
    old_user_name = account.name;
    old_website = account.website ?? "";
    old_description = account.description ?? "";
    description_text_view.set_text (account.description ?? "");
  }

  [GtkCallback]
  private void delete_button_clicked_cb () {
    delete_stack.visible_child_name = PAGE_DELETE;
  }

  private void save_data () {
    bool needs_save = (old_user_name != name_entry.text) ||
                      (old_description != description_text_view.get_text ()) ||
                      (old_website != website_entry.text);

    bool needs_init = needs_save || (new_avatar != null) || (new_banner != null);

    if (needs_init && account.proxy == null) {
      account.init_proxy ();
    }


    if (needs_save) {
      debug ("Saving data...");
      var call = account.proxy.new_call ();
      call.set_function ("1.1/account/update_profile.json");
      call.set_method ("POST");
      call.add_param ("url", website_entry.text);
      call.add_param ("name", name_entry.text);
      call.add_param ("description", description_text_view.get_text ());
      call.invoke_async.begin (null, (obj, res) => {
        try {
          call.invoke_async.end (res);
          debug ("Profile successfully updated");
        } catch (GLib.Error e) {
          warning (e.message);
          Utils.show_error_object (call.get_payload (), "Could not update profile",
                                   GLib.Log.LINE, GLib.Log.FILE, this);
        }
      });

      /* Update local user data */
      account.name = name_entry.text;
      account.description = description_text_view.get_text ();
      account.website = website_entry.text;
    }

    if (new_avatar != null) {
      debug ("Updating avatar...");
      uint8[] buffer;
      try {
        new_avatar.save_to_buffer (out buffer, "png", null);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }
      string b64 = GLib.Base64.encode (buffer);

      var call = account.proxy.new_call ();
      call.set_function ("1.1/account/update_profile_image.json");
      call.set_method ("POST");
      call.add_param ("skip_status", "true");
      call.add_param ("include_entities", "false");
      call.add_param ("image", b64);
      call.invoke_async.begin (null, (obj, res) => {
        try {
          call.invoke_async.end (res);
          debug ("Avatar successfully updated");
        } catch (GLib.Error e) {
          Utils.show_error_object (call.get_payload (), "Could not update your avatar",
                                   GLib.Log.LINE, GLib.Log.FILE, this);
          return;
        }

        /* Locally set new avatar */
        var s = Gdk.cairo_surface_create_from_pixbuf (new_avatar, 1, null);
        account.set_new_avatar (s);
      });
    }

    if (new_banner != null) {
      debug ("Updating banner...");
      uint8[] buffer;
      // XXX With large banners, this can be too slow...
      try {
        new_banner.save_to_buffer (out buffer, "png", null);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }
      string b64 = GLib.Base64.encode (buffer);

      var call = account.proxy.new_call ();
      call.set_function ("1.1/account/update_profile_banner.json");
      call.set_method ("POST");

      call.add_param ("banner", b64);
      call.invoke_async.begin (null, (obj, res) => {
        try {
          call.invoke_async.end (res);
          debug ("Banner successfully updated");
        } catch (GLib.Error e) {
          Utils.show_error_object (call.get_payload (), "Could not update your banner",
                                   GLib.Log.LINE, GLib.Log.FILE, this);
        }
      });
    }
  }

  [GtkCallback]
  private void delete_confirm_button_clicked_cb () {
    /*
       - Close open window of that account
       - Remove the account from the db, disk, etc.
       - Remove the account from the app menu
       - If this would close the last opened window,
         set the account of that window to NULL
     */
    int64 acc_id = account.id;
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id).db"));
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id).png"));
    FileUtils.remove (Dirs.config (@"accounts/$(acc_id)_small.png"));
    Corebird.db.exec (@"DELETE FROM `accounts` WHERE `id`='$(acc_id)';");

    /* Remove account from startup accounts, if it's in there */
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    for (int i = 0; i < startup_accounts.length; i++)
      if (startup_accounts[i] == account.screen_name) {
        string[] sa_new = new string[startup_accounts.length - 1];
        for (int x = 0; x < i; i++)
          sa_new[x] = startup_accounts[x];
        for (int x = i+1; x < startup_accounts.length; x++)
          sa_new[x] = startup_accounts[x];
        Settings.get ().set_strv ("startup-accounts", sa_new);
      }

    Corebird cb = (Corebird) GLib.Application.get_default ();

    /* Handle windows, i.e. if this MainWindow is the last open one,
       we want to use it to show the "new account" UI, otherwise we
       just close it. */
    unowned GLib.List<Gtk.Window> windows = cb.get_windows ();
    Gtk.Window? account_window = null;
    int n_main_windows = 0;
    foreach (Gtk.Window win in windows) {
      if (win is MainWindow) {
        n_main_windows ++;
        if (((MainWindow)win).account.id == this.account.id) {
          account_window = win;
        }
      }
    }
    debug ("Open main windows: %d", n_main_windows);

    if (account_window != null) {
      if (n_main_windows > 1)
        account_window.destroy ();
      else
        ((MainWindow)account_window).change_account (null);
    }


    /* Remove the account from the global list of accounts */
    Account acc_to_remove = Account.query_account_by_id (account.id);
    cb.account_removed (acc_to_remove);
    Account.remove_account (account.screen_name);


    /* Close this dialog */
    this.destroy ();
  }

  [GtkCallback]
  private void delete_cancel_button_clicked_cb () {
    delete_stack.visible_child_name = PAGE_NORMAL;
  }

  [GtkCallback]
  private void autostart_switch_activate_cb () {
    bool active = autostart_switch.active;
    string[] startup_accounts = Settings.get ().get_strv ("startup-accounts");
    if (active) {
      foreach (unowned string acc in startup_accounts) {
        if (acc == this.account.screen_name) {
          return;
        }
      }

      string[] new_startup_accounts = new string[startup_accounts.length + 1];
      int i = 0;
      foreach (unowned string s in startup_accounts) {
        new_startup_accounts[i] = s;
        i ++;
      }
      new_startup_accounts[new_startup_accounts.length - 1] = this.account.screen_name;
      Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
    } else {
      string[] new_startup_accounts = new string[startup_accounts.length - 1];
      int i = 0;
      foreach (unowned string acc in startup_accounts) {
        if (acc != this.account.screen_name) {
          new_startup_accounts[i] = acc;
          i ++;
        }
      }
      Settings.get ().set_strv ("startup-accounts", new_startup_accounts);
    }
  }

  private void show_crop_image_selector () {
    var filechooser = new Gtk.FileChooserNative (_("Select Banner Image"),
                                                 this,
                                                 Gtk.FileChooserAction.OPEN,
                                                 _("Open"),
                                                 _("Cancel"));
    var filter = new Gtk.FileFilter ();
    filter.add_mime_type ("image/png");
    filter.add_mime_type ("image/jpeg");
    filechooser.set_filter (filter);

    if (filechooser.run () == Gtk.ResponseType.ACCEPT) {
      string selected_file = filechooser.get_filename ();
      Gdk.Pixbuf? image = null;
      try {
        image = new Gdk.Pixbuf.from_file (selected_file);
      } catch (GLib.Error e) {
        warning (e.message);
        return;
      }

      /* Values for banner */
      int min_width = 200;
      int min_height = 100;

      if (crop_widget.desired_aspect_ratio == 1.0) {
        /* Avatar */
        min_width = 48;
        min_height = 48;
      }

      if (image.get_width () >= min_width &&
          image.get_height () >= min_height) {
        crop_widget.set_image (image);
        save_button.sensitive = true;
      } else {
        string error_str = "";
        error_str += _("Image does not meet minimum size requirements:") + "\n";
        error_str += ngettext ("Minimum width: %d pixel", "Minimum width: %d pixels", min_width)
                     .printf (min_width) + "\n";
        error_str += ngettext ("Minimum height: %d pixel", "Minimum height: %d pixels", min_height)
                     .printf (min_height);
        error_label.label = error_str;
        content_stack.visible_child = error_label;
        save_button.sensitive = false;
      }
    } else {
      content_stack.visible_child = info_box;
    }
  }

  [GtkCallback]
  private void avatar_clicked_cb () {
    this.get_size (out old_width, out old_height);
    this.resize (400, 400);
    crop_widget.set_image (null);
    crop_widget.set_size_request (-1, 400);
    crop_widget.desired_aspect_ratio = 1.0;
    crop_widget.set_min_size (48);
    content_stack.visible_child = crop_widget;
    show_crop_image_selector ();
    save_button.label = _("Pick");
  }

  [GtkCallback]
  private void banner_clicked_cb () {
    this.get_size (out old_width, out old_height);
    this.resize (700, 350);
    crop_widget.set_size_request (700, 350);
    crop_widget.set_image (null);
    crop_widget.desired_aspect_ratio = 2.0;
    crop_widget.set_min_size (200);
    content_stack.visible_child = crop_widget;
    show_crop_image_selector ();
    save_button.label = _("Pick");
  }

  [GtkCallback]
  private void cancel_button_clicked_cb () {
    if (content_stack.visible_child == crop_widget ||
        content_stack.visible_child == error_label) {
      this.resize (old_width, old_height);
      old_width = 0;
      old_height = 0;
      /* Just go back */
      content_stack.visible_child = info_box;
      save_button.label = _("Save");
    } else {
      this.destroy ();
    }
  }

  [GtkCallback]
  private void save_button_clicked_cb () {
    if (content_stack.visible_child == crop_widget) {
      Gdk.Pixbuf new_pixbuf = crop_widget.get_cropped_image ();
      if (crop_widget.desired_aspect_ratio == 1.0) {
        /* Avatar */
        avatar_banner_widget.set_avatar (new_pixbuf);
        new_avatar = new_pixbuf;
      } else if (crop_widget.desired_aspect_ratio == 2.0) {
        /* Banner */
        avatar_banner_widget.set_banner (new_pixbuf);
        new_banner = new_pixbuf;
      } else {
        GLib.assert_not_reached ();
      }
      save_button.label = _("Save");
      content_stack.visible_child = info_box;
    } else {
      save_data ();
      this.destroy ();
    }
  }
}
