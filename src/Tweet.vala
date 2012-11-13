
using Gtk;


class Tweet : GLib.Object{
	


}



class TweetRenderer : Gtk.CellRenderer {
	public Tweet tweet{get;set;}

	public TweetRenderer(){
		GLib.Object();
	}

	public override void render (Cairo.Context ctx, Widget tree,
							 Gdk.Rectangle background_area, Gdk.Rectangle cell_area,
							 CellRendererState flags) {

	}




    public override void get_size (Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height) {
        x_offset = 0;
        y_offset = 0;
        width = 50;
        height = 50;
    }
}