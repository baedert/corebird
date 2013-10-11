




class FriendService : IMessageReceiver, GLib.Object {


  public void stream_message_received (StreamMessageType type, Json.Node root_node) {
    if (type != StreamMessageType.FRIENDS) return;

    var arr = root_node.get_array ();


  }
}
