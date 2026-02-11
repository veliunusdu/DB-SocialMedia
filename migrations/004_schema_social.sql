BEGIN;

-- FOLLOWS (confirmed follow)
CREATE TABLE IF NOT EXISTS app.follows (
  follower_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  followed_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, followed_id),
  CONSTRAINT follows_not_self CHECK (follower_id <> followed_id)
);

-- FOLLOW REQUESTS (for private accounts)
CREATE TABLE IF NOT EXISTS app.follow_requests (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  requester_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  target_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,

  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT follow_requests_not_self CHECK (requester_id <> target_id)
);

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS app.notifications (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,   -- receiver
  actor_id uuid NULL REFERENCES app.users(id) ON DELETE SET NULL,     -- who caused it

  type text NOT NULL
    CHECK (type IN ('like', 'comment', 'follow', 'follow_request', 'message')),

  post_id bigint NULL REFERENCES app.posts(id) ON DELETE CASCADE,
  comment_id bigint NULL REFERENCES app.comments(id) ON DELETE CASCADE,
  follow_request_id bigint NULL REFERENCES app.follow_requests(id) ON DELETE CASCADE,

  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMIT;
