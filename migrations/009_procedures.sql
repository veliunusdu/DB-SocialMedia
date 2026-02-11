BEGIN;

-- Convenience procedure for setting current user context
CREATE OR REPLACE PROCEDURE app.set_current_user(p_user uuid, p_is_admin boolean DEFAULT false)
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM set_config('app.current_user_id', p_user::text, true);
  PERFORM set_config('app.is_admin', CASE WHEN p_is_admin THEN 'true' ELSE 'false' END, true);
END;
$$;

-- Helper: Require current user (throws error if not set)
CREATE OR REPLACE FUNCTION app.require_current_user()
RETURNS uuid
LANGUAGE plpgsql
STABLE
AS $$
DECLARE v_me uuid;
BEGIN
  v_me := app.current_user_id();
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'current user is not set (app.current_user_id is null)'
      USING ERRCODE = '42501';
  END IF;
  RETURN v_me;
END;
$$;

COMMIT;
