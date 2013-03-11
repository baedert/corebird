

using Notify;


class NotificationManager {
	private static Notification notification;
	private static bool is_persistent;



	public static void init(MainWindow window){
		Notify.init("Corebird");
		unowned List<string> caps = Notify.get_server_caps();
		foreach(string s in caps){
			message(s);
			if (s == "persistence"){
				message("Not creating any tray icon");
				is_persistent = true;
				notification = new Notification("Corebird",
				                                "Logged in as "+User.screen_name, null);
				notification.set_urgency(Urgency.LOW);
				notification.set_timeout(Notify.EXPIRES_NEVER);
				notification.add_action("clicked", "Open",
				() => {
					window.show_again();
				});
				notification.add_action("compose", "Compose",
				() => {
					ComposeTweetWindow win = new ComposeTweetWindow(null,
									null,
					                window.get_application());
					win.show_all();
				});
				notification.set_icon_from_pixbuf(
                      	new Gdk.Pixbuf.from_file(User.get_avatar_path()));
				try{
					notification.set_hint("resident", new Variant.boolean(true));
					notification.show();
				}catch(GLib.Error e){
					critical(e.message);
				}
				return;
			}
		}
	}


	public static void notify(string summary, string body="",
	                          Urgency urgency = Urgency.LOW,
	                          Gdk.Pixbuf? pixbuf = null){
		Notification n;
		if (is_persistent){
			n = notification;
			n.update(summary, body, "");
		}else{
			n = new Notification(summary, body, null);
		}

		n.set_urgency(urgency);
		if(pixbuf != null)
			n.set_icon_from_pixbuf(pixbuf);

		try{
			n.show();
		}catch(GLib.Error e){
			message("Error while showing notification: %s", e.message);
		}
	}


	/**
	 * Uninitializes the notification manager
	 * Should be called when the application gets closed completely.
	 */
	public static void uninit(){
		if(is_persistent){
			try{
				notification.close();
			}catch(GLib.Error e){
				message("Closing the notification: %s", e.message);
			}
		}
		Notify.uninit();
	}

}