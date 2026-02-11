BEGIN;

-- Helper to prevent self-notifications
CREATE OR REPLACE FUNCTION app.notify_guard(receiver uuid, actor uuid)
RETURNS boolean
LANGUAGE sql
AS $$
  SELECT receiver IS NOT NULL AND actor IS NOT NULL AND receiver <> actor;
$$;

-- 1) Notify on FOLLOW
CREATE OR REPLACE FUNCTION app.trg_notify_follow()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF app.notify_guard(NEW.followed_id, NEW.follower_id) THEN
    INSERT INTO app.notifications(user_id, actor_id, type)
    VALUES (NEW.followed_id, NEW.follower_id, 'follow');
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_follow ON app.follows;
CREATE TRIGGER trg_notify_follow
AFTER INSERT ON app.follows
FOR EACH ROW
EXECUTE FUNCTION app.trg_notify_follow();


-- 2) Notify on FOLLOW REQUEST (only when pending is created)
CREATE OR REPLACE FUNCTION app.trg_notify_follow_request()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'pending' AND app.notify_guard(NEW.target_id, NEW.requester_id) THEN
    INSERT INTO app.notifications(user_id, actor_id, type, follow_request_id)
    VALUES (NEW.target_id, NEW.requester_id, 'follow_request', NEW.id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_follow_request ON app.follow_requests;
CREATE TRIGGER trg_notify_follow_request
AFTER INSERT ON app.follow_requests
FOR EACH ROW
EXECUTE FUNCTION app.trg_notify_follow_request();


-- 3) Notify on LIKE (receiver = post owner)
CREATE OR REPLACE FUNCTION app.trg_notify_like()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_owner uuid;
BEGIN
  SELECT user_id INTO v_owner
  FROM app.posts
  WHERE id = NEW.post_id;

  IF app.notify_guard(v_owner, NEW.user_id) THEN
    INSERT INTO app.notifications(user_id, actor_id, type, post_id)
    VALUES (v_owner, NEW.user_id, 'like', NEW.post_id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_like ON app.post_likes;
CREATE TRIGGER trg_notify_like
AFTER INSERT ON app.post_likes
FOR EACH ROW
EXECUTE FUNCTION app.trg_notify_like();


-- 4) Notify on COMMENT (receiver = post owner)
CREATE OR REPLACE FUNCTION app.trg_notify_comment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_owner uuid;
BEGIN
  SELECT user_id INTO v_owner
  FROM app.posts
  WHERE id = NEW.post_id;

  IF app.notify_guard(v_owner, NEW.user_id) THEN
    INSERT INTO app.notifications(user_id, actor_id, type, post_id, comment_id)
    VALUES (v_owner, NEW.user_id, 'comment', NEW.post_id, NEW.id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_comment ON app.comments;
CREATE TRIGGER trg_notify_comment
AFTER INSERT ON app.comments
FOR EACH ROW
EXECUTE FUNCTION app.trg_notify_comment();

COMMIT;
