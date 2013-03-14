
using Gtk;

class ProfileWidget : Gtk.Box {
	private ImageBox banner_box         = new ImageBox(Orientation.VERTICAL, 3);
	private ImageBox avatar_image       = new ImageBox(Orientation.VERTICAL, 0);
	private Label name_label            = new Label("");
	private Label description_label     = new Label("");
	private Label url_label             = new Label("");
	private Label location_label        = new Label("");
	private TextButton tweets_button    = new TextButton();
	private TextButton following_button = new TextButton();
	private TextButton followers_button = new TextButton();

	public ProfileWidget(){
		GLib.Object(orientation: Orientation.VERTICAL);

		banner_box.get_style_context().add_class("profile-header");
		var top_banner_box = new Gtk.Box(Orientation.HORIZONTAL, 8);
		avatar_image.set_size_request(100, 100);
		avatar_image.margin_left = 8;
		avatar_image.margin_top  = 8;
		top_banner_box.pack_start(avatar_image, false, false);


		var data_box = new Gtk.Box(Orientation.VERTICAL, 5);
		name_label.get_style_context().add_class("data");
		name_label.set_alignment(0, 0.5f);
		name_label.margin_top = 8;
		data_box.pack_start(name_label, false, true);
		url_label.set_alignment(0, 0.5f);
		url_label.get_style_context().add_class("data");
		data_box.pack_start(url_label, false, true);
		location_label.set_alignment(0, 0.5f);
		location_label.get_style_context().add_class("data");
		data_box.pack_start(location_label, false, true);
		top_banner_box.pack_start(data_box, true, true);

		banner_box.pack_start(top_banner_box, false, false);

		description_label.set_use_markup(true);
		description_label.set_line_wrap(true);
		description_label.get_style_context().add_class("description");
		description_label.set_justify(Justification.CENTER);
		description_label.margin_bottom = 5;
		banner_box.pack_start(description_label, true, true);

		var bottom_banner_box = new Gtk.Box(Orientation.HORIZONTAL, 0);
		bottom_banner_box.homogeneous = true;

		tweets_button.get_style_context().add_class("data-button");
		following_button.get_style_context().add_class("data-button");
		followers_button.get_style_context().add_class("data-button");
		bottom_banner_box.pack_start(tweets_button, false, true);
		bottom_banner_box.pack_start(following_button, false, true);
		bottom_banner_box.pack_start(followers_button, false, true);


		banner_box.pack_start(bottom_banner_box, false, false);

		this.pack_start(banner_box, false, false);
		// this.pack_start(bottom_banner_box, false, false);
	}


	public void set_user_id(int64 user_id, string screen_name = ""){
		if(user_id != 0 && screen_name != "") {
			error("Can't use both user_id and screen_name.");
		}

		load_profile_data.begin(user_id, screen_name);

		//Load cached data
		try{
			string query_string = "SELECT id, screen_name, name, description, tweets,
						 following, followers, avatar_name,banner_url,
						 url, location FROM profiles ";
			if(user_id != 0)
				query_string += @"WHERE id='$user_id';";
			else
				query_string += @"WHERE screen_name='$screen_name';";

			SQLHeavy.Query cache_query = new SQLHeavy.Query(Corebird.db,
			                                                query_string);
			SQLHeavy.QueryResult cache_result = cache_query.execute();
			if (!cache_result.finished){
				if(screen_name != "")
					user_id = cache_result.fetch_int64(0);

				string url = cache_result.fetch_string(9);
				string location = cache_result.fetch_string(10);

				load_banner.begin(user_id, cache_result.fetch_string(8));

				name_label.set_markup("<big><big><b>%s</b>  @%s</big></big>"
					                      .printf(cache_result.fetch_string(2),
					                              cache_result.fetch_string(1)));
				description_label.set_markup("<big><big><big>%s</big></big></big>".
				                             printf(cache_result.fetch_string(3)));
				if(url != "") {
					url_label.visible = true;
					url_label.set_markup("<big><big><a href='%s'>%s</a></big></big>"
					                     .printf(url, url));
				}else
					url_label.visible = false;

				if(location != "") {
					location_label.visible = true;
					location_label.set_markup("<big><big>%s</big></big>"
				    	                      .printf(cache_result.fetch_string(10)));
				}else
					location_label.visible = false;
				tweets_button.set_markup(
						"<big><big><b>%'d</b></big></big>\nTweets"
						.printf(cache_result.fetch_int(4)));
				following_button.set_markup(
						"<big><big><b>%'d</b></big></big>\nFollowing"
						.printf(cache_result.fetch_int(5)));
				followers_button.set_markup(
						"<big><big><b>%'d</b></big></big>\nFollowers"
						.printf(cache_result.fetch_int(6)));
				avatar_image.set_background(Utils.get_user_file_path(
				                           "/assets/avatars/"+cache_result.fetch_string(7)));
				if(FileUtils.test(Utils.get_user_file_path(@"assets/banners/$user_id.png"),
								  FileTest.EXISTS)){
					banner_box.set_background(Utils.get_user_file_path(
					                          @"assets/banners/$user_id.png"));
				}else
					banner_box.set_background(DATADIR+"/no_banner.png");
			}else
				banner_box.set_background(DATADIR+"/no_banner.png");
		}catch(SQLHeavy.Error e){
			warning("Error while loading cached profile data: %s", e.message);
		}
	}


	private async void load_profile_data(int64 user_id, string screen_name = ""){
		return;
		if(user_id != 0 && screen_name != "") {
			error("Can't use both user_id and screen_name.");
		}

		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/users/show.json");
		if(user_id != 0)
			call.add_param("user_id", user_id.to_string());
		else
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

			// stdout.printf("\n\n\n%s\n\n\n", back);
			var root = parser.get_root().get_object();
			string avatar_url = root.get_string_member("profile_image_url");
			string avatar_name = Utils.get_avatar_name(avatar_url);
			string avatar_on_disk = Utils.get_user_file_path("assets/avatars/"+avatar_name);
			//TODO: Also use libsoup here
			if(!FileUtils.test(avatar_on_disk, FileTest.EXISTS)){
				File av = File.new_for_uri(avatar_url);
				File dest = File.new_for_path(avatar_on_disk);
				try{
					av.copy(dest, FileCopyFlags.OVERWRITE);
				}catch(GLib.Error e){
					warning("Error while copying avatar to disk: %s", e.message);

				}
			}
			avatar_image.set_background(avatar_on_disk);
			string name        = root.get_string_member("name");
			       screen_name = root.get_string_member("screen_name");
			string description = root.get_string_member("description").replace("&", "&amp;");
			int64 id		   = root.get_int_member("id");
			int followers      = (int)root.get_int_member("followers_count");
			int following      = (int)root.get_int_member("friends_count");
			int tweets         = (int)root.get_int_member("statuses_count");
			bool has_url       = root.get_object_member("entities").has_member("url");

			string display_url = "";
			if(has_url) {
				var urls_object = root.get_object_member("entities")
					.get_object_member("url").get_array_member("urls").get_element(0)
						.get_object();

				var url = urls_object.get_string_member("expanded_url");
				if(urls_object.has_member("display_url")){
					display_url = urls_object.get_string_member("display_url");
				}else{
					url = urls_object.get_string_member("url");
					display_url = url;
				}

				url_label.set_markup("<big><big><a href='%s'>%s</a></big></big>".printf(
			                     url, display_url));
				url_label.visible = true;
			} else
				url_label.visible = false;

			string location = "";
			if(root.has_member("location")){
				location	   = root.get_string_member("location");
				if(location != "")
					location_label.visible = true;
				location_label.set_markup("<big><big>%s</big></big>".printf(location));
			} else
				location_label.visible = false;


			name_label.set_markup("<big><big><b>%s</b>  @%s</big></big>"
				                      .printf(name, screen_name));
			description_label.set_markup("<big><big><big>%s</big></big></big>".printf(
			                             description));
			tweets_button.set_markup(
					"<big><big><b>%'d</b></big></big>\nTweets"
					.printf(tweets));
			following_button.set_markup(
					"<big><big><b>%'d</b></big></big>\nFollowing"
					.printf(followers));
			followers_button.set_markup(
					"<big><big><b>%'d</b></big></big>\nFollowers"
					.printf(following));

			try{
				SQLHeavy.Query update_query = new SQLHeavy.Query(Corebird.db,
					"INSERT OR REPLACE INTO `profiles`(`id`, `screen_name`, `name`,
					   `followers`, `following`, `tweets`, `description`, `avatar_name`,
					   `url`, `location`)
					 VALUES
					(:id, :screen_name, :name, :followers, :following, :tweets,
					 :description, :avatar_name, :url, :location);");
				update_query.set_int64(":id", id);
				update_query.set_string(":screen_name", screen_name);
				update_query.set_string(":name", name);
				update_query.set_int(":followers", followers);
				update_query.set_int(":following", following);
				update_query.set_int(":tweets", tweets);
				update_query.set_string(":description", description);
				update_query.set_string(":avatar_name", avatar_name);
				update_query.set_string(":url", display_url);
				update_query.set_string(":location", location);
				update_query.execute_async.begin();
			}catch(SQLHeavy.Error e){
				warning("Error while updating profile info for %s:%s", screen_name,
						e.message);
			}
		});
	}


	/**
	 * Loads the user's banner image.
	 *
	 * @param user_id The user's ID
	 */
	private async void load_banner(int64 user_id, string saved_banner_url){

		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/users/profile_banner.json");
		call.add_param("user_id", user_id.to_string());

		call.invoke_async.begin(null, (obj, res) => {
			if (call.get_status_code() == 404){
				// Normal. The user has not set a profile banner.
				message("No Banner set.");
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
			banner_url = root.get_object_member("mobile").get_string_member("url");

			string banner_on_disk = Utils.get_user_file_path(@"assets/banners/$user_id.png");
			if (!FileUtils.test(banner_on_disk, FileTest.EXISTS) ||
			    banner_url != saved_banner_url){
				message("Loading banner...%s\n%s", banner_url, saved_banner_url);
				try{
					// TODO: Use soap here
					File banner_file = File.new_for_uri(banner_url);
					FileInputStream in_stream = banner_file.read();
					Gdk.Pixbuf b = new Gdk.Pixbuf.from_stream(in_stream);
					message("Banner saved.");
					b.save(banner_on_disk, "png");
					Corebird.db.execute(@"UPDATE `profiles` SET `banner_url`='$banner_url'
					                    WHERE `id`='$user_id';");
				} catch (GLib.Error ex) {
					warning ("Error while setting banner: %s", ex.message);
				}
			}
			banner_box.set_background(banner_on_disk);
		});
	}

}