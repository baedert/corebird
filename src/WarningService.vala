


class WarningService : IMessageReceiver, GLib.Object {
	private string stream_name;

	public WarningService(string stream_name) {
		this.stream_name = stream_name;
	}


	private void stream_message_received(StreamMessageType type, Json.Object root){
		if(type != StreamMessageType.WARNING) return;

		var warning_object = root.get_object_member("warning");
		string message = warning_object.get_string_member("code")+"\n"+
				warning_object.get_string_member("message");

		var dialog = new Gtk.MessageDialog(null, Gtk.DialogFlags.DESTROY_WITH_PARENT,
		           Gtk.MessageType.WARNING, Gtk.ButtonsType.OK,
		           message);

		dialog.response.connect((id) => {
			if(id == Gtk.ResponseType.OK)
				dialog.destroy();
		});


		dialog.set_title(stream_name);
		dialog.show();

	}

}