

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
				notification = new Notification("Corebird", "summary", null);
				notification.show();
				return;
			}
		}
	}


	public static void notify(string summary, string body="",
	                          Urgency urgency = Urgency.LOW){
		if (is_persistent){
			notification.update(summary, body, null);
			notification.show();
		}else{
			Notification n = new Notification(summary, body, null);
			n.set_urgency(urgency);
			n.show();
		}
	}


	public static void uninit(){
		if(is_persistent)
			notification.close();
		Notify.uninit();	
	}

}