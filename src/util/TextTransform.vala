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
}

public enum TransformFlags {
  REMOVE_MEDIA_LINKS       = 1 << 0,
  REMOVE_TRAILING_HASHTAGS = 1 << 1,
  EXPAND_LINKS             = 1 << 2,
  TEXTIFY_HASHTAGS         = 1 << 3
}

namespace TextTransform {

  private bool is_media_url (string url,
                             uint   media_count)
  {
    return (InlineMediaDownloader.is_media_candidate (url) && media_count == 1) ||
           url.has_prefix ("pic.twitter.com/");
  }

  private bool is_hashtag (string entity)
  {
    return entity[0] == '#';
  }

  public string transform (string                  text,
                           GLib.SList<TextEntity?> entities,
                           TransformFlags          flags,
                           uint                    media_count = 0)
  {
    StringBuilder builder = new StringBuilder ();
    uint last_end = 0;

    foreach (TextEntity entity in entities) {
      /* Append part before this entity */
      builder.append (text.substring (text.index_of_nth_char (last_end),
                                      text.index_of_nth_char (entity.from) -
                                      text.index_of_nth_char (last_end)));

      /* Skip the entire entity if we should remove media links AND
         it is a media link. */
      if (!(TransformFlags.REMOVE_MEDIA_LINKS in flags) ||
          !is_media_url (entity.display_text ?? entity.target, media_count)) {

        if (TransformFlags.EXPAND_LINKS in flags) {
          builder.append (entity.target ?? entity.display_text);
        } else {
          bool linkify = !(TransformFlags.TEXTIFY_HASHTAGS in flags);

          /* Append start of link + entity target */
          if (linkify) {
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
          }


          if (TransformFlags.TEXTIFY_HASHTAGS in flags &&
              is_hashtag (entity.display_text))
            builder.append (entity.display_text.substring (1));
          else
            builder.append (entity.display_text);


          if (linkify) {
            builder.append ("</a></span>");
          }

        }

      }
      last_end = entity.to;
    }

    /* Append last part of the source string */
    builder.append (text.substring (text.index_of_nth_char (last_end)));

    /* Replace all & with &amp; */
    return builder.str.replace ("&", "&amp;");
  }

}
