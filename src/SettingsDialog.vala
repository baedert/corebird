

using Gtk;


public class SettingsDialog {
	public Dialog dialog;

	public SettingsDialog(){
		Builder builder = new Builder();
		try{
			builder.add_from_file("ui/settings.ui");
			builder.connect_signals(this);
		}catch(GLib.Error e){
			error("Error while loading ui: %s", e.message);
		}
		

		dialog = builder.get_object("dialog") as Dialog;
	}

	[CCode (instance_pos = -1)]
	public void show_primary_toolbar_cb(Button source){
		message("hihi");
	}


	public void show_all(){
		dialog.show_all();
	}
}