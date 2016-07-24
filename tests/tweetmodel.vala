
bool is_sorted (TweetModel tm) {
  int64 last_id = ((Cb.Tweet)tm.get_item (0)).id;

  for (int i = 1; i < tm.get_n_items (); i ++) {
    Cb.Tweet t = (Cb.Tweet)tm.get_item (i);
    if (t.id > last_id) return false;

    last_id = t.id;
  }
  return true;
}

int64 get_max_id (TweetModel tm) {
  int64 max = -1;

  for (int i = 0; i < tm.get_n_items (); i ++) {
    var t = (Cb.Tweet)tm.get_item (i);
    if (t.id > max) max = t.id;
  }

  return max;
}

void basic_tweet_order () {
  TweetModel tm = new TweetModel ();

  Cb.Tweet t1 = new Cb.Tweet ();
  t1.id = 10;

  Cb.Tweet t2 = new Cb.Tweet ();
  t2.id = 100;

  Cb.Tweet t3 = new Cb.Tweet ();
  t3.id = 1000;


  tm.add (t3); // 1000
  tm.add (t1); // 10
  tm.add (t2); // 100

  assert (tm.get_n_items () == 3);

  assert (((Cb.Tweet)tm.get_item (0)).id == 1000);
  assert (((Cb.Tweet)tm.get_item (1)).id == 100);
  assert (((Cb.Tweet)tm.get_item (2)).id == 10);
}


void tweet_removal () {
  var tm = new TweetModel ();

  //add 10 visible tweets
  for (int i = 0; i < 10; i ++) {
    var t = new Cb.Tweet ();
    t.id = 100 - i;
    tm.add (t);
  }

  // now add 2 invisible tweets
  {
    var t = new Cb.Tweet ();
    t.id = 2;
    t.set_flag (Cb.TweetState.HIDDEN_FORCE);
    tm.add (t);

    assert (tm.get_n_items () == 10);

    t = new Cb.Tweet ();
    t.id = 1;
    t.set_flag (Cb.TweetState.HIDDEN_UNFOLLOWED);
    tm.add (t);

    assert (tm.get_n_items () == 10);
  }

  // We should have 10 now
  assert (tm.get_n_items () == 10);

  // Now remove the last 5 visible ones.
  // This should remove 2 invisible tweets as well as 5 visible ones
  // Leaving the model with 5 remaining tweets
  tm.remove_last_n_visible (5);

  assert (tm.get_n_items () == 5);
}


void clear () {
  var tm = new TweetModel ();

  const int n = 10;

  for (int i = 0; i < n; i++) {
    var t = new Cb.Tweet ();
    t.id = 100 + i;

    tm.add (t);
  }

  assert (tm.get_n_items () == n);

  tm.clear ();
  assert (tm.get_n_items () == 0);
}

void clear2 () {
  var tm1 = new TweetModel ();
  var tm2 = new TweetModel ();

  var t = new Cb.Tweet ();
  t.id = 10000;
  tm1.add (t);

  var t2 = new Cb.Tweet ();
  t2.id = 3400;
  t2.set_flag (Cb.TweetState.HIDDEN_FORCE);
  tm1.add(t2);

  tm1.clear ();

  assert (tm1.get_n_items () == tm2.get_n_items ());
  assert (tm1.greatest_id == tm2.greatest_id);
  assert (tm1.lowest_id == tm2.lowest_id);
  assert (tm1.hidden_tweets.length == 0);
}

void remove_tweet () {
  var tm = new TweetModel ();

  var t1 = new Cb.Tweet ();
  t1.id = 10;
  tm.add (t1);

  var t2 = new Cb.Tweet ();
  t2.id = 100;
  tm.add (t2);

  assert (tm.get_n_items () == 2);

  tm.remove_tweet (t2);

  assert (tm.get_n_items () == 1);

  tm.remove_tweet (t1);

  assert (tm.get_n_items () == 0);
}

void remove_hidden () {
  var tm = new TweetModel ();

  var t1 = new Cb.Tweet ();
  t1.id = 10;
  t1.set_flag (Cb.TweetState.HIDDEN_UNFOLLOWED);
  tm.add (t1);

  assert (tm.get_n_items () == 0);
  assert (tm.hidden_tweets.length == 1);

  tm.remove_tweet (t1);
  assert (tm.get_n_items () == 0);
  assert (tm.hidden_tweets.length == 0);
}

void remove_own_retweet () {
  var tm = new TweetModel ();

  var t1 = new Cb.Tweet ();
  t1.id = 1337;
  t1.my_retweet = 500; // <--
  t1.set_flag (Cb.TweetState.RETWEETED);

  tm.add (t1);

  for (int i = 1; i < 51; i ++) {
    var t = new Cb.Tweet ();
    t.id = i;
    tm.add (t);
  }

  assert (tm.get_n_items () == 51);

  //tm.remove (5);
  //assert (tm.get_n_items () == 50);

  // should not actually remove any tweet
  tm.remove_tweet (t1);
  assert (tm.get_n_items () == 50);
}

void hide_rt () {
  var tm = new TweetModel ();

  var t1 = new Cb.Tweet ();
  t1.id = 100;
  t1.source_tweet = Cb.MiniTweet ();
  t1.source_tweet.author = Cb.UserIdentity ();
  t1.source_tweet.author.id = 10;
  t1.source_tweet.id = 1;
  t1.retweeted_tweet = Cb.MiniTweet ();
  t1.retweeted_tweet.id = 100;
  t1.retweeted_tweet.author = Cb.UserIdentity ();
  t1.retweeted_tweet.author.id = 100;

  tm.add (t1);
  assert (!t1.is_hidden ());

  tm.toggle_flag_on_retweet (10, Cb.TweetState.HIDDEN_FILTERED, true);
  assert (t1.is_hidden ());

  assert (tm.get_n_items () == 0);

  tm.toggle_flag_on_retweet (10, Cb.TweetState.HIDDEN_FILTERED, false);
  assert (!t1.is_hidden ());
  assert (tm.get_n_items () == 1);
  assert (!((Cb.Tweet)tm.get_item (0)).is_hidden ());
}


void get_from_id () {
  var tm = new TweetModel ();

  var t1 = new Cb.Tweet ();
  t1.id = 10;

  var t2 = new Cb.Tweet ();
  t2.id = 100;

  tm.add (t1);
  tm.add (t2);

  assert (tm.get_n_items () == 2);
  assert (((Cb.Tweet)tm.get_item (0)).id == 100);
  assert (((Cb.Tweet)tm.get_item (1)).id == 10);

  var result = tm.get_from_id (10, -1);

  assert (result != null);
  assert (result.id == 100);

}

void min_max_id () {
  var tm = new TweetModel ();
  var t = new Cb.Tweet ();
  t.id = 1337;
  tm.add (t);

  var t2 = new Cb.Tweet ();
  t2.id = 30000;
  t2.set_flag (Cb.TweetState.HIDDEN_FORCE);
  tm.add (t2); // Hidden tweets shouldn't affect teh min/max id values

  assert (tm.lowest_id == 1337);
  assert (tm.greatest_id == 1337);
}


void sorting () {
  var tm = new TweetModel ();

  for (int i = 0; i < 100; i ++) {
    var t = new Cb.Tweet ();
    t.id = GLib.Random.next_int ();
    tm.add (t);
  }

  assert (is_sorted (tm));
}

void min_max_remove () {
  var tm = new TweetModel ();

  var t1 = new Cb.Tweet ();
  t1.id = 10;
  tm.add (t1);

  var t2 = new Cb.Tweet ();
  t2.id = 20;
  tm.add (t2);

  var t3 = new Cb.Tweet ();
  t3.id = 2;
  tm.add (t3);

  assert (tm.greatest_id == 20);
  assert (tm.lowest_id == 2);

  tm.remove_tweet (t1);
  // Should still be the same
  assert (tm.greatest_id == 20);
  assert (tm.lowest_id == 2);

  var t = new Cb.Tweet ();
  t.id = 10;
  tm.add (t);

  // And again...
  assert (tm.greatest_id == 20);
  assert (tm.lowest_id == 2);


  // Now it gets interesting
  tm.remove_tweet (t2);
  assert (tm.lowest_id == 2);
  assert (tm.greatest_id == 10);
  assert (tm.greatest_id == get_max_id (tm));

  tm.remove_tweet (t3);
  assert (tm.lowest_id == 10);
  assert (tm.greatest_id == 10);

  tm.remove_tweet (t1);
  assert (tm.lowest_id == int64.MAX);
  assert (tm.greatest_id == int64.MIN);
}

void tweet_count () {
  var tm = new TweetModel ();

  var t1 = new Cb.Tweet ();
  t1.id = 10;
  t1.source_tweet = Cb.MiniTweet ();
  t1.source_tweet.author = Cb.UserIdentity ();
  t1.source_tweet.author.id = 11;
  t1.retweeted_tweet = Cb.MiniTweet ();
  t1.retweeted_tweet.id = 100;
  t1.retweeted_tweet.author = Cb.UserIdentity ();
  t1.retweeted_tweet.author.id = 111;

  tm.add (t1);
  assert (tm.get_n_items () == 1);
  assert (tm.greatest_id == t1.id);
  assert (tm.lowest_id == t1.id);

  tm.toggle_flag_on_retweet (11, Cb.TweetState.HIDDEN_FILTERED, true);
  assert (tm.get_n_items () == 0);

  tm.toggle_flag_on_retweet (11, Cb.TweetState.HIDDEN_FILTERED, false);
  assert (tm.get_n_items () == 1);


  var t2 = new Cb.Tweet ();
  t2.id = 20;
  t2.source_tweet = Cb.MiniTweet ();
  t2.source_tweet.author = Cb.UserIdentity ();
  t2.source_tweet.author.id = 11;

  tm.add (t2);
  assert (tm.get_n_items () == 2);
  assert (tm.greatest_id == t2.id);
  assert (tm.lowest_id == t1.id);

  tm.toggle_flag_on_tweet (11, Cb.TweetState.HIDDEN_FILTERED, true);
  assert (tm.get_n_items () == 1);
  tm.toggle_flag_on_retweet (11, Cb.TweetState.HIDDEN_FILTERED, true);
  assert (tm.get_n_items () == 0);

  tm.toggle_flag_on_retweet (11, Cb.TweetState.HIDDEN_FILTERED, false);
  assert (tm.get_n_items () == 1);
  tm.toggle_flag_on_tweet (11, Cb.TweetState.HIDDEN_FILTERED, false);
  assert (tm.get_n_items () == 2);
}

void tweet_count2 () {
  var tm = new TweetModel ();

  for (int i = 1;  i <= 20; i ++) {
    var t1 = new Cb.Tweet ();
    t1.id = i * 10;
    t1.source_tweet = Cb.MiniTweet ();
    t1.source_tweet.author = Cb.UserIdentity ();
    t1.source_tweet.author.id = 1337;
    t1.retweeted_tweet = Cb.MiniTweet ();
    t1.retweeted_tweet.id = i * 100;
    t1.retweeted_tweet.author = Cb.UserIdentity ();
    t1.retweeted_tweet.author.id = 999;//i * 100 + 1;

    tm.add (t1);
  }

  assert (tm.get_n_items () == 20);

  tm.toggle_flag_on_retweet (1337, Cb.TweetState.HIDDEN_RETWEETER_MUTED, true);
  assert (tm.get_n_items () == 0);

  tm.toggle_flag_on_retweet (1337, Cb.TweetState.HIDDEN_RETWEETER_MUTED, false);
  assert (tm.get_n_items () == 20);

  tm.toggle_flag_on_tweet (999, Cb.TweetState.HIDDEN_RETWEETER_MUTED, true);
  message ("%u", tm.get_n_items ());
  assert (tm.get_n_items () == 0);

  tm.toggle_flag_on_tweet (999, Cb.TweetState.HIDDEN_RETWEETER_MUTED, false);
  message ("%u", tm.get_n_items ());
  assert (tm.get_n_items () == 20);
}

void hidden_max_id () {
  var tm = new TweetModel ();
  /* TODO: Hidden tweets has to be removed since tweet with lower ID gets remoevd from the main array */

  var t1 = new Cb.Tweet ();
  t1.id = 1;
  tm.add (t1); // Visible

  var t2 = new Cb.Tweet ();
  t2.id = 10;
  tm.add (t2);

  var t3 = new Cb.Tweet ();
  t3.id = 20;
  t3.set_flag (Cb.TweetState.HIDDEN_FORCE);
  tm.add (t3);

  var t4 = new Cb.Tweet ();
  t4.id = 5;
  t4.set_flag (Cb.TweetState.HIDDEN_FORCE);
  tm.add (t4);

  assert (tm.get_n_items () == 2); // Only 2 visible tweets
  assert (tm.hidden_tweets.length == 2);

  tm.remove_tweet (t2);
  /* t2 has an ID lower than ONE of the hidden tweets, so t3 should be removed from the model */
  assert (tm.get_n_items () == 1);
  assert (tm.hidden_tweets.length == 1);

  tm.remove_tweet (t1);
  assert (tm.get_n_items () == 0);
  assert (tm.hidden_tweets.length == 0);
}

void hidden_remove_last_n_visible () {
  var tm = new TweetModel ();

  for (int i = 0; i < 20; i ++) {
    var t = new Cb.Tweet();
    t.id = 10 + (i * 2); // Only even ids
    tm.add (t);
  }

  var t1 = new Cb.Tweet ();
  t1.id = 15;
  t1.set_flag (Cb.TweetState.HIDDEN_UNFOLLOWED);
  tm.add (t1);

  var t2 = new Cb.Tweet ();
  t2.id = 21;
  t2.set_flag (Cb.TweetState.HIDDEN_AUTHOR_MUTED);
  tm.add (t2);

  assert (tm.get_n_items () == 20);
  assert (tm.hidden_tweets.length == 2);

  tm.remove_last_n_visible (20);
  assert (tm.get_n_items () == 0);
  assert (tm.hidden_tweets.length == 0);
}

void empty_hidden_tweets () {
  int n = 100;
  var tm = new TweetModel ();
  for (int i = 1; i <= n; i += 2) {
    var t1 = new Cb.Tweet ();
    t1.id = i + 1;
    tm.add (t1);

    var t2 = new Cb.Tweet ();
    t2.id = i;
    t2.set_flag (Cb.TweetState.HIDDEN_RT_BY_FOLLOWEE);
    tm.add (t2);

    tm.remove_tweet (t1);
  }

  message ("%u", tm.get_n_items ());
  assert (tm.get_n_items () == 0);
  message ("%u", tm.hidden_tweets.length);
  assert (tm.hidden_tweets.length == 0);
}

void muting () {
  var tm = new TweetModel ();
  var t = new Cb.Tweet();
  t.id = 1337;
  t.set_flag (Cb.TweetState.HIDDEN_AUTHOR_MUTED);

  tm.add (t);
  assert (tm.get_n_items () == 0);
  assert (tm.hidden_tweets.length == 1);

  tm.unset_tweet_flag (t, Cb.TweetState.HIDDEN_AUTHOR_MUTED);
  assert (tm.get_n_items () == 1);
  assert (tm.hidden_tweets.length == 0);

  tm.set_tweet_flag (t, Cb.TweetState.HIDDEN_RETWEETER_MUTED);
  assert (tm.get_n_items () == 0);
  assert (tm.hidden_tweets.length == 1);

  tm.unset_tweet_flag (t, Cb.TweetState.HIDDEN_RETWEETER_MUTED);
  assert (tm.get_n_items () == 1);
  assert (tm.hidden_tweets.length == 0);

  tm.remove_tweet (t);
  assert (tm.get_n_items () == 0);
  assert (tm.hidden_tweets.length == 0);
}

int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/tweetmodel/basic-tweet-order", basic_tweet_order);
  GLib.Test.add_func ("/tweetmodel/tweet-removal", tweet_removal);
  GLib.Test.add_func ("/tweetmodel/clear", clear);
  GLib.Test.add_func ("/tweetmodel/clear2", clear2);
  GLib.Test.add_func ("/tweetmodel/remove", remove_tweet);
  GLib.Test.add_func ("/tweetmodel/remove-hidden", remove_hidden);
  GLib.Test.add_func ("/tweetmodel/remove-own-retweet", remove_own_retweet);
  GLib.Test.add_func ("/tweetmodel/hide-rt", hide_rt);
  GLib.Test.add_func ("/tweetmodel/get-from-id", get_from_id);
  GLib.Test.add_func ("/tweetmodel/min-max-id", min_max_id);
  GLib.Test.add_func ("/tweetmodel/sorting", sorting);
  GLib.Test.add_func ("/tweetmodel/min-max-remove", min_max_remove);
  GLib.Test.add_func ("/tweetmodel/tweet-count", tweet_count);
  GLib.Test.add_func ("/tweetmodel/tweet-count2", tweet_count2);
  GLib.Test.add_func ("/tweetmodel/hidden-max-id", hidden_max_id);
  GLib.Test.add_func ("/tweetmodel/empty-hidden-tweets", empty_hidden_tweets);
  GLib.Test.add_func ("/tweetmodel/hidden-remove-last-n-visible", hidden_remove_last_n_visible);
  GLib.Test.add_func ("/tweetmodel/muting", muting);

  return GLib.Test.run ();
}
