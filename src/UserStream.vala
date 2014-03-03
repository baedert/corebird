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


// See https://dev.twitter.com/docs/streaming-apis/messages
enum StreamMessageType {
  UNSUPPORTED,
  DELETE,
  SCRUB_GEO,
  LIMIT,
  DISCONNECT,
  FRIENDS,
  EVENT,
  WARNING,
  FOLLOW,
  DIRECT_MESSAGE,

  TWEET,
  EVENT_LIST_CREATED,
  EVENT_LIST_DESTROYED,
  EVENT_LIST_UPDATED,
  EVENT_LIST_UNSUBSCRIBED,
  EVENT_LIST_SUBSCRIBED,
  EVENT_LIST_MEMBER_ADDED,
  EVENT_LIST_MEMBER_REMOVED,
  EVENT_FAVORITE,
  EVENT_UNFAVORITE
}


class UserStream : Object {
  private static const int TIMEOUT_INTERVAL         = 45*1000;
  private Rest.OAuthProxy proxy;
  private Rest.ProxyCall proxy_call;
  private StringBuilder data                        = new StringBuilder();
  private SList<unowned IMessageReceiver> receivers = new SList<unowned IMessageReceiver>();
  private uint timeout_id = -1;
  private string account_name;
  public string token {
    set { proxy.token = value; }
  }
  public string token_secret {
    set { proxy.token_secret = value; }
  }



  public UserStream (string account_name) {
    this.account_name = account_name;
    debug ("CREATING USER STREAM FOR "+account_name);
    proxy = new Rest.OAuthProxy(
          Utils.decode (Utils.CONSUMER_KEY),
          Utils.decode (Utils.CONSUMER_SECRET),
          "https://userstream.twitter.com/", //Url Format
          false
        );
  }


  public void register (IMessageReceiver receiver) {
    receivers.append(receiver);
  }



  /**
   * Starts the UserStream
   */
  public void start () {
    proxy_call = proxy.new_call ();
    proxy_call.set_function ("1.1/user.json");
    proxy_call.set_method ("GET");
    try {
      proxy_call.continuous (parse_data_cb, proxy_call);
    } catch (GLib.Error e) {
      error (e.message);
    }
  }

  ~UserStream () {
    critical ("USERSTREAM DESTROYED");
  }

  /**
   * Stops the UserStream
   */
  public void stop () {
    debug ("STOPPING STREAM FOR " + account_name);
    proxy_call.cancel ();
    if(timeout_id != -1)
        GLib.Source.remove (timeout_id);
  }

  /**
   * The timeout cb is called whenever we didn't get a heartbeat
   * from Twitter for over TIMEOUT_INTERVAL seconds.
   *
   */
  private bool timeout_cb() {
    message ("Restarting...");
//    start ();
    return false;
  }


  /**
   * Callback called by the Rest.ProxyCall whenever it receives data.
   *
   * @param call The Rest.ProxyCall created when the UserStream was started.
   * @param buf The string received
   * @param length The buffer's length
   * @param error
   */
  private void parse_data_cb (Rest.ProxyCall call, string? buf, size_t length,
                              Error? error) {
    if (buf == null) {
      warning("buf == NULL");
      return;
    }

    string real = buf.substring(0, (int)length);

    data.append (real);

    if (real.has_suffix ("\r\n") || real.has_suffix ("\r")) {
      //Reset the timeout
      if (timeout_id != -1)
        GLib.Source.remove (timeout_id);
      timeout_id = GLib.Timeout.add (TIMEOUT_INTERVAL, timeout_cb);

      if (real == "\r\n") {
        debug ("HEARTBEAT(%s)", account_name);
        data.erase ();
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data(data.str);
      } catch (GLib.Error e) {
        critical(e.message);
      }

      var root_node = parser.get_root();
      var root = root_node.get_object ();

      StreamMessageType type = 0;

      if (root.has_member ("delete"))
        type = StreamMessageType.DELETE;
      else if (root.has_member ("scrub_geo"))
        type = StreamMessageType.SCRUB_GEO;
      else if (root.has_member ("limit"))
        type = StreamMessageType.LIMIT;
      else if (root.has_member ("disconnect"))
        type = StreamMessageType.DISCONNECT;
      else if (root.has_member ("friends"))
        type = StreamMessageType.FRIENDS;
      else if (root.has_member ("text"))
        type = StreamMessageType.TWEET;
      else if (root.has_member ("event")) {
        string evt_str = root.get_string_member ("event");
        type = get_event_type (evt_str);
      }
      else if (root.has_member ("warning"))
        type = StreamMessageType.WARNING;
      else if (root.has_member ("direct_message"))
        type = StreamMessageType.DIRECT_MESSAGE;
      else if (root.has_member ("status_withheld"))
        type = StreamMessageType.UNSUPPORTED;

#if __DEV
      message ("Message with type %s", type.to_string ());
      if (type != StreamMessageType.FRIENDS)
        stdout.printf (data.str+"\n");
#endif
      foreach (IMessageReceiver it in receivers)
        it.stream_message_received (type, root_node);


      data.erase ();
    }
  }


  private StreamMessageType get_event_type (string evt_str) {
    switch (evt_str) {
      case "follow":
        return StreamMessageType.FOLLOW;
      case "list_created":
        return StreamMessageType.EVENT_LIST_CREATED;
      case "list_destroyed":
        return StreamMessageType.EVENT_LIST_DESTROYED;
      case "list_updated":
        return StreamMessageType.EVENT_LIST_UPDATED;
      case "list_user_unsubscribed":
        return StreamMessageType.EVENT_LIST_UNSUBSCRIBED;
      case "list_user_subscribed":
        return StreamMessageType.EVENT_LIST_SUBSCRIBED;
      case "list_member_added":
        return StreamMessageType.EVENT_LIST_MEMBER_ADDED;
      case "list_member_removed":
        return StreamMessageType.EVENT_LIST_MEMBER_REMOVED;
      case "favorite":
        return StreamMessageType.EVENT_FAVORITE;
      case "unfavorite":
        return StreamMessageType.EVENT_UNFAVORITE;
    }

    return 0;
  }
}



