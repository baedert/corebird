
/// These are the original ids with two zeroes appended!
const int64 RECIPIENT_ID = 11805587900;
const int64 SENDER_ID    = 146929708900;

// Some utils
Json.Object get_dm_object (string json_input) {
  var parser = new Json.Parser ();
  try {
    parser.load_from_data (json_input);
  } catch (GLib.Error e) {
    message ("%s", e.message);
    assert (false);
  }
  var root_node = parser.get_root ();
  var root_object = root_node.get_object ();

  assert (root_node != null);
  assert (root_object != null);

  var dm_object = root_object.get_object_member ("direct_message");
  assert (dm_object != null);

  return dm_object;
}
void clear_account (Account acc) {
  FileUtils.remove (Dirs.config ("accounts/%s.db".printf (acc.id.to_string ())));
}

void simple () {
  var account = new Account (10, "baedert", "BAEDERT");
  var manager = new DMManager.for_account (account);
  var threads_model = manager.get_threads_model ();

  assert (threads_model != null);
  assert (threads_model.get_n_items () == 0);
  assert (manager.empty);
}

void simple_insert () {
  var account = new Account (RECIPIENT_ID, "baedert", "BAEDERT");
  clear_account (account);
  account.init_database ();
  var manager = new DMManager.for_account (account);
  var threads_model = manager.get_threads_model ();

  var dm_obj = get_dm_object (DM_DATA1);
  manager.insert_message (dm_obj);

  // This should create a new thread.
  assert (!manager.empty);
  assert (threads_model.get_n_items () == 1);

  // ...with the correct info
  var thread = threads_model.get_item (0) as DMThread;
  assert (thread != null);
  assert (thread.user.id == SENDER_ID);
  assert (thread.user.user_name == "Hans Wurst");
  assert (thread.user.screen_name == "wurst_hw");
}

void main (string[] args) {
  GLib.Test.init (ref args);

  GLib.Test.add_func ("/dmmanager/simple", simple);
  GLib.Test.add_func ("/dmmanager/simple-insert", simple_insert);

  GLib.Test.run ();
}

// {{{

const string DM_DATA1=  """
{"direct_message":{"id":905788395095457796,"id_str":"905788395095457796","text":"SUP
  FEGET","sender":{"id":11805587900,"id_str":"11805587900","name":"Schupp &
    Wupp","screen_name":"baedert","location":null,"url":"http:\/\/corebird.baedert.org","description":"Corebird
    developer by night, silently judging people on the train by
    day.","protected":false,"followers_count":221,"friends_count":70,"listed_count":4,"created_at":"Sat Feb 27
    13:13:34 +0000
    2010","favourites_count":159,"utc_offset":7200,"time_zone":"Bern","geo_enabled":false,"verified":false,"statuses_count":2142,"lang":"en","contributors_enabled":false,"is_translator":false,"is_translation_enabled":false,"profile_background_color":"C6E2EE","profile_background_image_url":"http:\/\/abs.twimg.com\/images\/themes\/theme2\/bg.gif","profile_background_image_url_https":"https:\/\/abs.twimg.com\/images\/themes\/theme2\/bg.gif","profile_background_tile":false,"profile_image_url":"http:\/\/pbs.twimg.com\/profile_images\/810507927941476352\/cSydClet_normal.jpg","profile_image_url_https":"https:\/\/pbs.twimg.com\/profile_images\/810507927941476352\/cSydClet_normal.jpg","profile_banner_url":"https:\/\/pbs.twimg.com\/profile_banners\/118055879\/1488791887","profile_link_color":"1F98C7","profile_sidebar_border_color":"C6E2EE","profile_sidebar_fill_color":"DAECF4","profile_text_color":"663B12","profile_use_background_image":true,"default_profile":false,"default_profile_image":false,"following":false,"follow_request_sent":false,"notifications":false,"translator_type":"none"},"sender_id":11805587900,"sender_id_str":"11805587900","sender_screen_name":"baedert","recipient":{"id":146929708900,"id_str":"146929708900","name":"Hans Wurst","screen_name":"wurst_hw","location":null,"url":null,"description":null,"protected":false,"followers_count":1,"friends_count":2,"listed_count":0,"created_at":"Thu May 30 08:47:22 +0000 2013","favourites_count":0,"utc_offset":null,"time_zone":null,"geo_enabled":false,"verified":false,"statuses_count":31,"lang":"en","contributors_enabled":false,"is_translator":false,"is_translation_enabled":false,"profile_background_color":"C0DEED","profile_background_image_url":"http:\/\/abs.twimg.com\/images\/themes\/theme1\/bg.png","profile_background_image_url_https":"https:\/\/abs.twimg.com\/images\/themes\/theme1\/bg.png","profile_background_tile":false,"profile_image_url":"http:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_normal.png","profile_image_url_https":"https:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_normal.png","profile_link_color":"1DA1F2","profile_sidebar_border_color":"C0DEED","profile_sidebar_fill_color":"DDEEF6","profile_text_color":"333333","profile_use_background_image":true,"default_profile":true,"default_profile_image":false,"following":false,"follow_request_sent":false,"notifications":false,"translator_type":"none"},"recipient_id":146929708900,"recipient_id_str":"146929708900","recipient_screen_name":"wurst_hw","created_at":"Thu Sep 07 13:42:36 +0000 2017","entities":{"hashtags":[],"symbols":[],"user_mentions":[],"urls":[]}}}""";
// }}}
