
# Implementation Details

## SQL Tables

### common
`token`: The application token of Corebird<br />
`token_secret` The token secred received from Twitter when first settings up Corebird. Store this somewhere else?<br />
`update_config`: timestamp of the last config update. RENAME!<br />
`max_media_per_upload`: Self explanatory. see Twitter. <br />
`photo_size_limit`:Self explanatory. see Twitter. <br />
`short_url_length`:Self explanatory. see Twitter. <br />
`short_url_length_https`:Self explanatory. see Twitter. <br />
`characters_reserved_per_media`:Self explanatory. see Twitter. <br />

### cache
Caches all types of tweets.
Columns:
`id`: The id of this tweet(received from Twitter)<br />
`rt_id`: Currently unused. Remove? <br />
`text`: The text of this tweet, in raw form, like received from Twitter. <br />
`user_id`: The id of the user who created this tweet.(If this is a retweet, it's the id of the user who retweeted the original tweet).<br />
`user_name`: The name of the user who created this tweet. RT-case like above.<br />
`screen_name`: The screen name of the user who created this tweet(@foo)<br />
`time`: Unused. Remove.<br />
`is_retweet`: TRUE if this tweet is a retweet, false otherwise.<br />
`retweeted_by`: The user who retweeted the original tweet.<br />
`retweeted`: TRUE if the user(the one who's using Corebird) retweeted this tweet.<br />
`favorited`: TRUE if the user(the one who's using Corebird) favorited this tweet.<br />
`created_at`: The date+time when this tweet was *originally* created<br />
`avatar_url`: The author's avatar url<br />
`avatar_name`: The author's avatar_name <br />
`retweets`: Number of retweets of this tweet<br />
`favorites`: Number of favorites of this tweet<br />
`added_to_stream`: When this tweet was added to the user's stream.<br />
`type`: The tweet's type. Just do differentiate between tweets, mentions, favorites, ...<br />
