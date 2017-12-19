namespace Tl {
  [CCode (cprefix = "TL_ENT_", cheader_filename = "libtweetlength.h")]
  enum EntityType {
    TEXT = 1,
    HASHTAG,
    LINK,
    MENTION,
    WHITESPACE
  }

  [CCode (cprefix = "TlEntity_", lower_case_cprefix = "tl_entity_", cheader_filename = "libtweetlength.h")]
  struct Entity {
    EntityType type;
    string *start;
    size_t start_character_index;
    size_t length_in_characters;
    size_t length_in_bytes;
  }


  [CCode (cprefix = "tl_", lower_case_cprefix = "tl_", cheader_filename = "libtweetlength.h")]
  size_t count_characters (string input);

  [CCode (cprefix = "tl_", lower_case_cprefix = "tl_", cheader_filename = "libtweetlength.h",
          array_length_pos = 1)]
  Entity[]? extract_entities (string input, out size_t text_length);

  [CCode (cprefix = "tl_", lower_case_cprefix = "tl_", cheader_filename = "libtweetlength.h",
          array_length_pos = 1)]
  Entity[]? extract_entities_and_text (string input, out size_t text_length);
}
