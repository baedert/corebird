/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

public class SnippetManager : GLib.Object {
  private Gee.HashMap<string, string> snippets = new Gee.HashMap<string, string> ();
  private bool inited = false;

  public delegate void SnippetQueryFunc (string key, string value);


  public SnippetManager () {
  }

  private void load_snippets () {
    Corebird.db.select ("snippets")
               .cols ("id", "key", "value")
               .order ("id")
               .run ((vals) => {
      snippets.set (vals[1], vals[2]);

      return true;
    });

    inited = true;
  }

  public void remove_snippet (string snippet_key) {
    if (!inited) load_snippets ();

    this.snippets.unset (snippet_key);
    string key = snippet_key.replace ("'", "''");
    Corebird.db.exec (@"DELETE FROM `snippets` WHERE `key`='$(key)'");
  }

  public void insert_snippet (string key, string value) {
    if (!inited) load_snippets ();

    if (this.snippets.has_key (key))
      error ("Snippet already exists: %s", key);

    // Insert snippet into db
    Corebird.db.insert ("snippets")
               .val ("key", key)
               .val ("value", value)
               .run ();

    this.snippets.set (key, value);
  }

  public string? get_snippet (string key) {
    if (!inited) load_snippets ();

    return this.snippets.get (key);
  }

  public void query_snippets (SnippetQueryFunc func) {
    if (!inited) load_snippets ();

    foreach (var entry in this.snippets.entries) {
      func (entry.key, entry.value);
    }
  }

  public int n_snippets () {
    if (!inited) load_snippets ();
    return this.snippets.size;
  }

  public void set_snippet (string old_key, string key, string new_value) {
    if (!inited) load_snippets ();

    if (!this.snippets.has_key (old_key)) {
      debug ("Key %s not in hashmap!", key);
      return;
    }

    // Delete the old one, add the new one, update the db
    this.snippets.unset (key);
    this.snippets.set (key, new_value);
    Corebird.db.update ("snippets")
               .val ("key", key)
               .val ("value", new_value)
               .where_eq ("key", old_key)
               .run ();
  }
}
