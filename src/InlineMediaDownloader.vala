

class InlineMediaDownloader {
	public static const int THUMB_SIZE = 40;


	public static async void try_load_media(Tweet t, string url) {
		if(!Settings.show_inline_media())
			return;

		/*
			Support For:
				* yfrog
				* ow.ly
				* lockerz.com
				* say.ly
					* <img src="contentImage" src="(.*?)"
				* moby.tv

				* Youtube (Preview image with video indicator. Click on the video
				           opens/streams it in some video player)
				* vine!

		*/

		if(url.has_prefix("http://instagr.am") ||
		   url.has_prefix("http://instagram.com/p/")) {
			two_step_load.begin(t, url, "<img class=\"photo\" src=\"(.*?)\"", 1);
		} else if(url.has_prefix("http://i.imgur.com")) {
			load_inline_media.begin(t, url);
		} else if(url.has_prefix("http://d.pr/i/")) {
			two_step_load.begin(t, url, "<meta property=\"og:image\" content=\"(.*?)\"",
			                    1);
		} else if(url.has_prefix("http://pbs.twimg.com/media/")) {
			load_inline_media.begin(t, url);
		} else if(url.has_prefix("http://twitpic.com/")) {
			two_step_load.begin(t, url,
			                    "<meta name=\"twitter:image\" value=\"(.*?)\"", 1);
		} else if(url.has_prefix("http://ow.ly/i/")) {
			two_step_load.begin(t, url,
			                	"<meta name=\"twitter:image\" content=\"(.*?)\"", 1);
		}
	}

	private static async void two_step_load(Tweet t, string first_url, string regex_str,
	                                        int match_index) {
		var session = new Soup.SessionAsync();
		var msg     = new Soup.Message("GET", first_url);
		session.send_message(msg);
		session.queue_message(msg, (_s, _msg) => {
		string back = (string)_msg.response_body.data;
			try{
				var regex = new GLib.Regex(regex_str, RegexCompileFlags.OPTIMIZE);
				MatchInfo info;
				regex.match(back, 0, out info);
				string real_url = info.fetch(match_index);
				if(real_url != null)
					load_inline_media.begin(t, real_url, session);
			} catch (GLib.RegexError e) {
				critical("Regex Error: %s", e.message);
			}
		});

	}

	private static async void load_inline_media(Tweet t, string url,
	                                       Soup.Session? sess = null) {

		// First, check if the media already exists...
		string path = get_media_path (t, url);
		string thumb_path = get_thumb_path (t, url);
		message("THUMB PATH: %s", thumb_path);
		if(FileUtils.test(path, FileTest.EXISTS)) {
			/* If the media already exists, the thumbnail also exists.
			   If not, fuck you.*/ 
			message("%s already exists...", path);
			var thumb = new Gdk.Pixbuf.from_file(thumb_path);
			fire_media_added(t, path, thumb, thumb_path);
			return;
		}


		Soup.Session session = sess;
		message("Directly Downloading %s", url);
		if(session == null)
			session = new Soup.SessionAsync();

		var msg = new Soup.Message("GET", url);

		session.queue_message(msg, (s, _msg) => {
			try {
				var ms  = new MemoryInputStream.from_data(_msg.response_body.data, null);
				string ext = Utils.get_file_type(url);
				if(ext.length == 0)
					ext = "png";
				ext = ext.down();

				Gdk.Pixbuf thumb = null;
				if(ext == "gif"){
					var file = File.new_for_path(path);
					var fout = file.create(FileCreateFlags.REPLACE_DESTINATION);
					fout.write_all(_msg.response_body.data, null);
					fout.flush();
					var anim = new Gdk.PixbufAnimation.from_file(path);
					thumb = anim.get_static_image().scale_simple(THUMB_SIZE, THUMB_SIZE,
												Gdk.InterpType.TILES);
				} else {
					var pic = new Gdk.Pixbuf.from_stream(ms);
					pic.save(path, ext);
					thumb = pic.scale_simple(THUMB_SIZE, THUMB_SIZE,
						                         Gdk.InterpType.TILES);
				}

				thumb.save(thumb_path, "png");
				fire_media_added(t, path, thumb, thumb_path);
			} catch (GLib.Error e) {
				critical(e.message);
			}
		});
	}

	private static void fire_media_added(Tweet t, string path, Gdk.Pixbuf thumb,
			                             string thumb_path) {
		try{
			Corebird.db.execute(@"UPDATE `cache` SET `media`='$path', `media_thumb`='$thumb_path'
				                    WHERE `id`='$(t.id)';");
		}catch(SQLHeavy.Error e) {
			error(e.message);
		}
		t.media = path;
		t.media_thumb = thumb_path;
		t.inline_media_added(thumb);
		t.has_inline_media = true;
	}

	private static string get_media_path (Tweet t, string url) {
		string ext = Utils.get_file_type (url);
		ext = ext.down();
		if(ext.length == 0)
			ext = "png";

		return Utils.user_file(@"assets/media/$(t.id)_$(t.user_id).$(ext)");
	}

	private static string get_thumb_path (Tweet t, string url) {
		return Utils.user_file(@"assets/media/thumbs/$(t.id)_$(t.user_id).png");
	}
}
