BEGIN;

DROP POLICY IF EXISTS messages_update_self ON app.messages;

CREATE POLICY messages_update_self
ON app.messages
FOR UPDATE
USING (
  app.is_admin()
  OR sender_id = app.current_user_id()
)
WITH CHECK (
  app.is_admin()
  OR sender_id = app.current_user_id()
);

COMMIT;
