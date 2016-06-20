#ifndef __TYPES_H
#define __TYPES_H

#include <glib-object.h>
#include <json-glib/json-glib.h>
#include "Media.h"

struct _CbUserIdentity
{
  gint64  id;
  char   *screen_name;
  char   *user_name;
};
typedef struct _CbUserIdentity CbUserIdentity;
void cb_user_identity_free (CbUserIdentity *id);
void cb_user_identity_copy (CbUserIdentity *id, CbUserIdentity *id2);

void cb_user_identity_parse (CbUserIdentity *id, JsonObject *user_obj);

struct _CbTextEntity
{
  guint  from;
  guint  to;
  guint  info : 1;
  char  *display_text;
  char  *tooltip_text;
  char  *target;
};
typedef struct _CbTextEntity CbTextEntity;
void cb_text_entity_free (CbTextEntity *e);
void cb_text_entity_copy (CbTextEntity *e1, CbTextEntity *e2);

struct _CbMiniTweet
{
  gint64 id;
  gint64 created_at;
  CbUserIdentity author;
  char *text;
  CbTextEntity *entities;
  guint n_entities;
  CbMedia **medias;
  guint n_medias;
};
typedef struct _CbMiniTweet CbMiniTweet;
void cb_mini_tweet_free (CbMiniTweet *tweet);
void cb_mini_tweet_copy (CbMiniTweet *t1, CbMiniTweet *t2);
void cb_mini_tweet_init (CbMiniTweet *t);
void cb_mini_tweet_parse (CbMiniTweet *t, JsonObject *obj);
void cb_mini_tweet_parse_entities (CbMiniTweet *t, JsonObject *obj);

char *escape_ampersand (const char *in);

#endif
