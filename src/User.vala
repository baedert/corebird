


class User{
	/** screen_name, unique per user, e.g. baedert(always written as @baedert) */
	public static string screen_name;
	/** Normal name like 'Chuck Norris' */
	public static string name;
	private static string avatar_name = "no_profile_pic.png";
	public static string avatar_url;
	public static int64 id;

	public static string get_avatar_path(){
		return "assets/user/"+avatar_name;
	}


	/**
	 * Loads the user's cached data from the database.
	 */
	public static void load(){
		try{
			SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
				"SELECT screen_name, avatar_name, avatar_url, id FROM `user`;");
			SQLHeavy.QueryResult res = query.execute();
			User.screen_name = res.fetch_string(0);
			User.avatar_name = res.fetch_string(1);
			User.avatar_url  = res.fetch_string(2);
			User.id          = res.fetch_int64(3);
		}catch(SQLHeavy.Error e){
			error("Error while loading the user: %s", e.message);
		}
	}

	/**
	 * Updates the users's profile info.
	 *
	 * @param avatar_widget The widget to update if the avatar has changed.
	 */
	public static async void update_info(Gtk.Image? avatar_widget, bool use_name = false){
		var img_call = Twitter.proxy.new_call();
		img_call.set_function("1.1/users/show.json");
		img_call.set_method("GET");
		if(use_name || id == 0)
			img_call.add_param("screen_name", User.screen_name);
		else
			img_call.add_param("user_id", User.id.to_string());

		if(use_name || id== 0)
			message("Using the screen_name(%s)",screen_name);
		else
			message("Using the id");

		img_call.add_param("include_entities", "false");
		img_call.invoke_async.begin(null, (obj, res) => {
			try{
				img_call.invoke_async.end(res);
			} catch (GLib.Error e){
				warning("Error while ending img_call: %s", e.message);
				Utils.show_error_dialog(e.message);
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
			User.id = root.get_int_member("id");
			int64 id = root.get_int_member("id");
			message(@"ID: $id");
			avatar_url = root.get_string_member("profile_image_url");
			User.avatar_name = Utils.get_file_name(avatar_url);
			// Check if the avatar of the user has changed.
			if (avatar_name != User.avatar_name
			    	|| !FileUtils.test(get_avatar_path(), FileTest.EXISTS)){

				//TODO: Find better variable names here
				string dest_path = "assets/user/%s".printf(avatar_name);
				string big_dest  = "assets/avatars/"+Utils.get_avatar_name(avatar_url);
				var session = new Soup.SessionAsync();
				var msg = new Soup.Message("GET", avatar_url);
				session.send_message(msg);

				string type = Utils.get_file_type(avatar_name);

				try{
					var data_stream = new MemoryInputStream.from_data(
									(owned)msg.response_body.data,null);
					var pixbuf = new Gdk.Pixbuf.from_stream_at_scale(data_stream,
					                                                 24, 24, false);
					pixbuf.save(big_dest, type);
					pixbuf.scale_simple(24, 24, Gdk.InterpType.HYPER);
					pixbuf.save(dest_path, type);
				} catch(GLib.Error e) {

				}

				if(avatar_widget != null)
					avatar_widget.set_from_file(dest_path);

				try{
					Corebird.db.execute(@"UPDATE `user` SET `avatar_name`='$avatar_name',`avatar_url`='$avatar_url',`id`='$id';");
				}catch(SQLHeavy.Error e){
					warning("Error while setting the new avatar_name: %s", e.message);
				}
				message("Updated the avatar image!");
			}
		});
	}

}