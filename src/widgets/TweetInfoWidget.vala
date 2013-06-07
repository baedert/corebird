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

class TweetInfoWidget :Gtk.ScrolledWindow{
	private int64 tweet_id;


	public TweetInfoWidget(Tweet t, MainWindow window){
		this.tweet_id = t.id;
		UIBuilder builder = new UIBuilder("ui/tweet-info-window.ui", "main_box");
		var box = builder.get_box("main_box");


		builder.get_label("text").label = t.text;
		builder.get_label("name").label = "<big><b>"+t.user_name+"</b></big>";
		builder.get_label("screen_name").label = "<small>@"+t.screen_name+"</small>";
		builder.get_image("avatar").pixbuf = t.avatar;
		builder.get_label("time_delta").label = t.time_delta;
		builder.get_toggle("retweet_button").active = t.retweeted;
		builder.get_toggle("favorite_button").active = t.favorited;

		builder.get_button("close_button").clicked.connect(() => {
			});



		this.hscrollbar_policy = PolicyType.NEVER;
		this.add_with_viewport(box);
		this.show_all();
	}

	public int64 get_id(){
		return tweet_id;
	}
}
