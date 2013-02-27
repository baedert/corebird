

using Notify;


class NotificationManager {
	private static Notification notification;
	private static bool is_persistent;



	public static void init(){
		Notify.init("Corebird");
		unowned List<string> caps = Notify.get_server_caps();
		foreach(string s in caps){
			if (s == "persistence"){
				message("Not creating any tray icon");
				is_persistent = true;
				notification = new Notification("Corebird", "Started", null);
				notification.set_urgency(Urgency.LOW);
				// notification.set_hint("transient", new Variant.boolean(true));
				notification.set_timeout(Notify.EXPIRES_NEVER);
				try{
					notification.show();
				}catch(GLib.Error e){
					critical(e.message);
				}
				return;
			}
		}
	}


	public static void notify(string summary, string body="",
	                          Urgency urgency = Urgency.LOW){
		Notification n;
		if (is_persistent){
			n = notification;
			n.update(summary, body, "");
			n.set_urgency(urgency);
		}else{
			n = new Notification(summary, body, null);
			n.set_urgency(urgency);
		}
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