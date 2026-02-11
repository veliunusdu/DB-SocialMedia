BEGIN;

-- ===== USERS =====
DROP POLICY IF EXISTS users_select ON app.users;
CREATE POLICY users_select
ON app.users
FOR SELECT
USING (true); -- like instagram: basic user fields are public-ish (we can tighten later)

DROP POLICY IF EXISTS users_update_self ON app.users;
CREATE POLICY users_update_self
ON app.users
FOR UPDATE
USING (app.is_admin() OR id = app.current_user_id())
WITH CHECK (app.is_admin() OR id = app.current_user_id());

-- ===== PROFILES =====
DROP POLICY IF EXISTS profiles_select ON app.profiles;
CREATE POLICY profiles_select
ON app.profiles
FOR SELECT
USING (true);

DROP POLICY IF EXISTS profiles_upsert_self ON app.profiles;
CREATE POLICY profiles_upsert_self
ON app.profiles
FOR INSERT
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());

DROP POLICY IF EXISTS profiles_update_self ON app.profiles;
CREATE POLICY profiles_update_self
ON app.profiles
FOR UPDATE
USING (app.is_admin() OR user_id = app.current_user_id())
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());

-- ===== POSTS (privacy) =====
-- You already have can_view_post(viewer, post_id) from 040_privacy_functions.sql
DROP POLICY IF EXISTS posts_select ON app.posts;
CREATE POLICY posts_select
ON app.posts
FOR SELECT
USING (app.is_admin() OR app.can_view_post(app.current_user_id(), id));

DROP POLICY IF EXISTS posts_insert_self ON app.posts;
CREATE POLICY posts_insert_self
ON app.posts
FOR INSERT
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());

DROP POLICY IF EXISTS posts_update_self ON app.posts;
CREATE POLICY posts_update_self
ON app.posts
FOR UPDATE
USING (app.is_admin() OR user_id = app.current_user_id())
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());

DROP POLICY IF EXISTS posts_delete_self ON app.posts;
CREATE POLICY posts_delete_self
ON app.posts
FOR DELETE
USING (app.is_admin() OR user_id = app.current_user_id());

-- ===== POST MEDIA =====
DROP POLICY IF EXISTS post_media_select ON app.post_media;
CREATE POLICY post_media_select
ON app.post_media
FOR SELECT
USING (
  app.is_admin()
  OR EXISTS (
    SELECT 1 FROM app.posts p
    WHERE p.id = post_id
      AND app.can_view_post(app.current_user_id(), p.id)
  )
);

DROP POLICY IF EXISTS post_media_write_owner ON app.post_media;
CREATE POLICY post_media_write_owner
ON app.post_media
FOR ALL
USING (
  app.is_admin()
  OR EXISTS (SELECT 1 FROM app.posts p WHERE p.id=post_id AND p.user_id=app.current_user_id())
)
WITH CHECK (
  app.is_admin()
  OR EXISTS (SELECT 1 FROM app.posts p WHERE p.id=post_id AND p.user_id=app.current_user_id())
);

-- ===== LIKES =====
DROP POLICY IF EXISTS post_likes_select ON app.post_likes;
CREATE POLICY post_likes_select
ON app.post_likes
FOR SELECT
USING (
  app.is_admin()
  OR EXISTS (SELECT 1 FROM app.posts p WHERE p.id=post_id AND app.can_view_post(app.current_user_id(), p.id))
);

DROP POLICY IF EXISTS post_likes_insert_self ON app.post_likes;
CREATE POLICY post_likes_insert_self
ON app.post_likes
FOR INSERT
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());

DROP POLICY IF EXISTS post_likes_delete_self ON app.post_likes;
CREATE POLICY post_likes_delete_self
ON app.post_likes
FOR DELETE
USING (app.is_admin() OR user_id = app.current_user_id());

-- ===== COMMENTS =====
DROP POLICY IF EXISTS comments_select ON app.comments;
CREATE POLICY comments_select
ON app.comments
FOR SELECT
USING (
  app.is_admin()
  OR EXISTS (SELECT 1 FROM app.posts p WHERE p.id=post_id AND app.can_view_post(app.current_user_id(), p.id))
);

DROP POLICY IF EXISTS comments_insert_self ON app.comments;
CREATE POLICY comments_insert_self
ON app.comments
FOR INSERT
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());

DROP POLICY IF EXISTS comments_update_self ON app.comments;
CREATE POLICY comments_update_self
ON app.comments
FOR UPDATE
USING (app.is_admin() OR user_id = app.current_user_id())
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());

DROP POLICY IF EXISTS comments_delete_self ON app.comments;
CREATE POLICY comments_delete_self
ON app.comments
FOR DELETE
USING (app.is_admin() OR user_id = app.current_user_id());

-- ===== FOLLOWS / REQUESTS =====
DROP POLICY IF EXISTS follows_select_involved ON app.follows;
CREATE POLICY follows_select_involved
ON app.follows
FOR SELECT
USING (app.is_admin() OR follower_id = app.current_user_id() OR followed_id = app.current_user_id());

DROP POLICY IF EXISTS follows_insert_self ON app.follows;
CREATE POLICY follows_insert_self
ON app.follows
FOR INSERT
WITH CHECK (app.is_admin() OR follower_id = app.current_user_id());

DROP POLICY IF EXISTS follows_delete_self ON app.follows;
CREATE POLICY follows_delete_self
ON app.follows
FOR DELETE
USING (app.is_admin() OR follower_id = app.current_user_id());

DROP POLICY IF EXISTS follow_requests_select_involved ON app.follow_requests;
CREATE POLICY follow_requests_select_involved
ON app.follow_requests
FOR SELECT
USING (app.is_admin() OR requester_id = app.current_user_id() OR target_id = app.current_user_id());

DROP POLICY IF EXISTS follow_requests_insert_self ON app.follow_requests;
CREATE POLICY follow_requests_insert_self
ON app.follow_requests
FOR INSERT
WITH CHECK (app.is_admin() OR requester_id = app.current_user_id());

DROP POLICY IF EXISTS follow_requests_update_target ON app.follow_requests;
CREATE POLICY follow_requests_update_target
ON app.follow_requests
FOR UPDATE
USING (app.is_admin() OR target_id = app.current_user_id())
WITH CHECK (app.is_admin() OR target_id = app.current_user_id());

-- ===== CONVERSATIONS / MEMBERS / MESSAGES =====
DROP POLICY IF EXISTS conversations_select_member ON app.conversations;
CREATE POLICY conversations_select_member
ON app.conversations
FOR SELECT
USING (
  app.is_admin()
  OR EXISTS (
    SELECT 1 FROM app.conversation_members m
    WHERE m.conversation_id = id AND m.user_id = app.current_user_id()
  )
);

DROP POLICY IF EXISTS conversation_members_select_self ON app.conversation_members;
CREATE POLICY conversation_members_select_self
ON app.conversation_members
FOR SELECT
USING (app.is_admin() OR user_id = app.current_user_id());

DROP POLICY IF EXISTS messages_select_member ON app.messages;
CREATE POLICY messages_select_member
ON app.messages
FOR SELECT
USING (
  app.is_admin()
  OR EXISTS (
    SELECT 1 FROM app.conversation_members m
    WHERE m.conversation_id = conversation_id
      AND m.user_id = app.current_user_id()
  )
);

DROP POLICY IF EXISTS messages_insert_sender_member ON app.messages;
CREATE POLICY messages_insert_sender_member
ON app.messages
FOR INSERT
WITH CHECK (
  app.is_admin()
  OR (
    sender_id = app.current_user_id()
    AND EXISTS (
      SELECT 1 FROM app.conversation_members m
      WHERE m.conversation_id = conversation_id
        AND m.user_id = app.current_user_id()
    )
  )
);

-- ===== NOTIFICATIONS =====
DROP POLICY IF EXISTS notifications_select_self ON app.notifications;
CREATE POLICY notifications_select_self
ON app.notifications
FOR SELECT
USING (app.is_admin() OR user_id = app.current_user_id());

DROP POLICY IF EXISTS notifications_update_self ON app.notifications;
CREATE POLICY notifications_update_self
ON app.notifications
FOR UPDATE
USING (app.is_admin() OR user_id = app.current_user_id())
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());

COMMIT;
