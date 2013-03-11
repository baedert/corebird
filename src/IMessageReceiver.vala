

interface IMessageReceiver : GLib.Object {
	public abstract void stream_message_received(StreamMessageType type,
	                		                     Json.Object root_object);
}