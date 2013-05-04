

class InlineMediaDownloader {
	public static const int THUMB_SIZE = 50;


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


		Soup.Session session = sess;
		message("Directly Downloading %s", url);
		if(session == null)
			session = new Soup.SessionAsync();

		var msg = new Soup.Message("GET", url);

		session.queue_message(msg, (s, _msg) => {
			try {
				var ms  = new MemoryInputStream.from_data(_msg.response_body.data, null);
				var pic = new Gdk.Pixbuf.from_stream(ms);
				string ext = Utils.get_file_type(url);

				if(ext.length == 0)
					ext = "png";

				string file_name = @"$(t.id)_$(t.user_id).$(ext)";

				int thumb_w, thumb_h;
				get_thumb_size(pic.get_width(), pic.get_height(), out thumb_w,
				               out thumb_h);
				var thumb = pic.scale_simple(thumb_w, thumb_h, Gdk.InterpType.TILES);

				string path = Utils.user_file("assets/media/"+file_name);
				string thumb_path = Utils.user_file("assets/media/thumbs/"
				                                             +file_name);
				Corebird.db.execute(@"UPDATE `cache` SET `media`='$path'
				                    WHERE `id`='$(t.id)';");
				t.media = path;
				pic.save(path, ext);
				thumb.save(thumb_path, ext);
				t.inline_media_added(thumb);
			} catch (GLib.Error e) {
				critical(e.message);
			}
		});
	}


	private static void get_thumb_size(int pic_width, int pic_height,
	                                   out int width, out int height) {
		double size_ratio = pic_width / pic_height;

		width  = THUMB_SIZE;
		height = THUMB_SIZE;
	}
}
