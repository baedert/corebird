
PRAGMA user_version = 2;

CREATE TABLE IF NOT EXISTS `snippets`(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key VARCHAR(20),
  value VARCHAR(200)
);

INSERT INTO `snippets` (key, value) VALUES ('dealwithit', '(•_•) ( •_•)>⌐■-■ (⌐■_■)');
INSERT INTO `snippets` (key, value) VALUES ('tableflip', '(╯°□°）╯︵ ┻━┻');

