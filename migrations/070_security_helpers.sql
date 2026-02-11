BEGIN;

-- We will simulate auth with a session variable for local testing:
-- SELECT set_config('app.current_user_id','<uuid>', true);

CREATE OR REPLACE FUNCTION app.current_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('app.current_user_id', true), '')::uuid;
$$;

CREATE OR REPLACE FUNCTION app.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(current_setting('app.is_admin', true), '') = 'true';
$$;

-- convenience procedure for psql demo
CREATE OR REPLACE PROCEDURE app.set_current_user(p_user uuid, p_is_admin boolean DEFAULT false)
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM set_config('app.current_user_id', p_user::text, true);
  PERFORM set_config('app.is_admin', CASE WHEN p_is_admin THEN 'true' ELSE 'false' END, true);
END;
$$;

COMMIT;
