
PRAGMA user_version = 1;

CREATE TABLE IF NOT EXISTS `common`(
  token VARCHAR(255),
  token_secret VARCHAR(255),
  update_config INTEGER(11),
  max_media_per_upload INTEGER(2),
  photo_size_limit INTEGER(10),
  short_url_length INTEGER(3),
  short_url_length_https INTEGER(3),
  characters_reserved_per_media INTEGER(3)
);

-- This table caches information about all the accounts
-- the user set up.
-- This is helpful so we don't have to initialize
-- all the databases just because the user wants
-- a list of all his accounts
CREATE TABLE IF NOT EXISTS `accounts`(
  id NUMERIC(19,0) PRIMARY KEY,
  screen_name VARCHAR(30),
  name VARCHAR(30),
  notifications_enabled BOOL,
  avatar_url VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS `user`(
  id NUMERIC(19,0),
  name VARCHAR(40),
  screen_name VARCHAR(40),
  avatar_name VARCHAR(40),
  avatar_url VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS `profiles`(
  id NUMERIC(19,0),
  name VARCHAR(40),
  screen_name VARCHAR(40) PRIMARY KEY,
  tweets INTEGER(11),
  followers INTEGER(11),
  following INTEGER(11),
  description VARCHAR(160),
  avatar_name VARCHAR(100),
  banner_url VARCHAR(255),
  banner_name VARCHAR(255),
  banner_on_disk VARCHAR(255),
  url VARCHAR(150),
  location VARCHAR(100),
  is_following BOOL
);
