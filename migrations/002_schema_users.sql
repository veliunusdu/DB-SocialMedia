BEGIN;

-- Users (UUID like real auth systems)
CREATE TABLE IF NOT EXISTS app.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  email citext NOT NULL,
  username text NOT NULL,

  password_hash text NOT NULL,

  is_private boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'disabled', 'deleted')),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT users_email_unique UNIQUE (email),
  CONSTRAINT users_username_len CHECK (char_length(username) BETWEEN 3 AND 30),
  CONSTRAINT users_username_chars CHECK (username ~ '^[A-Za-z0-9._]+$')
);

-- Profile (1:1)
CREATE TABLE IF NOT EXISTS app.profiles (
  user_id uuid PRIMARY KEY
    REFERENCES app.users(id) ON DELETE CASCADE,

  full_name text,
  bio text CHECK (bio IS NULL OR char_length(bio) <= 150),
  website text,
  avatar_url text,

  posts_count int NOT NULL DEFAULT 0 CHECK (posts_count >= 0),
  followers_count int NOT NULL DEFAULT 0 CHECK (followers_count >= 0),
  following_count int NOT NULL DEFAULT 0 CHECK (following_count >= 0),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMIT;
