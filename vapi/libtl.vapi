namespace Tl {
  [CCode (cprefix = "TL_ENT_", cheader_filename = "libtl/libtweetlength.h")]
  enum EntityType {
    TEXT = 1,
    HASHTAG,
    LINK,
    MENTION,
    WHITESPACE
  }

  [CCode (cprefix = "TlEntity_", lower_case_cprefix = "tl_entity_", cheader_filename = "libtl/libtweetlength.h")]
  struct Entity {
    EntityType type;
    size_t start_character_index;
    size_t length_in_characters;
  }


  [CCode (cprefix = "tl_", lower_case_cprefix = "tl_", cheader_filename = "libtl/libtweetlength.h")]
  size_t count_characters (string input);

  [CCode (cprefix = "tl_", lower_case_cprefix = "tl_", cheader_filename = "libtl/libtweetlength.h",
          array_length_pos = 1)]
  Entity[] extract_entities (string input, out size_t text_length);
}
