

using Gtk;


public class SettingsDialog {
	private Dialog dialog;

	public SettingsDialog(){
		Builder builder = new Builder();
		try{
			builder.add_from_file("ui/settings.ui");
		}catch(GLib.Error e){
			error("Error while loading ui: %s", e.message);
		}

		dialog = (Dialog)builder.get_object("dialog1");

		builder.connect_signals(null);
	}

	[CCode (instance_pos = -1)]
	public void show_primary_toolbar_cb(Button source){
		message("hihi");
	}


	public void show_all(){
		dialog.show_all();
	}
}