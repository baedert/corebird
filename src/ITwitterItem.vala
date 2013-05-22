

interface ITwitterItem : Gtk.Widget {
 public static int sort_func(Gtk.Widget a, Gtk.Widget b) {
    if(((ITwitterItem)a).sort_factor <
       ((ITwitterItem)b).sort_factor)
      return 1;
    return -1;
  }
    
  public abstract int64 sort_factor {get;}
  public abstract bool seen {get; set;}
}
