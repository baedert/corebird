


class User{
	/** screen_name, unique per user, e.g. baedert(always written as @baedert) */
	public static string screen_name;
	/** Normal name like 'Chuck Norris' */
	public static string name;
	private static string avatar_name = "no_profile_pic.png";
	public static string avatar_url;

	public static string get_avatar_path(){
		return "assets/user/"+avatar_name;
	}


	/**
	 * Loads the user's cached data from the database.
	 */
	public static void load(){
		try{
			SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
				"SELECT screen_name, avatar_name, avatar_url FROM `user`;");
			SQLHeavy.QueryResult res = query.execute();
			User.screen_name = res.fetch_string(0);
			User.avatar_name = res.fetch_string(1);
		}catch(SQLHeavy.Error e){
			error("Error while loading the user: %s", e.message);
		}
	}

	/**
	 * Updates the users's profile info.
	 *
	 * @param avatar_widget The widget to update if the avatar has changed.
	 */
	public static async void update_info(Gtk.Image avatar_widget){

		var img_call = Twitter.proxy.new_call();
		img_call.set_function("1.1/users/show.json");
		img_call.set_method("GET");
		img_call.add_param("screen_name", User.screen_name);
		img_call.add_param("include_entities", "false");
		img_call.invoke_async.begin(null, (obj, res) => {
			try{
				img_call.invoke_async.end(res);
			} catch (GLib.Error e){
				warning("Error while ending img_call: %s", e.message);
				return;
			}

			string back = img_call.get_payload();
			var parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			}catch(GLib.Error e){
				warning("Error while updating profile: %s", e.message);
				return;
			}
			var root = parser.get_root().get_object();
			User.name = root.get_string_member("name");
			avatar_url = root.get_string_member("profile_image_url");
			User.avatar_name = Utils.get_file_name(avatar_url);
			// Check if the avatar of the user has changed.
			if (avatar_name != User.avatar_name
			    || !FileUtils.test(get_avatar_path(), FileTest.EXISTS)){
				File user_avatar = File.new_for_uri(avatar_url);
				// TODO: This is insanely imperformant and stupid. FIX!
				string dest_path = "assets/user/%s".printf(avatar_name);
				File dest = File.new_for_path(dest_path);
				File big_dest = File.new_for_path("assets/avatars/%s".printf(Utils.get_avatar_name(avatar_url)));
				try{
					// Download-> save -> load -> scale -> save
					user_avatar.copy(dest, FileCopyFlags.OVERWRITE); 
					//Also save it in the normal avatars folder.
					user_avatar.copy(big_dest, FileCopyFlags.OVERWRITE);
					Gdk.Pixbuf av = new Gdk.Pixbuf.from_file(dest_path);
					Gdk.Pixbuf scaled = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 24, 24);
					av.scale(scaled, 0, 0, 24, 24, 0, 0, 0.5, 0.5, Gdk.InterpType.HYPER);
					// Overwrite current avatar because its too big.
					string type = Utils.get_file_type(avatar_name);
					scaled.save (dest_path, type);
				} catch (GLib.Error e){
					warning("Error while scaling the avatar: %s", e.message);
				}

				avatar_widget.set_from_file(dest_path);
				try{
					SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db, 
					"UPDATE `user` SET `avatar_name`='%s', `avatar_url`='%s';".printf(avatar_name,
						avatar_url));
					query.execute();
				}catch(SQLHeavy.Error e){
					warning("Error while setting the new avatar_name: %s", e.message);
				}
				message("Updated the avatar image!");
			}
		});
	}

}