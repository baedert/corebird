
using Gtk;



class MentionsContainer : ScrollWidget {
	public MainWindow window;
	private TweetList list = new TweetList();

	public MentionsContainer(){
		base();
		this.add_with_viewport(list);
	}


}