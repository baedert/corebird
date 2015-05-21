PRAGMA user_version = 2;

CREATE TABLE IF NOT EXISTS `drafts`(
  int ID(5),
  text VARCHAR(255),
  media TEXT -- SOME_SEPARATOR separated list of attached media
);
