BEGIN;

-- Fast: who I follow / who follows me
CREATE INDEX IF NOT EXISTS ix_follows_followed
ON app.follows (followed_id, created_at DESC);

CREATE INDEX IF NOT EXISTS ix_follows_follower
ON app.follows (follower_id, created_at DESC);

-- Allow only ONE pending request per pair (partial unique index = portfolio flex)
CREATE UNIQUE INDEX IF NOT EXISTS ux_follow_requests_pending
ON app.follow_requests (requester_id, target_id)
WHERE status = 'pending';

-- Quick queries for requests
CREATE INDEX IF NOT EXISTS ix_follow_requests_target_status
ON app.follow_requests (target_id, status, created_at DESC);

-- Notifications: unread list fast
CREATE INDEX IF NOT EXISTS ix_notifications_user_created_at
ON app.notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS ix_notifications_unread
ON app.notifications (user_id, created_at DESC)
WHERE is_read = false;

COMMIT;
