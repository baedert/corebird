

class InlineMediaDownloader {
	public static const int THUMB_SIZE    = 50;


	public static async void try_load_media(Tweet t, string url) {
		if(!Settings.show_inline_media())
			return;

		/*
			Support For:
				* yfrog
				* ow.ly
				* say.ly
					* <img src="contentImage" src="(.*?)"

				* Youtube (Preview image with video indicator. Click on the video
				           opens/streams it in some video player)

		*/

		if(url.has_prefix("http://instagr.am")) {
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
		GLib.Idle.add(() => {
			var session = new Soup.SessionAsync();
			var msg     = new Soup.Message("GET", first_url);
			session.send_message(msg);
			string back = (string)msg.response_body.data;
			var regex = new GLib.Regex(regex_str, RegexCompileFlags.OPTIMIZE);
			MatchInfo info;
			regex.match(back, 0, out info);
			string real_url = info.fetch(match_index);
			if(real_url != null)
				load_inline_media.begin(t, real_url, session);

			return false;
		});
	}

	private static async void load_inline_media(Tweet t, string url,
	                                       Soup.Session? sess = null) {
		GLib.Idle.add(() => {
			Soup.Session session = sess;
			message("Directly Downloading %s", url);
			if(session == null)
				session = new Soup.SessionAsync();
			var msg     = new Soup.Message("GET", url);


			session.send_message(msg);
			try {
				var ms    = new MemoryInputStream.from_data(msg.response_body.data, null);
				var pic   = new Gdk.Pixbuf.from_stream(ms);
				string file_name = @"$(t.id)_$(t.user_id).png";

				int thumb_w, thumb_h;
				get_thumb_size(pic.get_width(), pic.get_height(), out thumb_w,
				               out thumb_h);
				var thumb = pic.scale_simple(thumb_w, thumb_h, Gdk.InterpType.TILES);

				string path = Utils.get_user_file_path("assets/media/"+file_name);
				string thumb_path = Utils.get_user_file_path("assets/media/thumbs/"
				                                             +file_name);
				Corebird.db.execute(@"UPDATE `cache` SET `media`='$path'
				                    WHERE `id`='$(t.id)';");
				t.media = path;
				pic.save(path, "png");
				thumb.save(thumb_path, "png");
				t.inline_media_added(thumb);
			} catch (GLib.Error e) {
				critical(e.message);
			}
			return false;
		});

	}


	private static void get_thumb_size(int pic_width, int pic_height,
	                                   out int width, out int height) {
		double size_ratio = pic_width / pic_height;

		width  = THUMB_SIZE;
		height = THUMB_SIZE;
	}
}