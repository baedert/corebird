CREATE TABLE IF NOT EXISTS `common`(
				token VARCHAR(255),
				token_secret VARCHAR(255),
				update_config INTEGER(11),
				max_media_per_upload INTEGER(2),
				photo_size_limit INTEGER(10),
				short_url_length INTEGER(3),
				short_url_length_https INTEGER(3),
				characters_reserved_per_media INTEGER(3)
);

CREATE TABLE IF NOT EXISTS `cache`(
                id NUMERIC(19,0) PRIMARY KEY,
                rt_id NUMERIC(19,0),
                text VARCHAR(200),
				user_id NUMERIC(19,0),
				user_name VARCHAR(100),
				screen_name VARCHAR(40),
				is_retweet BOOL,
			    retweeted_by VARCHAR(100),
			    retweeted BOOL,
			    favorited BOOL,
			    created_at INTEGER(19,0),
			    rt_created_at INTEGER(19,0),
			    avatar_url VARCHAR(255),
			    avatar_name VARCHAR(50),
			    retweets INTEGER(5),
			    favorites INTEGER(5),
			    type INTEGER(1),
			    reply_id NUMERIC(19,0),
			    media VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS `people`(
				id NUMERIC(19,0),
			    name VARCHAR(30),
			    screen_name VARCHAR(30),
			    avatar_url VARCHAR(255),
			    avatar_name VARCHAR(70)
);

CREATE TABLE IF NOT EXISTS `user`(
                id NUMERIC(19,0),
			    name VARCHAR(40),
			    screen_name VARCHAR(40),
			    avatar_name VARCHAR(40),
			    avatar_url VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS `profiles`(
                id NUMERIC(19,0),
			    name VARCHAR(40) PRIMARY KEY,
			    screen_name VARCHAR(40),
			    tweets INTEGER(11),
			    followers INTEGER(11),
			    following INTEGER(11),
			    description VARCHAR(160),
			    avatar_name VARCHAR(100),
			    banner_url VARCHAR(255),
			    url VARCHAR(150),
			    location VARCHAR(100),
			    is_following BOOL
);
