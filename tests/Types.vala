// Bug 636 - copying tweets causes SIGSEGV later on original tweet
void copy_free_minitweet () {
  const string display_text = "#DisplayText";
  Cb.MiniTweet t1 = Cb.MiniTweet ();  
  t1.id = 100;
  t1.author = Cb.UserIdentity ();
  t1.author.id = 100;
  t1.entities = new Cb.TextEntity[1];
  t1.entities[0] = new Cb.TextEntity();
  t1.entities[0].display_text = display_text;
  t1.entities[0].tooltip_text = "";
  t1.entities[0].target = "";

  if (true) {
    // Put t2 in a block to try and trigger a free() at the end
    Cb.MiniTweet t2 = t1;
    // Simple assertion so that the block doesn't get optimised away
    assert (t1.entities[0].display_text == t2.entities[0].display_text);
  }

  // If everything is okay, entity.display_text should remain
  // If we have the bug, freeing t2 freed the display_text on t1
  assert (t1.entities[0].display_text == display_text);
}

int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/types/copy_and_free_minitweet", copy_free_minitweet);
  return GLib.Test.run ();
}