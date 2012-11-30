
using Gtk;


/**
 * A Dialog showing information about the given user.
 */
class ProfileDialog : Gtk.Window {
	private ImageBox banner_box = new ImageBox(Orientation.VERTICAL, 3);
	private Image avatar_image = new Image();
	private Label name_label = new Label("");
	private Label description_label = new Label("");

	//TODO: Implement proper caching here.
	public ProfileDialog(string screen_name = ""){
		if (screen_name == "")
			screen_name = User.screen_name;
		// screen_name = "bl2nk";


		var main_box = new Gtk.Box(Orientation.VERTICAL, 2);

		avatar_image.margin_top = 20;
		avatar_image.set_alignment(0.5f, 0);
		banner_box.pack_start(avatar_image, false, false);
		name_label.set_use_markup(true);
		name_label.justify = Justification.CENTER;
		Gdk.RGBA b = {};
		b.parse("#F00");
		// name_label.override_background_color(StateFlags.NORMAL, b);
		banner_box.pack_start(name_label, false, false);
		description_label.set_use_markup(true);
		description_label.set_line_wrap(true);
		description_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
		description_label.justify = Justification.CENTER;
		description_label.margin_left = 5;
		description_label.margin_right = 5;
		Gdk.RGBA c = {};
		c.parse("#0F0");
		// description_label.override_background_color(StateFlags.NORMAL, c);
		banner_box.pack_start(description_label, false, false);


		main_box.pack_start(banner_box, false, false);

		

		load_banner.begin(screen_name);
		load_profile_data.begin(screen_name);



		this.set_default_size(320, 450);
		this.add(main_box);
	}


	private async void load_profile_data(string screen_name){
		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/users/show.json");
		call.add_param("screen_name", screen_name);
		call.invoke_async.begin(null, (obj, res) => {
			try{
				call.invoke_async.end (res);
			} catch (GLib.Error e){
				warning("Error while ending call: %s", e.message);
				return;
			}
			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			} catch (GLib.Error e){
				warning ("Error while loading profile data: %s", e.message);
				return;
			}
			var root = parser.get_root().get_object();
			string avatar_url = root.get_string_member("profile_image_url");
			string avatar_name = Utils.get_file_name(avatar_url);
			string avatar_on_disk = "assets/avatars/"+avatar_name;
			if(!FileUtils.test(avatar_on_disk, FileTest.EXISTS)){
				File av = File.new_for_uri(avatar_url);
				File dest = File.new_for_path(avatar_on_disk);
				av.copy(dest, FileCopyFlags.OVERWRITE);
			}
			avatar_image.set_from_file(avatar_on_disk);


			name_label.set_markup("<big><big><big><b><span color='white'>%s
			                      </span></b></big></big></big>".printf(root.get_string_member("name")));
			description_label.set_markup("<big><span color='white'>%s</span></big>"
			                             .printf(root.get_string_member("description")));


		});
	}


	/**
	 * Loads the user's banner image.
	 */
	private async void load_banner(string screen_name){
		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/users/profile_banner.json");
		call.add_param("screen_name", screen_name);
		call.invoke_async.begin(null, (obj, res) => {
			if (call.get_status_code() == 404){
				// Normal. The user has not set a profile banner.
				message("No Banner set.");
				banner_box.set_pixbuf(new Gdk.Pixbuf.from_file("assets/banners/no_banner.png"));
				return;
			}
			try{
				call.invoke_async.end (res);
			} catch (GLib.Error e){
				warning("Error while ending call: %s", e.message);
				return;
			}
			string back = call.get_payload();
			Json.Parser parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			} catch (GLib.Error e){
				warning ("Error while loading banner: %s\nDATA:%s\n", e.message, back);
				return;
			}

			var root = parser.get_root().get_object().get_object_member("sizes");
			string banner_url;
			if (root.has_member("mobile"))
				banner_url = root.get_object_member("mobile").get_string_member("url");
			else
				banner_url = root.get_object_member("web").get_string_member("url");

			string banner_on_disk = "assets/banners/"+screen_name+".png";
			if (!FileUtils.test(banner_on_disk, FileTest.EXISTS)){
				message("Loading banner...");
				try{
					File banner_file = File.new_for_uri(banner_url);
					FileInputStream in_stream = banner_file.read();
					Gdk.Pixbuf b = new Gdk.Pixbuf.from_stream(in_stream);
					banner_box.set_pixbuf(b);
					b.save(banner_on_disk, "png");
				} catch (GLib.Error ex) {
					warning ("Error while setting banner: %s", ex.message);
				}
			}else {
				banner_box.set_pixbuf(new Gdk.Pixbuf.from_file(banner_on_disk));
			}
		});
	}

}