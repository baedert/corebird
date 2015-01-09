



void set () {
  Account account = new Account (1337, "Name", "Screen Name");
  Json.Array friends = new Json.Array ();
  for (int i = 10; i <= 17; i ++) {
    friends.add_int_element (i);
  }

  account.set_friends (friends);

  for (int i = 10; i <= 17; i ++) {
    assert (account.follows_id (i));
  }

}


void add () {
  Account account = new Account (1337, "Name", "Screen Name");
  Json.Array friends = new Json.Array ();
  for (int i = 10; i <= 17; i ++) {
    friends.add_int_element (i);
  }

  account.set_friends (friends);

  account.follow_id (1337);

  assert (account.follows_id (1337));

  for (int i = 10; i <= 17; i ++) {
    assert (account.follows_id (i));
  }
}

void _remove () {
  Account account = new Account (1337, "Name", "Screen Name");
  Json.Array friends = new Json.Array ();
  for (int i = 10; i <= 17; i ++) {
    friends.add_int_element (i);
  }

  account.set_friends (friends);

  account.unfollow_id (10);
  account.unfollow_id (11);
  account.unfollow_id (12);

  for (int i = 13; i <= 17; i ++) {
    assert (account.follows_id (i));
  }

  assert (!account.follows_id (10));
  assert (!account.follows_id (11));
  assert (!account.follows_id (12));


  account.unfollow_id (17);
  assert (!account.follows_id (17));

  account.unfollow_id (17);
  assert (!account.follows_id (17));


}


int main (string[] args) {
  GLib.Test.init (ref args);
  Dirs.create_dirs ();
  GLib.Test.add_func ("/friends/set", set);
  GLib.Test.add_func ("/friends/add", add);
  GLib.Test.add_func ("/friends/remove", _remove);

  return GLib.Test.run ();
}
