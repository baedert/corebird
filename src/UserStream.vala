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
public enum StreamMessageType {
  UNSUPPORTED,
  DELETE,
  SCRUB_GEO,
  LIMIT,
  DISCONNECT,
  FRIENDS,
  EVENT,
  WARNING,
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
  EVENT_UNFAVORITE,
  EVENT_FOLLOW,
  EVENT_UNFOLLOW,
  EVENT_BLOCK,
  EVENT_UNBLOCK,
  EVENT_MUTE,
  EVENT_UNMUTE,
  EVENT_USER_UPDATE
}


public class UserStream : Object {
  private static const int TIMEOUT_INTERVAL         = 45*1000;
  private Rest.OAuthProxy proxy;
  private Rest.ProxyCall proxy_call;
  private StringBuilder data                        = new StringBuilder();
  private SList<unowned IMessageReceiver> receivers = new SList<unowned IMessageReceiver>();
  private GLib.NetworkMonitor network_monitor;
  private bool network_available;
  private uint network_timeout_id   = 0;
  private uint heartbeat_timeout_id = 0;
  private bool running = false;
  private string account_name;
  public string token {
    set { proxy.token = value; }
  }
  public string token_secret {
    set { proxy.token_secret = value; }
  }
  private unowned Account account;

  // Signals
  public signal void interrupted ();
  public signal void resumed ();




  public UserStream (Account account) {
    this.account_name = account.screen_name;
    this.account = account;
    debug ("CREATING USER STREAM FOR " + account_name);
    proxy = new Rest.OAuthProxy(
          Settings.get_consumer_key (),
          Settings.get_consumer_secret (),
          "https://userstream.twitter.com/", //Url Format
          false
        );
    network_monitor = GLib.NetworkMonitor.get_default ();
    network_available = network_monitor.get_network_available ();
    network_monitor.network_changed.connect (network_changed_cb);
    if (!network_available)
      start_network_timeout ();
  }


  public void register (IMessageReceiver receiver) {
    receivers.append(receiver);
  }


  private void network_changed_cb (bool available) {
    if (available == this.network_available)
      return;

    this.network_available = available;

    if (network_available) {
      debug ("Restarting stream (reason: Network available (callback))");
      restart ();
      resumed ();
    } else {
      debug ("Connection lost (%s) Reason: network unavailable", account_name);
      interrupted ();
      start_network_timeout ();
    }
  }



  /**
   * Starts the UserStream
   */
  public void start () {
    // Reset state of the stream
    running = true;
    proxy_call = proxy.new_call ();
    proxy_call.set_function ("1.1/user.json");
    proxy_call.set_method ("GET");
    start_heartbeat_timeout ();
    try {
      proxy_call.continuous (parse_data_cb, proxy_call);
    } catch (GLib.Error e) {
      error (e.message);
    }
  }

  /**
   * Stops the UserStream
   */
  public void stop () {
    running = false;

    if (this.network_timeout_id != 0)
      GLib.Source.remove (this.network_timeout_id);

    debug ("STOPPING STREAM FOR " + account_name);
    proxy_call.cancel ();
  }

  private void restart () {
    stop ();
    start ();
  }

  private void start_network_timeout () {
    network_timeout_id = GLib.Timeout.add (30 * 1000, () => {
      if (running)
        return false;

      var available = network_monitor.get_network_available ();
      if (available) {
        debug ("Restarting stream (reason: network available (timeout))");
        restart ();
        return false;
      }
      return true;
    });
  }

  private void start_heartbeat_timeout () {
    heartbeat_timeout_id = GLib.Timeout.add (TIMEOUT_INTERVAL, () => {
      if (!running)
        return false;
      // If we get here, we need to restart the stream.
      running = false;
      debug ("Connection lost (%s) Reason: heartbeat. Restarting...", account_name);
      restart ();
      return false;
    });
  }


  ~UserStream () {
    debug ("USERSTREAM for %s DESTROYED", account_name);
  }

  /**
   * Callback called by the Rest.ProxyCall whenever it receives data.
   *
   * @param call The Rest.ProxyCall created when the UserStream was started.
   * @param buf The string received
   * @param length The buffer's length
   * @param error
   */
  private void parse_data_cb (Rest.ProxyCall call,
                              string?        buf,
                              size_t         length,
                              GLib.Error?    error) {
    if (buf == null) {
      warning ("buf == NULL");
      return;
    }

    string real = buf.substring (0, (int)length);

    data.append (real);

    if (real.has_suffix ("\r\n") || real.has_suffix ("\r")) {

      if (real == "\r\n") {
        debug ("HEARTBEAT(%s)", account_name);
        data.erase ();
        if (heartbeat_timeout_id != 0)
          GLib.Source.remove (heartbeat_timeout_id);

        start_heartbeat_timeout ();
        return;
      }

      /* For whatever reason, we sometimes receive "OK"
         from the server. I can't find an explanation
         for this but it doesn't seem to cause any harm. */
      if (data.str.strip () == "OK") {
        data.erase ();
        return;
      }

      var parser = new Json.Parser ();
      try {
        parser.load_from_data (data.str);
      } catch (GLib.Error e) {
        critical (e.message);
        critical (data.str);
        data.erase ();
        return;
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
      else if (root.has_member ("friends")) {
        account.set_friends (root.get_array_member ("friends"));
        type = StreamMessageType.FRIENDS;
      } else if (root.has_member ("text"))
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

#if DEBUG
      debug ("Message with type %s", type.to_string ());
      stdout.printf (data.str+"\n\n");
#endif
      foreach (IMessageReceiver it in receivers)
        it.stream_message_received (type, root_node);


      data.erase ();
    }
  }


  private StreamMessageType get_event_type (string evt_str) {
    switch (evt_str) {
      case "follow":
        return StreamMessageType.EVENT_FOLLOW;
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
      case "unfollow":
        return StreamMessageType.EVENT_UNFOLLOW;
      case "block":
        return StreamMessageType.EVENT_BLOCK;
      case "unblock":
        return StreamMessageType.EVENT_UNBLOCK;
      case "mute":
        return StreamMessageType.EVENT_MUTE;
      case "unmute":
        return StreamMessageType.EVENT_UNMUTE;
      case "user_update":
        return StreamMessageType.EVENT_USER_UPDATE;
    }

    return 0;
  }
}



