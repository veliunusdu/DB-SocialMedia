BEGIN;

-- Reusable updated_at trigger function
CREATE OR REPLACE FUNCTION app.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- Attach triggers
DROP TRIGGER IF EXISTS trg_users_set_updated_at ON app.users;
CREATE TRIGGER trg_users_set_updated_at
BEFORE UPDATE ON app.users
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

DROP TRIGGER IF EXISTS trg_profiles_set_updated_at ON app.profiles;
CREATE TRIGGER trg_profiles_set_updated_at
BEFORE UPDATE ON app.profiles
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

-- Portfolio-grade indexes
CREATE UNIQUE INDEX IF NOT EXISTS ux_users_username_ci
ON app.users (lower(username));

CREATE INDEX IF NOT EXISTS ix_users_created_at
ON app.users (created_at DESC);

CREATE INDEX IF NOT EXISTS ix_profiles_user_id
ON app.profiles (user_id);

COMMIT;
