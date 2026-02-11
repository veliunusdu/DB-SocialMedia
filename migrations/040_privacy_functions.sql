BEGIN;

-- Helper: are we following?
CREATE OR REPLACE FUNCTION app.is_following(p_follower uuid, p_followed uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM app.follows f
    WHERE f.follower_id = p_follower
      AND f.followed_id = p_followed
  );
$$;

-- Helper: is account private?
CREATE OR REPLACE FUNCTION app.is_private_user(p_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT u.is_private
  FROM app.users u
  WHERE u.id = p_user;
$$;

-- Core policy function: can viewer see the post?
CREATE OR REPLACE FUNCTION app.can_view_post(p_viewer uuid, p_post_id bigint)
RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_owner uuid;
  v_visibility text;
BEGIN
  SELECT p.user_id, p.visibility INTO v_owner, v_visibility
  FROM app.posts p
  WHERE p.id = p_post_id;

  IF v_owner IS NULL THEN
    RETURN false;
  END IF;

  -- owner always can view
  IF p_viewer = v_owner THEN
    RETURN true;
  END IF;

  -- public posts always visible
  IF v_visibility = 'public' THEN
    RETURN true;
  END IF;

  -- followers-only: must follow the owner
  IF v_visibility = 'followers' THEN
    RETURN app.is_following(p_viewer, v_owner);
  END IF;

  RETURN false;
END;
$$;

COMMIT;
