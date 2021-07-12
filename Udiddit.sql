--PART II
CREATE TABLE "users" (
id SERIAL PRIMARY KEY
,user_name VARCHAR(25) UNIQUE NOT NULL
,last_login TIMESTAMP
,CONSTRAINT "user_name_not_empty" CHECK (LENGTH(TRIM("user_name")) > 0)
);

CREATE INDEX "user_name_index" ON "users" ("user_name");

CREATE TABLE "topics" (
  id SERIAL PRIMARY KEY
  ,topic_name VARCHAR(30) UNIQUE NOT NULL
  ,description VARCHAR(500) DEFAULT NULL
  ,CONSTRAINT "topic_not_empty" CHECK (LENGTH(TRIM("topic_name")) > 0)
  );

CREATE INDEX ON "topics" ("topic_name" VARCHAR_PATTERN_OPS);

CREATE TABLE "posts" (
  id SERIAL PRIMARY KEY
  ,title VARCHAR(100) NOT NULL
  ,url VARCHAR(500)
  ,created_on TIMESTAMP
  ,post VARCHAR(1000) DEFAULT NULL
  ,topic_id INTEGER NOT NULL REFERENCES "topics" ON DELETE CASCADE
  ,user_id INTEGER NOT NULL REFERENCES "users" ON DELETE SET NULL
  ,CONSTRAINT "url_or_text" CHECK (
  (
  "url" IS NULL
  AND "post" IS NOT NULL
  )
  OR (
  "url" IS NOT NULL
  AND "post" IS NULL
  )
  )
  );

CREATE INDEX ON "posts" ("url" VARCHAR_PATTERN_OPS);

CREATE TABLE "comments" (
    id SERIAL PRIMARY KEY
    ,user_id INTEGER NOT NULL REFERENCES "users" ON DELETE SET NULL
    ,post_id INTEGER NOT NULL REFERENCES "posts" ON DELETE CASCADE
    ,comment VARCHAR(5000) NOT NULL
    ,created_on TIMESTAMP
    ,parent_id INTEGER REFERENCES "comments" ON DELETE CASCADE CONSTRAINT "comment_not_empty" CHECK (LENGTH(TRIM("comment")) > 0)
    );

CREATE TABLE "votes" (
    vote SMALLINT NOT NULL CHECK (
    "vote" = 1
    OR "vote" = - 1
    )
    ,user_id INTEGER NOT NULL REFERENCES "users" ON DELETE SET NULL
    ,post_id INTEGER NOT NULL REFERENCES "posts" ON DELETE CASCADE
    ,CONSTRAINT "unique_user_votes" PRIMARY KEY (
    post_id
    ,user_id
    )
    );


--PART III
INSERT INTO users ("user_name") (
SELECT DISTINCT regexp_split_to_table(upvotes, ',') FROM bad_posts
UNION
SELECT DISTINCT regexp_split_to_table(downvotes, ',') FROM bad_posts
UNION
SELECT DISTINCT “username” FROM bad_posts
UNION
SELECT DISTINCT “username” FROM bad_comments
);

INSERT INTO topics ("topic_name")
SELECT DISTINCT topic
FROM bad_posts;


INSERT INTO posts (
"user_id"
,"title"
,"url"
,"post"
,"topic_id"
)
SELECT users.id
,LEFT(bp.title, 100)
,bp.url
,bp.text_content
,topics.id
FROM bad_posts bp
JOIN users ON users.user_name = bp.username
JOIN topics ON topics.topic_name = bp.topic;


INSERT INTO comments (
user_id
,post_id
,comment
)
SELECT users.id
,posts.id
,bad_comments.text_content
FROM bad_comments
JOIN posts ON posts.id = bad_comments.post_id
JOIN users ON bad_comments.username = users.user_name;


INSERT INTO votes (
"post_id"
,"user_id"
,"vote"
)
SELECT t1.id
,users.id
,1 AS upvote
FROM (
SELECT id
,REGEXP_SPLIT_TO_TABLE(upvotes, ',') AS upvote_users
FROM bad_posts
) t1
JOIN users ON users.user_name = t1.upvote_users;

INSERT INTO votes (
"post_id"
,"user_id"
,"vote"
)
SELECT t1.id
,users.id
,- 1 AS downvote
FROM (
SELECT id
,REGEXP_SPLIT_TO_TABLE(downvotes, ',') AS downvote_users
FROM bad_posts
) t1
JOIN users ON users.user_name = t1.downvote_users;
