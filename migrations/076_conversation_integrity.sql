BEGIN;

CREATE OR REPLACE FUNCTION app.trg_conversation_integrity()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.created_by IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM app.conversation_members m
      WHERE m.conversation_id = NEW.id
        AND m.user_id = NEW.created_by
    ) THEN
      RAISE EXCEPTION 'created_by must be a member of the conversation';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_conversation_integrity ON app.conversations;

CREATE TRIGGER trg_conversation_integrity
AFTER INSERT ON app.conversations
FOR EACH ROW
EXECUTE FUNCTION app.trg_conversation_integrity();

COMMIT;
