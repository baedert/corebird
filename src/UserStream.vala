/*  This file is part of corebird.
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
  DELETE,
  SCRUB_GEO,
  LIMIT,
  DISCONNECT,
  FRIENDS,
  EVENT,
  WARNING,
  FOLLOW,

  TWEET,
}


// TODO: Retweets(other user retweet the user's tweet) are
//       recognized as mentions(and...tweets?)

class UserStream : Object {
  private static const int TIMEOUT_INTERVAL     = 45*1000;
  private Rest.OAuthProxy proxy;
  private StringBuilder data                    = new StringBuilder();
  private SList<IMessageReceiver> receivers     = new SList<IMessageReceiver>();
  private uint timeout_id = -1;
  public string token {
    set { proxy.token = value; }
  }
  public string token_secret {
    set { proxy.token_secret = value; }
  }



  public UserStream () {
    proxy = new Rest.OAuthProxy(
          "0rvHLdbzRULZd5dz6X1TUA",           //Consumer Key
          "oGrvd6654nWLhzLcJywSW3pltUfkhP4BnraPPVNhHtY",  //Consumer Secret
          "https://userstream.twitter.com/",        //Url Format
          false
        );
    //Register a new warning service
    receivers.append(new WarningService("UserStream"));
  }


  public void register (IMessageReceiver receiver) {
    receivers.append(receiver);
  }




  public void start () {
    var call = proxy.new_call ();
    call.set_function ("1.1/user.json");
    call.set_method ("GET");
    try{
      call.continuous (parse_data_cb, this);
    } catch (GLib.Error e) {
      error (e.message);
    }
  }

  private bool timeout_cb() {
    var builder = new UIBuilder(DATADIR+"/ui/connection-lost-dialog.ui");
    var dialog = builder.get_dialog ("dialog1");
    dialog.response.connect((id) => {
      if(id == 0)
        dialog.destroy();
      else if(id == 1) {
        error ("Implement reconnecting");
      }
    });

    dialog.show_all();
    return false;
  }

  private void parse_data_cb(Rest.ProxyCall call, string? buf, size_t length,
                             Error? error) {
    if(buf == null) {
      warning("buf == NULL");
      return;
    }

    string real = buf.substring(0, (int)length);

    data.append(real);

    if(real.has_suffix("\r\n")) {
      //Reset the timeout
      if(timeout_id != -1)
        GLib.Source.remove (timeout_id);
      timeout_id = GLib.Timeout.add (TIMEOUT_INTERVAL, timeout_cb);

      if(real == "\r\n") {
        message("HEARTBEAT");
        data.erase();
        return;
      }

      var parser = new Json.Parser();
      try{
        parser.load_from_data(data.str);
#if __DEV
        stdout.printf (data.str+"\n");
#endif
      } catch (GLib.Error e) {
        critical(e.message);
      }

      var root = parser.get_root().get_object();

      StreamMessageType type = 0;

      if(root.has_member("delete"))
        type = StreamMessageType.DELETE;
      else if(root.has_member("scrub_geo"))
        type = StreamMessageType.SCRUB_GEO;
      else if(root.has_member("limit"))
        type = StreamMessageType.LIMIT;
      else if(root.has_member("disconnect"))
        type = StreamMessageType.DISCONNECT;
      else if(root.has_member("friends"))
        type = StreamMessageType.FRIENDS;
      else if(root.has_member("text"))
        type = StreamMessageType.TWEET;
      else if(root.has_member("event")){
        string evt_str = root.get_string_member("event");
        if(evt_str == "follow")
          type = StreamMessageType.FOLLOW;
        else
          type = StreamMessageType.EVENT;
      }
      else if(root.has_member("warning"))
        type = StreamMessageType.WARNING;

      message("Message with type %s", type.to_string());
      foreach(IMessageReceiver it in receivers)
        it.stream_message_received(type, root);


      data.erase();
    }
  }

}



