

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


void clear () {
  var tm = new TweetModel ();

  tm.add (new Tweet ());
  tm.add (new Tweet ());
  tm.add (new Tweet ());
  tm.add (new Tweet ());
  tm.add (new Tweet ());
  tm.add (new Tweet ());
  tm.add (new Tweet ());
  tm.add (new Tweet ());

  assert (tm.get_n_items () == 8);

  tm.clear ();
  assert (tm.get_n_items () == 0);
}

void hide_rt () {
  var tm = new TweetModel ();

  var t1 = new Tweet ();
  t1.id = 1;
  t1.user_id = 10;
  t1.rt_by_id = 100;
  t1.is_retweet = true;

  tm.add (t1);

  tm.toggle_flag_on_retweet (100, Tweet.HIDDEN_FILTERED, true);

  assert (tm.get_n_items () == 1);
  assert (((Tweet)tm.get_item (0)).is_hidden);

  tm.toggle_flag_on_retweet (100, Tweet.HIDDEN_FILTERED, false);
  assert (!((Tweet)tm.get_item (0)).is_hidden);
}



int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/tweetmodel/basic-tweet-order", basic_tweet_order);
  GLib.Test.add_func ("/tweetmodel/tweet-removal", tweet_removal);
  GLib.Test.add_func ("/tweetmodel/clear", clear);
  GLib.Test.add_func ("/tweetmodel/hide-rt", hide_rt);

  return GLib.Test.run ();
}
