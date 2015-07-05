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

public struct TextEntity {
  uint from;
  uint to;
  string display_text;
  string tooltip_text;
  string? target; // If target is null, use display_text as target!
  uint info;
}

//void print_e (TextEntity ent) {
  //message ("Entity (range = %u..%u, display_text = '%s', target = '%s'",
           //ent.from, ent.to, ent.display_text, ent.target);
//}

public enum TransformFlags {
  REMOVE_MEDIA_LINKS       = 1 << 0,
  REMOVE_TRAILING_HASHTAGS = 1 << 1,
  EXPAND_LINKS             = 1 << 2
}

namespace TextTransform {
  private static const uint TRAILING = 1 << 0;

  private bool is_media_url (string? url,
                             string  display_text,
                             uint    media_count)
  {
    return (InlineMediaDownloader.is_media_candidate (url ?? display_text) &&
            media_count == 1) || display_text.has_prefix ("pic.twitter.com/");
  }

  private bool is_hashtag (string entity)
  {
    return entity[0] == '#';
  }

  private bool is_whitespace (string s)
  {
    unichar c;
    for (int i = 0; s.get_next_char (ref i, out c);) {
      if (c.isgraph ())
        return false;
    }
    return true;
  }

  public string transform_tweet (MiniTweet tweet, TransformFlags flags)
  {
    return transform (tweet.text, tweet.entities, flags, tweet.medias.length);
  }


  // XXX We could probably do this a bit faster and simpler (and in one step!)
  //     if we just built the new string from end to start.
  public string transform (string         text,
                           TextEntity[]   entities,
                           TransformFlags flags,
                           uint           media_count = 0)
  {
    StringBuilder builder = new StringBuilder ();
    uint last_end = 0;

    uint cur_end = text.char_count ();
    for (int i = entities.length - 1; i >= 0; i --) {
      /* Check that only whitespace is between the two entities */
      string btw = text.substring (text.index_of_nth_char (entities[i].to),
                                   text.index_of_nth_char (cur_end) -
                                   text.index_of_nth_char (entities[i].to));

      if (!is_whitespace (btw) && btw.length > 0) {
        break;
      } else
        cur_end = entities[i].to;

      if (entities[i].to == cur_end && is_hashtag (entities[i].display_text)) {
        entities[i].info |= TRAILING;
        cur_end = entities[i].from;
      } else break;
    }


    foreach (TextEntity entity in entities) {
      /* Append part before this entity */
      builder.append (text.substring (text.index_of_nth_char (last_end),
                                      text.index_of_nth_char (entity.from) -
                                      text.index_of_nth_char (last_end)));

      if (TransformFlags.REMOVE_TRAILING_HASHTAGS in flags &&
          (entity.info & TRAILING) > 0 &&
          is_hashtag (entity.display_text)) {
        last_end = entity.to;
        continue;
      }

      /* Skip the entire entity if we should remove media links AND
         it is a media link. */

      if (TransformFlags.REMOVE_MEDIA_LINKS in flags &&
          is_media_url (entity.target, entity.display_text, media_count)) {
        last_end = entity.to;
        continue;
      }

      if (TransformFlags.EXPAND_LINKS in flags) {
        if (entity.display_text[0] == '@')
          builder.append (entity.display_text);
        else
          builder.append (entity.target ?? entity.display_text);
      } else {
        /* Append start of link + entity target */
        builder.append ("<span underline=\"none\"><a href=\"")
               .append (entity.target ?? entity.display_text)
               .append ("\"");

        /* Only set the tooltip if there actually is one */
        if (entity.tooltip_text != null) {
          builder.append (" title=\"")
                 .append (entity.tooltip_text.replace ("&", "&amp;"))
                 .append ("\"");
        }

        builder.append (">");
        builder.append (entity.display_text.replace ("&", "&amp;"));


        builder.append ("</a></span>");

      }

      last_end = entity.to;
    }

    /* Append last part of the source string */
    builder.append (text.substring (text.index_of_nth_char (last_end)));

    /* Replace all & with &amp; */
    return builder.str;
  }

}
