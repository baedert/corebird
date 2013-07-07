/*  This file is part of corebird.
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

 using Gtk;

extern string cb_replace_links(string text);

class Tweet : GLib.Object{

	public static const int TYPE_NORMAL   = 1;
	public static const int TYPE_MENTION  = 2;
	public static const int TYPE_FAVORITE = 3;


	public static GLib.Regex link_regex;


	public int64 id;
	public int64 rt_id;
	public bool retweeted = false;
	public bool favorited = false;
	public string text;
	public int64 user_id;
	public string user_name;
	public string retweeted_by;
	public bool is_retweet;
	public Gdk.Pixbuf avatar {get; set;}
	public string time_delta = "-1s";
	/** The avatar url on the server */
	public string avatar_url;
	/** The name of the avatar image file on the hard disk */
	public string avatar_name;
	public string screen_name;
	public int64 created_at;
	public int64 rt_created_at;
	public bool verified = false;

  /** if 0, this tweet is NOT part of a conversation */
  public int64 reply_id = 0;
  public string media;
	public string media_thumb;
  public signal void inline_media_added(Gdk.Pixbuf? media);
  public bool has_inline_media = false;
  public int type = -1;


	public Tweet(){
		this.avatar = Twitter.no_avatar;
	}

	public void load_avatar(Gdk.Pixbuf? pixbuf = null){
		if(pixbuf != null){
			Twitter.avatars.set(avatar_name, pixbuf);
			this.avatar = pixbuf;
			return;
		}

		if (Twitter.avatars.has_key(avatar_name)){
		 	this.avatar = Twitter.avatars.get(avatar_name);
		 }else{
			string path = Utils.user_file("assets/avatars/"+avatar_name);
			if(FileUtils.test(path, FileTest.EXISTS)){
				try{
					Twitter.avatars.set(avatar_name, new Gdk.Pixbuf.from_file(path));
				}catch(GLib.Error e){
					warning("Error while loading avatar from database: %s", e.message);
				}
				this.avatar = Twitter.avatars.get(avatar_name);
			}
		}
	}

	public bool has_avatar(){
		return this.avatar != Twitter.no_avatar;
	}

	/**
	 * Fills all the data of this tweet from Json data.
	 * @param status The Json object to get the data from
	 * @param now The current time
	 */
	public void load_from_json(Json.Object status, GLib.DateTime now){
		Json.Object user = status.get_object_member("user");
		this.text        = status.get_string_member("text");
		this.favorited   = status.get_boolean_member("favorited");
		this.retweeted   = status.get_boolean_member("retweeted");
		this.id          = status.get_int_member("id");
		this.user_name   = user.get_string_member("name");
		this.user_id     = user.get_int_member("id");
		this.screen_name = user.get_string_member("screen_name");
		this.created_at  = Utils.parse_date(status.get_string_member("created_at"))
										.to_unix();
		this.avatar_url  = user.get_string_member("profile_image_url");
		this.verified    = user.get_boolean_member("verified");
        if(!status.get_null_member("in_reply_to_status_id"))
                this.reply_id  = status.get_int_member("in_reply_to_status_id");


		if (status.has_member("retweeted_status")){
			Json.Object rt      = status.get_object_member("retweeted_status");
			Json.Object rt_user = rt.get_object_member("user");
			this.is_retweet    = true;
			this.rt_id         = rt.get_int_member("id");
			this.retweeted_by  = user.get_string_member("name");
			this.text          = rt.get_string_member("text");
			this.user_name     = rt_user.get_string_member ("name");
			this.avatar_url    = rt_user.get_string_member("profile_image_url");
			this.user_id       = rt_user.get_int_member("id");
			this.screen_name   = rt_user.get_string_member("screen_name");
			this.rt_created_at = Utils.parse_date(rt.get_string_member("created_at"))
			                            .to_unix();
			this.verified      = rt_user.get_boolean_member("verified");
            if(!rt.get_null_member("in_reply_to_status_id"))
				this.reply_id = rt.get_int_member("in_reply_to_status_id");
		}
		this.avatar_name = Utils.get_avatar_name(this.avatar_url);



		// 'Resolve' the used URLs
		var entities = status.get_object_member("entities");

		var urls = entities.get_array_member("urls");
		urls.foreach_element((arr, index, node) => {
			var url = node.get_object();
			string expanded_url = url.get_string_member("expanded_url");
			expanded_url = expanded_url.replace("&", "&amp;");
			InlineMediaDownloader.try_load_media.begin(this, expanded_url);

			this.text = this.text.replace(url.get_string_member("url"),
			    expanded_url);
		});

		// The same with media
		if(entities.has_member("media")){
			var medias = entities.get_array_member("media");
			medias.foreach_element((arr, index, node) => {
				var url = node.get_object();
				string expanded_url = "https://"+url.get_string_member("display_url");
				InlineMediaDownloader.try_load_media.begin(this,
				        url.get_string_member("media_url"));
				expanded_url = expanded_url.replace("&", "&amp;");
				this.text = this.text.replace(url.get_string_member("url"),
				    expanded_url);
			});
		}




		var dt = new DateTime.from_unix_local(is_retweet ? rt_created_at : created_at);
		this.time_delta  = Utils.get_time_delta(dt, now);


		this.load_avatar();
		if(!this.has_avatar()){
			var session = new Soup.SessionAsync();
			var msg     = new Soup.Message("GET", this.avatar_url);
			session.queue_message(msg, (s, _msg) => {
				string dest = Utils.user_file("assets/avatars/"+
				                                       this.avatar_name);
				var memory_stream = new MemoryInputStream.from_data(
				                                   _msg.response_body.data,
				                                   null);
        try {
          var pixbuf = new Gdk.Pixbuf.from_stream_at_scale(memory_stream,
                                                           48, 48,
                                                           false);
          pixbuf.save(dest, "png");
          this.load_avatar(pixbuf);
        } catch (GLib.Error e) {
          critical (e.message);
        }
				debug("Loaded avatar for %s", screen_name);
				debug("Dest: %s", dest);
			});
		}
	}

  /**
	 * Replaces the links in the given text with html tags to be used in
	 * pango layouts.
	 *
	 * TODO: Also replace nicknames and hashtags here
   * TODO: Multiple links in one tweet don't work
	 * @param text The text to replace the links in
	 * @return The text with replaced links
	 */
	public static string replace_links(string text){
		if(link_regex == null){
			//TODO: Most regexes can be truly static.
			//TODO: This regex actually sucks.
      try {
        link_regex = new GLib.Regex(
        "http[s]{0,1}:\\/\\/[a-zA-Z\\_.\\+!\\?\\/#=&;\\-0-9%,~:]+",
        RegexCompileFlags.OPTIMIZE);
      } catch (GLib.RegexError e) {
        critical (e.message);
      }
		}
		string real_text = text;
		try{
			MatchInfo mi;
			if (link_regex.match(real_text, 0, out mi)){
				do{

					string link = mi.fetch(0);
					if (link.length > 25){
						if(link.has_prefix("http://"))
							link = link.substring(7);
						else //https
							link = link.substring(8);

						if(link.has_prefix("www."))
							link = link.substring(4);

						if(link.length > 25){
							link = link.substring(0, 25);
							link += "…";
						}

					}
					//TODO: This doesn't work for if there are multiple links in one
					//      tweet.
					real_text = real_text.replace(mi.fetch(0),
						"<a href='%s'>%s</a>".printf(mi.fetch(0), link));
				}while(mi.next());
			}

		}catch(GLib.RegexError e){
			warning("Error while applying regexes: %s", e.message);
		}

		return real_text;
	}
}
