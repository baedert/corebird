
using Gtk;

class ProfileWidget : Gtk.Box {
	private ImageBox banner_box     = new ImageBox(Orientation.VERTICAL, 3);
	private Image avatar_image      = new Image();
	private Label name_label        = new Label("");
	private Label screen_name_label = new Label("");
	private Label description_label = new Label("");
	private Label tweets_label      = new Label("");
	private Label follower_label    = new Label("");
	private Label following_label   = new Label("");
	private static string banner_css = "*{
		background-image: url('%s');
		background-size: 100% 100%;
	}";


	public ProfileWidget(){
		GLib.Object(orientation: Orientation.VERTICAL);
		banner_box.get_style_context().add_class("profile-header");
		avatar_image.margin_top = 20;
		banner_box.pack_start(avatar_image, false, false);
		name_label.set_use_markup(true);
		name_label.justify = Justification.CENTER;
		name_label.get_style_context().add_class("name");
		banner_box.pack_start(name_label, false, false);
		screen_name_label.set_use_markup(true);
		screen_name_label.get_style_context().add_class("screen-name");
		banner_box.pack_start(screen_name_label, false, false);
		description_label.set_use_markup(true);
		description_label.set_line_wrap(true);
		description_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
		description_label.justify = Justification.CENTER;
		description_label.margin_left = 5;
		description_label.margin_right = 5;
		description_label.get_style_context().add_class("description");
		banner_box.pack_start(description_label, false, false);
		this.pack_start(banner_box, false, false);

		var data_box = new Box(Orientation.HORIZONTAL, 3);
		tweets_label.set_use_markup(true);
		tweets_label.margin_left = 10;
		data_box.pack_start(tweets_label, false, false);
		following_label.set_use_markup(true);
		data_box.pack_start(following_label, true, true);
		follower_label.set_use_markup(true);
		follower_label.margin_right = 10;
		data_box.pack_start(follower_label, false, false);
		this.pack_start(data_box, false, false);
	}


	public void set_user_id(int64 user_id){
		screen_name_label.set_markup(@"<big>@$user_id</big>");
		//Load cached data
		try{
			SQLHeavy.Query cache_query = new SQLHeavy.Query(Corebird.db,
				@"SELECT id, screen_name, name, description, tweets,
						 following, followers, avatar_name
				FROM profiles
				WHERE id='$user_id';");
			SQLHeavy.QueryResult cache_result = cache_query.execute();
			if (!cache_result.finished){
				name_label.set_markup("<big><big><big><b>%s</b></big></big></big>"
					                      .printf(cache_result.fetch_string(1)));
				description_label.set_markup("<small>%s</small>"
					                             .printf(cache_result.fetch_string(2)));

				tweets_label.set_markup("<big><b>%'d</b></big>\nTweets".printf(cache_result.fetch_int(3)));
				following_label.set_markup("<big><b>%'d</b></big>\nFollowing".printf(cache_result.fetch_int(4)));
				follower_label.set_markup("<big><b>%'d</b></big>\nFollowers".printf(cache_result.fetch_int(5)));
				avatar_image.set_from_file("assets/avatars/%s".printf(cache_result.fetch_string(6)));
				if(FileUtils.test(@"assets/banners/$user_id.png", FileTest.EXISTS)){
					set_banner(Utils.get_user_file_path(@"assets/banners/$user_id.png"));
				}else
					set_banner("assets/no_banner.png"); // TODO: Change
			}else
				set_banner("assets/no_banner.png"); // TODO Change
		}catch(SQLHeavy.Error e){
			warning("Error while loading cached profile data: %s", e.message);
		}catch(GLib.Error e){
			warning("Error while loading cached banner: %s", e.message);
		}

		load_banner.begin(user_id);
		load_profile_data.begin(user_id);
	}


	private async void load_profile_data(int64 user_id){
		var call = Twitter.proxy.new_call();
		call.set_method("GET");
		call.set_function("1.1/users/show.json");
		call.add_param("user_id", user_id.to_string());
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
			avatar_image.set_from_file(avatar_on_disk);
			string name        = root.get_string_member("name");
			string screen_name = root.get_string_member("screen_name");
			string description = root.get_string_member("description").replace("&", "&amp;");
			int64 id		   = root.get_int_member("id");
			int followers      = (int)root.get_int_member("followers_count");
			int following      = (int)root.get_int_member("friends_count");
			int tweets         = (int)root.get_int_member("statuses_count");



			name_label.set_markup("<big><big><big><b>%s</b></big></big></big>"
			                      .printf(name));
			description_label.set_markup(description);

			tweets_label.set_markup("<big><b>%'d</b></big>\nTweets".printf(tweets));
			following_label.set_markup("<big><b>%'d</b></big>\nFollowing".printf(following));
			follower_label.set_markup("<big><b>%'d</b></big>\nFollowers".printf(followers));

			try{
				SQLHeavy.Query update_query = new SQLHeavy.Query(Corebird.db,
					"INSERT OR REPLACE INTO `profiles`(`id`, `screen_name`, `name`,
					   `followers`, `following`, `tweets`, `description`, `avatar_name`) VALUES
					(:id, :screen_name, :name, :followers, :following, :tweets, :description, :avatar_name);");
				update_query.set_int64(":id", id);
				update_query.set_string(":screen_name", screen_name);
				update_query.set_string(":name", name);
				update_query.set_int(":followers", followers);
				update_query.set_int(":following", following);
				update_query.set_int(":tweets", tweets);
				update_query.set_string(":description", description);
				update_query.set_string(":avatar_name", avatar_name);
				update_query.execute_async.begin();
			}catch(SQLHeavy.Error e){
				warning("Error while updating profile info for %s:%s", screen_name, e.message);
			}
		});
	}


	/**
	 * Loads the user's banner image.
	 */
	private async void load_banner(int64 user_id){
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
			// if (root.has_member("mobile"))
				// banner_url = root.get_object_member("mobile").get_string_member("url");
			// else
			banner_url = root.get_object_member("mobile").get_string_member("url");

			string banner_on_disk = Utils.get_user_file_path(@"assets/banners/$user_id.png");
			if (!FileUtils.test(banner_on_disk, FileTest.EXISTS)){
				message("Loading banner...");
				try{
					// TODO: Use soap here
					File banner_file = File.new_for_uri(banner_url);
					FileInputStream in_stream = banner_file.read();
					Gdk.Pixbuf b = new Gdk.Pixbuf.from_stream(in_stream);
					// banner_box.set_pixbuf(b);
					message("Banner saved.");
					b.save(banner_on_disk, "png");
					set_banner(banner_on_disk);
				} catch (GLib.Error ex) {
					warning ("Error while setting banner: %s", ex.message);
				}
			}else {
				try{
					// banner_box.set_pixbuf(new Gdk.Pixbuf.from_file(banner_on_disk));
				}catch(GLib.Error e){
					warning("Error while loading banner_on_disk: %s", e.message);
				}
			}
		});
	}

	private void set_banner(string path){
		try{
			CssProvider prov = new CssProvider();
			prov.load_from_data(banner_css.printf(path), -1);
			banner_box.get_style_context().add_provider(prov,
		                       	         STYLE_PROVIDER_PRIORITY_APPLICATION);
		} catch (GLib.Error e){
			warning(e.message);
		}
	}
}