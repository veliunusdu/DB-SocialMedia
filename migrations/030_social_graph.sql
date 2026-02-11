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

DROP TRIGGER IF EXISTS trg_follow_requests_set_updated_at ON app.follow_requests;
CREATE TRIGGER trg_follow_requests_set_updated_at
BEFORE UPDATE ON app.follow_requests
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

COMMIT;
