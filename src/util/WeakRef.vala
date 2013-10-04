



class WeakRef<G> : GLib.Object {
  private GLib.WeakRef wr;

  public WeakRef (G obj) {
    this.wr = GLib.WeakRef ((GLib.Object)obj);
  }

  public new G get () {
    return wr.get ();
  }
}


