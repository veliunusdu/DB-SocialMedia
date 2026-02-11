BEGIN;

-- CONVERSATIONS
CREATE TABLE IF NOT EXISTS app.conversations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind text NOT NULL CHECK (kind IN ('direct','group')),
  created_by uuid NULL REFERENCES app.users(id) ON DELETE SET NULL,
  title text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- CONVERSATION MEMBERS
CREATE TABLE IF NOT EXISTS app.conversation_members (
  conversation_id bigint NOT NULL REFERENCES app.conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('member','admin')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  last_read_message_id bigint NULL,
  PRIMARY KEY (conversation_id, user_id)
);

-- MESSAGES
CREATE TABLE IF NOT EXISTS app.messages (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  conversation_id bigint NOT NULL REFERENCES app.conversations(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,

  body text NOT NULL,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz NULL
);

COMMIT;
