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