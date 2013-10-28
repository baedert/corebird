

PRAGMA user_version = 2;

CREATE TABLE IF NOT EXISTS `user_cache`(
  id NUMERIC(19,0) PRIMARY KEY,
  screen_name VARCHAR(30),
  user_name VARCHAR (40),
  score INTEGER (11)
);
