BEGIN;

-- 1) FK from members.last_read_message_id -> messages.id (idempotent)
ALTER TABLE app.conversation_members
  DROP CONSTRAINT IF EXISTS fk_members_last_read_message;

ALTER TABLE app.conversation_members
  ADD CONSTRAINT fk_members_last_read_message
  FOREIGN KEY (last_read_message_id) REFERENCES app.messages(id) ON DELETE SET NULL;

-- 2) can_message(sender, receiver)
CREATE OR REPLACE FUNCTION app.can_message(p_sender uuid, p_receiver uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT
    CASE
      WHEN p_sender = p_receiver THEN true
      WHEN (SELECT is_private FROM app.users WHERE id=p_receiver) = false THEN true
      WHEN app.is_following(p_sender, p_receiver) THEN true
      WHEN EXISTS (
        SELECT 1
        FROM app.conversations c
        JOIN app.conversation_members m1 ON m1.conversation_id=c.id AND m1.user_id=p_sender
        JOIN app.conversation_members m2 ON m2.conversation_id=c.id AND m2.user_id=p_receiver
        WHERE c.kind='direct'
      ) THEN true
      ELSE false
    END;
$$;

-- 3) Ensure notifications.type CHECK includes 'message' (idempotent)
ALTER TABLE app.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE app.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('like', 'comment', 'follow', 'follow_request', 'message'));

-- 4) Trigger: notify all other members on new message
CREATE OR REPLACE FUNCTION app.trg_notify_message()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO app.notifications(user_id, actor_id, type)
  SELECT
    m.user_id, NEW.sender_id, 'message'
  FROM app.conversation_members m
  WHERE m.conversation_id = NEW.conversation_id
    AND m.user_id <> NEW.sender_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_message ON app.messages;

CREATE TRIGGER trg_notify_message
AFTER INSERT ON app.messages
FOR EACH ROW
EXECUTE FUNCTION app.trg_notify_message();

COMMIT;
