
PRAGMA user_version = 1;

CREATE TABLE IF NOT EXISTS `accounts`(
  id NUMERIC(19,0) PRIMARY KEY,
  screen_name VARCHAR(30),
  name VARCHAR(30),
  avatar_url VARCHAR(255)
);
