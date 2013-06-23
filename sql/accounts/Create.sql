

PRAGMA user_version = 1;

-- SQL schema for an account database
CREATE TABLE IF NOT EXISTS `common`(
  token VARCHAR(100),
  token_secret VARCHAR(100)
);


CREATE TABLE IF NOT EXISTS `info`(
  id NUMERIC(19,0) PRIMARY KEY,
  screen_name VARCHAR(30),
  name VARCHAR(30)
);
