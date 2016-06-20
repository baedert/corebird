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

class ComposeJob : GLib.Object {
  private unowned Account account;
  public string text;
  public Tweet quoted_tweet;
  public int64? reply_id = null;
  private GLib.GenericArray<string> image_paths = new GLib.GenericArray<string> ();
  public signal void image_upload_started  (string path);
  public signal void image_upload_finished (string path, string? error_message = null);

  public ComposeJob (Account account) {
    this.account = account;
  }


  public void add_image (string path) {
    this.image_paths.add (path);
  }


  private async int64 upload_image (string path, Rest.Proxy proxy, GLib.Cancellable cancellable)
                      throws GLib.Error {
    var call = proxy.new_call ();
    call.set_function ("1.1/media/upload.json");
    call.set_method ("POST");
    uint8[] file_contents;
    GLib.File media_file = GLib.File.new_for_path (path);
    media_file.load_contents (null, out file_contents, null);
    Rest.Param param = new Rest.Param.full ("media",
                                            Rest.MemoryUse.COPY,
                                            file_contents,
                                            "multipart/form-data",
                                            path);
    call.add_param_full (param);


    yield call.invoke_async (cancellable);
    var parser = new Json.Parser ();
    try {
      parser.load_from_data (call.get_payload ());
    } catch (GLib.Error e) {
      warning (e.message); //XXX Error handling
      return -1;
    }

    if (cancellable.is_cancelled ()) return 0;

    var root = parser.get_root ().get_object ();
    return root.get_int_member ("media_id");
  }


  private async int64[] upload_images (GLib.Cancellable cancellable) {
    assert (this.image_paths.length > 0);

    Rest.OAuthProxy proxy = new Rest.OAuthProxy (Settings.get_consumer_key (),
                                                 Settings.get_consumer_secret (),
                                                 "https://upload.twitter.com/",
                                                 false);
    proxy.token = account.proxy.token;
    proxy.token_secret = account.proxy.token_secret;

    int64[] ids = new int64[this.image_paths.length];
    var collect_obj = new Collect (this.image_paths.length);
    collect_obj.finished.connect (() => {
      debug ("Calling the callback...");
      upload_images.callback ();
    });

    for (int i = 0; i < this.image_paths.length; i ++) {
      string path = this.image_paths.get (i);
      this.image_upload_started (path);
      debug ("Starting upload of %s (%d)", path, i);
      int index = i;
      this.upload_image.begin (path, proxy, cancellable, (obj, res) => {
        int64 id;
        try {
          id = this.upload_image.end (res);
        } catch (GLib.Error e) {
          warning (e.message);
          this.image_upload_finished (path, e.message);
          collect_obj.emit (e);
          return;
        }

        debug ("id for %s (%d): %s", path, index, id.to_string ());
        ids[index] = id;
        this.image_upload_finished (path);
        collect_obj.emit ();
      });

      if (cancellable.is_cancelled ()) break;
    }

    yield;

    return ids;
  }

  private async bool send_tweet (int64[]? media_ids, GLib.Cancellable? cancellable) {
    bool success = true;
    var call = this.account.proxy.new_call ();
    call.set_method ("POST");
    call.set_function ("1.1/statuses/update.json");

    if (this.reply_id != null) {
      call.add_param ("in_reply_to_status_id", this.reply_id.to_string ());
    } else if (this.quoted_tweet != null) {
      Cb.MiniTweet mt = quoted_tweet.retweeted_tweet ?? quoted_tweet.source_tweet;

      this.text += " https://twitter.com/%s/status/%s".printf (mt.author.screen_name,
                                                               mt.id.to_string ());
    }

    call.add_param ("status", this.text);

    if (media_ids != null && media_ids.length > 0) {
      var sb = new StringBuilder ();
      sb.append (media_ids[0].to_string ());
      for (int i = 1; i < media_ids.length; i ++) {
        sb.append (",").append (media_ids[i].to_string ());
      }
      debug ("id param: %s", sb.str);
      call.add_param ("media_ids", sb.str);
    }

    call.invoke_async.begin (cancellable, (obj, res) => {
      try {
        call.invoke_async.end (res);
      } catch (GLib.Error e) {
        warning (e.message);
        Utils.show_error_object (call.get_payload (), e.message,
                                 GLib.Log.LINE, GLib.Log.FILE);
        success = false;
      }
      send_tweet.callback ();
    });
    yield;

    return success;
  }


  public async bool start (GLib.Cancellable cancellable) {
    /* composing a tweet consists of 2 phases:
       1) we need to upload each image separately and get its
          media ID form the payload.
       2) Merge all media ids to a string and add that as a parameter to
          the tweet
     */

    int64[]? media_ids = null;
    if (this.image_paths.length > 0) {
      debug ("Uploading %d images first...", this.image_paths.length);
      media_ids = yield upload_images (cancellable);
      debug ("media_ids[0]: %s", media_ids[0].to_string ());
    }

    if (cancellable.is_cancelled ()) return false;

    bool success = yield send_tweet (media_ids, cancellable);

    return success;
  }
}
