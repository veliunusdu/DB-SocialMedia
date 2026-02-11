BEGIN;

-- Unread notifications view
CREATE OR REPLACE VIEW app.v_notifications_unread AS
SELECT n.*
FROM app.notifications n
WHERE n.is_read = false;

-- Generic feed view (privacy is applied via can_view_post(viewer, post_id) in the query)
CREATE OR REPLACE VIEW app.v_feed AS
SELECT
  p.id AS post_id,
  p.user_id AS owner_id,
  p.caption,
  p.visibility,
  p.likes_count,
  p.comments_count,
  p.created_at
FROM app.posts p;

COMMIT;
