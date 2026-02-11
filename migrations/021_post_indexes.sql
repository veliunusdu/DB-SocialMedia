BEGIN;

-- Feed: user posts by newest
CREATE INDEX IF NOT EXISTS ix_posts_user_created_at
ON app.posts (user_id, created_at DESC);

-- Likes lookup
CREATE INDEX IF NOT EXISTS ix_post_likes_user_created_at
ON app.post_likes (user_id, created_at DESC);

-- Comments for a post
CREATE INDEX IF NOT EXISTS ix_comments_post_created_at
ON app.comments (post_id, created_at ASC);

-- Replies for a comment
CREATE INDEX IF NOT EXISTS ix_comments_parent
ON app.comments (parent_comment_id, created_at ASC);

COMMIT;
