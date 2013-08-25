





using Gtk;

class DMTimeline : IPage, ITimeline, IMessageReceiver, ScrollWidget {
  public int unread_count { get;set; }
  public unowned MainWindow main_window {set; get;}
  protected Gtk.ListBox tweet_list {set; get;}
  public Account account {get; set;}
  private int id;
  private BadgeRadioToolButton tool_button;
  private bool loading = false;
  public int64 lowest_id {get; set; default = int64.MAX-2;}
  protected uint tweet_remove_timeout{get;set;}
  private ProgressEntry progress_entry = new ProgressEntry(75);
  public DeltaUpdater delta_updater {get;set;}


  public DMTimeline (int id) {
    this.id = id;
  }


  public void stream_message_received (StreamMessageType type, Json.Node root) {

  }


  public void on_join (int page_id, va_list arg_list) {

  }

  public void load_cached () {

  }

  public void load_newest () {

  }

  public void load_older () {

  }





  public void create_tool_button(RadioToolButton? group) {
    tool_button = new BadgeRadioToolButton(group, "dms");
    tool_button.label = "Home";
  }

  public RadioToolButton? get_tool_button() {
    return tool_button;
  }

  public int get_id() {
    return id;
  }

  private void update_unread_count() {
    tool_button.show_badge = (unread_count > 0);
    tool_button.queue_draw();
  }

}
