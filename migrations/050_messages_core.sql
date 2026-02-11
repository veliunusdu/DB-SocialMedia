BEGIN;

-- 1) Conversations: 1-1 DM için "direct" kullanacağız
CREATE TABLE IF NOT EXISTS app.conversations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind text NOT NULL CHECK (kind IN ('direct','group')),
  created_by uuid NULL REFERENCES app.users(id) ON DELETE SET NULL,
  title text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_conversations_set_updated_at ON app.conversations;
CREATE TRIGGER trg_conversations_set_updated_at
BEFORE UPDATE ON app.conversations
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

-- 2) Conversation members
CREATE TABLE IF NOT EXISTS app.conversation_members (
  conversation_id bigint NOT NULL REFERENCES app.conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('member','admin')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  last_read_message_id bigint NULL,
  PRIMARY KEY (conversation_id, user_id)
);

-- last_read_message_id FK (messages table comes next) => add later in 052 migration to avoid circular dependency.

-- 3) Messages
CREATE TABLE IF NOT EXISTS app.messages (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  conversation_id bigint NOT NULL REFERENCES app.conversations(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,

  body text NOT NULL,
  -- simple: optional metadata for future
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz NULL
);

DROP TRIGGER IF EXISTS trg_messages_set_updated_at ON app.messages;
CREATE TRIGGER trg_messages_set_updated_at
BEFORE UPDATE ON app.messages
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

COMMIT;
