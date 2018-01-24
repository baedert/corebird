namespace Gd {

  [CCode (cprefix = "GdModelListBox_", lower_case_cprefix = "gd_model_list_box_", cheader_filename = "gd-model-list-box.h")]
  public class ModelListBox : Gtk.Widget {
    [CCode (has_construct_function = false)]
    public ModelListBox ();

    public signal void row_activated (Gtk.Widget row,
                                      [CCode (type = "gpointer")] GLib.Object item,
                                      uint item_index);
    public Cb.TweetModel model;

    public delegate Gtk.Widget ModelListBoxFillFunc ([CCode (type = "gpointer")] GLib.Object item,
                                                     Gtk.Widget widget, uint item_index);
    public delegate void ModelListBoxRemoveFunc (Gtk.Widget widget,
                                                 [CCode (type = "gpointer")] GLib.Object item);

    public void set_model (GLib.ListModel model,
                           owned ModelListBoxFillFunc? fill_func,
                           owned ModelListBoxRemoveFunc? remove_func);
  }
}
