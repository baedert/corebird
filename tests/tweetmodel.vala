

void basic_tweet_order () {
  TweetModel tm = new TweetModel ();

  Tweet t1 = new Tweet ();
  t1.id = 10;

  Tweet t2 = new Tweet ();
  t2.id = 100;

  Tweet t3 = new Tweet ();
  t3.id = 1000;


  tm.add (t3); // 1000
  tm.add (t1); // 10
  tm.add (t2); // 100

  assert (tm.get_n_items () == 3);




  assert (((Tweet)tm.get_item (0)).id == 1000);
  assert (((Tweet)tm.get_item (1)).id == 100);
  assert (((Tweet)tm.get_item (2)).id == 10);
}


void tweet_removal () {
  var tm = new TweetModel ();

  //add 10 visible tweets
  for (int i = 0; i < 10; i ++) {
    var t = new Tweet ();
    t.id = 100 - i;
    tm.add (t);
  }

  // now add 2 invisible tweets
  {
    var t = new Tweet ();
    t.id = 2;
    t.hidden_flags |= Tweet.HIDDEN_FORCE;

    tm.add (t);

    t = new Tweet ();
    t.id = 1;
    t.hidden_flags |= Tweet.HIDDEN_UNFOLLOWED;

    tm.add (t);
  }

  // We should have 12 now
  assert (tm.get_n_items () == 12);

  // Now remove the last 5 visible ones.
  // This should remove both invisible tweets as well as 5 visible ones
  // Leaving the model with 5 remaining tweets
  tm.remove_last_n_visible (5);

  assert (tm.get_n_items () == 5);


}


int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/tweetmodel/basic-tweet-order", basic_tweet_order);
  GLib.Test.add_func ("/tweetmodel/tweet-removal", tweet_removal);

  return GLib.Test.run ();
}
