BEGIN;

CREATE TABLE IF NOT EXISTS app.notifications (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,   -- receiver
  actor_id uuid NULL REFERENCES app.users(id) ON DELETE SET NULL,     -- who caused it

  type text NOT NULL
    CHECK (type IN ('like', 'comment', 'follow', 'follow_request')),

  post_id bigint NULL REFERENCES app.posts(id) ON DELETE CASCADE,
  comment_id bigint NULL REFERENCES app.comments(id) ON DELETE CASCADE,
  follow_request_id bigint NULL REFERENCES app.follow_requests(id) ON DELETE CASCADE,

  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMIT;
