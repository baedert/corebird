void simple () {
  var model = new Cb.UserCompletionModel ();

  assert (model.get_n_items () == 0);
  model.clear ();
  assert (model.get_n_items () == 0);
}

void add_infos () {
  var model = new Cb.UserCompletionModel ();

  var infos = new Cb.UserInfo[3];
  infos[0].user_id = 1;
  infos[0].screen_name = "a";
  infos[0].user_name = "aa";

  infos[1].user_id = 2;
  infos[1].screen_name = "b";
  infos[1].user_name = "bb";

  infos[2].user_id = 3;
  infos[2].screen_name = "c";
  infos[2].user_name = "cc";

  model.insert_infos (infos);

  assert (model.get_n_items () == 3);

  Cb.UserIdentity *id = (Cb.UserIdentity*)model.get_item (0);
  assert (id->id == 1);
  assert (id->screen_name == "a");
  assert (id->user_name == "aa");

  id = (Cb.UserIdentity*)model.get_item (1);
  assert (id->id == 2);
  assert (id->screen_name == "b");
  assert (id->user_name == "bb");

  id = (Cb.UserIdentity*)model.get_item (2);
  assert (id->id == 3);
  assert (id->screen_name == "c");
  assert (id->user_name == "cc");

  // test clear
  model.clear ();
  assert (model.get_n_items () == 0);
}

void add_items () {
  var model = new Cb.UserCompletionModel ();

  var ids = new Cb.UserIdentity[3];
  ids[0].id = 1;
  ids[0].screen_name = "a";
  ids[0].user_name = "aa";

  ids[1].id = 2;
  ids[1].screen_name = "b";
  ids[1].user_name = "bb";

  ids[2].id = 3;
  ids[2].screen_name = "c";
  ids[2].user_name = "cc";

  model.insert_items (ids);
  assert (model.get_n_items () == 3);

  Cb.UserIdentity *id = (Cb.UserIdentity*)model.get_item (0);
  assert (id->id == 1);
  assert (id->screen_name == "a");
  assert (id->user_name == "aa");

  id = (Cb.UserIdentity*)model.get_item (1);
  assert (id->id == 2);
  assert (id->screen_name == "b");
  assert (id->user_name == "bb");

  id = (Cb.UserIdentity*)model.get_item (2);
  assert (id->id == 3);
  assert (id->screen_name == "c");
  assert (id->user_name == "cc");

  // test clear
  model.clear ();
  assert (model.get_n_items () == 0);
}

void id_duplicates () {
  var model = new Cb.UserCompletionModel ();

  var ids = new Cb.UserIdentity[3];
  ids[0].id = 1;
  ids[0].screen_name = "a";
  ids[0].user_name = "aa";

  ids[1].id = 2;
  ids[1].screen_name = "b";
  ids[1].user_name = "bb";

  ids[2].id = 3;
  ids[2].screen_name = "c";
  ids[2].user_name = "cc";

  model.insert_items (ids);
  assert (model.get_n_items () == 3);

  model.insert_items (ids);
  // Still.
  assert (model.get_n_items () == 3);
}

void info_duplicates () {
  var model = new Cb.UserCompletionModel ();

  var infos = new Cb.UserInfo[3];
  infos[0].user_id = 1;
  infos[0].screen_name = "a";
  infos[0].user_name = "aa";

  infos[1].user_id = 2;
  infos[1].screen_name = "b";
  infos[1].user_name = "bb";

  infos[2].user_id = 3;
  infos[2].screen_name = "c";
  infos[2].user_name = "cc";

  model.insert_infos (infos);
  assert (model.get_n_items () == 3);

  model.insert_infos (infos);
  assert (model.get_n_items () == 3);
}

int main (string[] args) {
  GLib.Test.init (ref args);
  GLib.Test.add_func ("/usercompletionmodel/simple", simple);
  GLib.Test.add_func ("/usercompletionmodel/add-infos", add_infos);
  GLib.Test.add_func ("/usercompletionmodel/add-items", add_items);
  GLib.Test.add_func ("/usercompletionmodel/id-duplicates", id_duplicates);
  GLib.Test.add_func ("/usercompletionmodel/info-duplicates", info_duplicates);

  return GLib.Test.run ();
}
