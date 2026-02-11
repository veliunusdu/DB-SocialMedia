BEGIN;

-- Disable direct inserts from app_user (force using app.send_message)
DROP POLICY IF EXISTS messages_insert_sender_member ON app.messages;

CREATE POLICY messages_insert_via_definer_only
ON app.messages
FOR INSERT
WITH CHECK (
  -- only allow inserts when security definer function runs as table owner.
  -- app_user won't be table owner, so direct insert gets blocked.
  pg_catalog.current_user = 'postgres'
  OR app.is_admin()
);

COMMIT;
