/*  This file is part of corebird.
 *
 *  Foobar is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Foobar is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;


class TweetTextView : TextView {
	private const uint MAX_TWEET_LENGTH = 140;
	public bool too_long{get;set; default = false;}
	private int length = 0;

	public TweetTextView(){
		this.key_release_event.connect( () => {
			this.length = this.buffer.text.length;
			this.too_long = this.length > MAX_TWEET_LENGTH;
			this.queue_draw();
			return false;
		});
	}


	public override bool draw(Cairo.Context c){
		StyleContext context = this.get_style_context();
		Allocation a;
		this.get_allocation(out a);
		Pango.Layout layout = this.create_pango_layout("");
		if (too_long)
			layout.set_markup("<small><span color='red'>%d/%u</span></small>".
			        printf(length, MAX_TWEET_LENGTH), -1);
		else
			layout.set_markup("<small>%d/%u</small>".printf(length,
			                  MAX_TWEET_LENGTH), -1);

		Pango.Rectangle layout_size;
		layout.get_extents(null, out layout_size);

		base.draw(c);
		context.render_layout(c, a.width  - (layout_size.width  / Pango.SCALE) - 5,
		                    	 a.height - (layout_size.height / Pango.SCALE) - 5,
		                    	 layout);
		return false;
	}

	public int get_length(){
		return length;
	}
}