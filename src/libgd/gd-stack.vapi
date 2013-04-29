namespace Gd {
	[CCode (cheader_filename = "gd-stack.h")]
	public class Stack : Gtk.Container{
		public enum TransitionType{
			NONE,
			CROSSFADE,
			SLIDE_RIGHT,
			SLIDE_LEFT
		}
		// Properties
		public bool homogeneous{get; set;}
		public Gtk.Widget visible_child{get; set;}
		public string visible_child_name{get; set;}
		public int transition_duration{get; set;}
		public TransitionType transition_type{get; set;}


		public Stack();
		public void add_named(Gtk.Widget child, string name);
		public void add_titled(Gtk.Widget child, string name, string title);
		public void set_visible_child_name(string name);
	}
}