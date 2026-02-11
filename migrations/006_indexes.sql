BEGIN;

-- ===== USERS & PROFILES =====
CREATE UNIQUE INDEX IF NOT EXISTS ux_users_username_ci
ON app.users (lower(username));

CREATE INDEX IF NOT EXISTS ix_users_created_at
ON app.users (created_at DESC);

CREATE INDEX IF NOT EXISTS ix_profiles_user_id
ON app.profiles (user_id);

-- ===== POSTS =====
CREATE INDEX IF NOT EXISTS ix_posts_user_id
ON app.posts (user_id);

CREATE INDEX IF NOT EXISTS ix_posts_created_at
ON app.posts (created_at DESC);

CREATE INDEX IF NOT EXISTS ix_posts_user_created_at
ON app.posts (user_id, created_at DESC);

-- ===== POST MEDIA =====
CREATE INDEX IF NOT EXISTS ix_post_media_post_id
ON app.post_media (post_id);

-- ===== COMMENTS =====
CREATE INDEX IF NOT EXISTS ix_comments_post_id
ON app.comments (post_id);

CREATE INDEX IF NOT EXISTS ix_comments_user_id
ON app.comments (user_id);

CREATE INDEX IF NOT EXISTS ix_comments_parent_id
ON app.comments (parent_comment_id);

-- ===== LIKES =====
CREATE INDEX IF NOT EXISTS ix_post_likes_post_id
ON app.post_likes (post_id);

CREATE INDEX IF NOT EXISTS ix_post_likes_user_id
ON app.post_likes (user_id);

-- ===== FOLLOWS =====
CREATE INDEX IF NOT EXISTS ix_follows_followed_id
ON app.follows (followed_id);

CREATE INDEX IF NOT EXISTS ix_follows_follower_id
ON app.follows (follower_id);

-- ===== FOLLOW REQUESTS =====
CREATE INDEX IF NOT EXISTS ix_follow_requests_requester
ON app.follow_requests (requester_id);

CREATE INDEX IF NOT EXISTS ix_follow_requests_target
ON app.follow_requests (target_id);

CREATE INDEX IF NOT EXISTS ix_follow_requests_status
ON app.follow_requests (status);

-- ===== NOTIFICATIONS =====
CREATE INDEX IF NOT EXISTS ix_notifications_user_id
ON app.notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS ix_notifications_unread
ON app.notifications (user_id, is_read)
WHERE is_read = false;

-- ===== CONVERSATIONS =====
CREATE INDEX IF NOT EXISTS ix_conversations_created_by
ON app.conversations (created_by);

-- ===== CONVERSATION MEMBERS =====
CREATE INDEX IF NOT EXISTS ix_conversation_members_user_id
ON app.conversation_members (user_id);

CREATE INDEX IF NOT EXISTS ix_conversation_members_conversation_id
ON app.conversation_members (conversation_id);

-- ===== MESSAGES =====
CREATE INDEX IF NOT EXISTS ix_messages_conversation_id
ON app.messages (conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS ix_messages_sender_id
ON app.messages (sender_id);

CREATE INDEX IF NOT EXISTS ix_messages_deleted_at
ON app.messages (deleted_at)
WHERE deleted_at IS NOT NULL;

COMMIT;
