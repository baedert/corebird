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

class ProgressEntry : Box, ITwitterItem {
  public int64 sort_factor{
    get{ return 0;}
  }
  public bool seen{get; set; default = true;}
	private Spinner spinner 		= new Spinner();
	private Button cancel_button 	= new Button();

	public ProgressEntry(int size = 25, bool show_stop_button = false){
		GLib.Object(orientation: Orientation.HORIZONTAL, spacing: 3);
		this.get_style_context().add_class("progress-item");
		this.pack_start(spinner, true, true);
    if(show_stop_button) {
	  	cancel_button.image = new Image.from_stock(Stock.CANCEL, IconSize.LARGE_TOOLBAR);
	  	cancel_button.clicked.connect( () => {
	  		this.stop();
	  		this.parent.remove(this);
	  	});
		  this.pack_start(cancel_button, false, false);
    }
		this.border_width = 5;
		spinner.set_size_request(size, size);
		this.set_size_request(size, size);

    this.start();
	}



	public void start(){
		spinner.start();
	}

	public void stop(){
		spinner.stop();
	}
}
