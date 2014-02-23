

PRAGMA user_version = 2;

CREATE TABLE IF NOT EXISTS `filters`(
  id INTEGER(3) PRIMARY KEY,
  content VARCHAR(100),
  block_count INTEGER(5)
);
