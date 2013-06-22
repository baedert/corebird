

PRAGMA user_version = 1;

-- SQL schema for an account database

CREATE TABLE IF NOT EXISTS `info`(
  id NUMERIC(19,0) PRIMARY KEY,
  screen_name VARCHAR(30),
  name VARCHAR(30)
);
