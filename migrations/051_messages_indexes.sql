BEGIN;

-- Fast fetch messages by conversation (chat screen)
CREATE INDEX IF NOT EXISTS ix_messages_conversation_created_at
ON app.messages (conversation_id, created_at DESC);

-- Fast list "my conversations"
CREATE INDEX IF NOT EXISTS ix_conversation_members_user
ON app.conversation_members (user_id, conversation_id);

-- Search in messages (pg_trgm is enabled)
CREATE INDEX IF NOT EXISTS ix_messages_body_trgm
ON app.messages USING gin (body gin_trgm_ops);

-- Soft delete filter optimization
CREATE INDEX IF NOT EXISTS ix_messages_not_deleted
ON app.messages (conversation_id, created_at DESC)
WHERE deleted_at IS NULL;

COMMIT;
