

class InlineMediaDownloader {
	public static const int THUMB_SIZE    = 50;


	public static async void try_load_media(Tweet t, string url) {
		if(!Settings.show_inline_media())
			return;

		/*
			Support For:
				* pic.twitter.com
				* twitpic.com (see tweedle upload)
				* droplr
				* instagram

		*/

		if(url.has_prefix("http://instagr.am")) {
			two_step_load(t, url, "<img class=\"photo\" src=\"(.*?)\"", 1);
		} else if(url.has_prefix("http://i.imgur.com")) {
			// load_inline_media.begin(t, url);
		} else if(url.has_prefix("http://d.pr/")) {
			// load_droplr_media.begin(t, url);
		} else if(url.has_prefix("http://www.youtube.com/watch?v=")) {
			// load_yt_media.begin(t, url);
		}
	}

	private static  void two_step_load(Tweet t, string first_url, string regex_str,
	                                        int match_index) {
		var session = new Soup.SessionAsync();
		var msg     = new Soup.Message("GET", first_url);
		session.queue_message(msg, (s, m) => {
			string back = (string)m.response_body.data;
			message(regex_str);
			var regex = new GLib.Regex(regex_str, RegexCompileFlags.OPTIMIZE);
			MatchInfo info;
			regex.match(back, 0, out info);
			string real_url = info.fetch(match_index);
			load_inline_media(t, real_url);
		});
	}

	private static  void load_inline_media(Tweet t, string url, Soup.Session? sess = null) {
		Soup.Session session = sess;
		if(session == null)
			session = new Soup.SessionAsync();
		var msg     = new Soup.Message("GET", url);

		session.queue_message(msg, (s, m) => {
			try {
				var ms    = new MemoryInputStream.from_data(m.response_body.data, null);
				var pic   = new Gdk.Pixbuf.from_stream(ms);
				string file_name = @"$(t.id)_$(t.user_id).png";

				var thumb = pic.scale_simple(THUMB_SIZE, THUMB_SIZE, Gdk.InterpType.TILES);

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
		});
	}


	private static void scale(out int width, out int height) {

	}
}