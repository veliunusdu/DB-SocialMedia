BEGIN;

-- POSTS
CREATE TABLE IF NOT EXISTS app.posts (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,

  caption text,
  visibility text NOT NULL DEFAULT 'public'
    CHECK (visibility IN ('public', 'followers')),

  likes_count int NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  comments_count int NOT NULL DEFAULT 0 CHECK (comments_count >= 0),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- updated_at trigger
DROP TRIGGER IF EXISTS trg_posts_set_updated_at ON app.posts;
CREATE TRIGGER trg_posts_set_updated_at
BEFORE UPDATE ON app.posts
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();


-- POST MEDIA (carousel)
CREATE TABLE IF NOT EXISTS app.post_media (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  post_id bigint NOT NULL REFERENCES app.posts(id) ON DELETE CASCADE,

  media_type text NOT NULL CHECK (media_type IN ('image', 'video')),
  url text NOT NULL,
  position int NOT NULL CHECK (position >= 1),

  created_at timestamptz NOT NULL DEFAULT now()
);

-- ensure one position per post (1..n)
CREATE UNIQUE INDEX IF NOT EXISTS ux_post_media_position
ON app.post_media (post_id, position);


-- LIKES (many-to-many)
CREATE TABLE IF NOT EXISTS app.post_likes (
  post_id bigint NOT NULL REFERENCES app.posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, user_id)
);


-- COMMENTS (supports replies via parent_comment_id)
CREATE TABLE IF NOT EXISTS app.comments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  post_id bigint NOT NULL REFERENCES app.posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,

  parent_comment_id bigint NULL REFERENCES app.comments(id) ON DELETE CASCADE,
  body text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_comments_set_updated_at ON app.comments;
CREATE TRIGGER trg_comments_set_updated_at
BEFORE UPDATE ON app.comments
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

COMMIT;
