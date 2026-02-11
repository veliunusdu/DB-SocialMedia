BEGIN;

-- 0) helper: current user must exist
CREATE OR REPLACE FUNCTION app.require_current_user()
RETURNS uuid
LANGUAGE plpgsql
STABLE
AS $$
DECLARE v_me uuid;
BEGIN
  v_me := app.current_user_id();
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'current user is not set (app.current_user_id is null)'
      USING ERRCODE = '42501';
  END IF;
  RETURN v_me;
END;
$$;


-- 1) Create or reuse a direct conversation with "other user"
--    Enforces: can_message(me, other) AND both users exist
CREATE OR REPLACE FUNCTION app.create_direct_conversation(p_other uuid)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app, public
AS $$
DECLARE
  v_me uuid;
  v_conv_id bigint;
BEGIN
  v_me := app.require_current_user();

  IF p_other IS NULL THEN
    RAISE EXCEPTION 'p_other is null' USING ERRCODE='22004';
  END IF;

  IF v_me = p_other THEN
    RAISE EXCEPTION 'cannot DM yourself' USING ERRCODE='22023';
  END IF;

  -- ensure other exists
  IF NOT EXISTS (SELECT 1 FROM app.users u WHERE u.id = p_other) THEN
    RAISE EXCEPTION 'other user not found' USING ERRCODE='P0002';
  END IF;

  -- privacy / rule gate
  IF NOT app.can_message(v_me, p_other) THEN
    RAISE EXCEPTION 'cannot message this user (privacy rule)' USING ERRCODE='42501';
  END IF;

  -- reuse existing direct conversation if present
  SELECT c.id
  INTO v_conv_id
  FROM app.conversations c
  JOIN app.conversation_members m1 ON m1.conversation_id=c.id AND m1.user_id=v_me
  JOIN app.conversation_members m2 ON m2.conversation_id=c.id AND m2.user_id=p_other
  WHERE c.kind='direct'
  ORDER BY c.id DESC
  LIMIT 1;

  IF v_conv_id IS NOT NULL THEN
    RETURN v_conv_id;
  END IF;

  -- create new
  INSERT INTO app.conversations(kind, created_by)
  VALUES ('direct', v_me)
  RETURNING id INTO v_conv_id;

  INSERT INTO app.conversation_members(conversation_id, user_id)
  VALUES (v_conv_id, v_me)
  ON CONFLICT DO NOTHING;

  INSERT INTO app.conversation_members(conversation_id, user_id)
  VALUES (v_conv_id, p_other)
  ON CONFLICT DO NOTHING;

  RETURN v_conv_id;
END;
$$;


-- 2) Send message ONLY via procedure/function (guardrails inside)
CREATE OR REPLACE FUNCTION app.send_message(p_conversation_id bigint, p_body text)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app, public
AS $$
DECLARE
  v_me uuid;
  v_kind text;
  v_other uuid;
  v_msg_id bigint;
BEGIN
  v_me := app.require_current_user();

  IF p_conversation_id IS NULL THEN
    RAISE EXCEPTION 'conversation_id is null' USING ERRCODE='22004';
  END IF;

  IF p_body IS NULL OR length(btrim(p_body)) = 0 THEN
    RAISE EXCEPTION 'message body is empty' USING ERRCODE='22023';
  END IF;

  -- must be a member
  IF NOT EXISTS (
    SELECT 1 FROM app.conversation_members m
    WHERE m.conversation_id = p_conversation_id
      AND m.user_id = v_me
  ) THEN
    RAISE EXCEPTION 'not a member of this conversation' USING ERRCODE='42501';
  END IF;

  SELECT c.kind INTO v_kind
  FROM app.conversations c
  WHERE c.id = p_conversation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'conversation not found' USING ERRCODE='P0002';
  END IF;

  -- if direct: enforce can_message(me, other) on each send
  IF v_kind = 'direct' THEN
    SELECT m.user_id INTO v_other
    FROM app.conversation_members m
    WHERE m.conversation_id = p_conversation_id
      AND m.user_id <> v_me
    ORDER BY m.user_id
    LIMIT 1;

    IF v_other IS NULL THEN
      RAISE EXCEPTION 'direct conversation missing other member' USING ERRCODE='P0003';
    END IF;

    IF NOT app.can_message(v_me, v_other) THEN
      RAISE EXCEPTION 'cannot message this user (privacy rule)' USING ERRCODE='42501';
    END IF;
  END IF;

  INSERT INTO app.messages(conversation_id, sender_id, body)
  VALUES (p_conversation_id, v_me, p_body)
  RETURNING id INTO v_msg_id;

  RETURN v_msg_id;
END;
$$;


-- 3) Hard rule: direct conversations must have exactly 2 members
--    Enforced with a constraint trigger after insert/delete on conversation_members
CREATE OR REPLACE FUNCTION app.trg_enforce_direct_member_count()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_kind text;
  v_cnt int;
  v_conv bigint;
BEGIN
  v_conv := COALESCE(NEW.conversation_id, OLD.conversation_id);

  SELECT kind INTO v_kind
  FROM app.conversations
  WHERE id = v_conv;

  IF v_kind <> 'direct' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT count(*) INTO v_cnt
  FROM app.conversation_members
  WHERE conversation_id = v_conv;

  -- allow 0/1 temporarily during creation inside same txn; enforce only when >=2 and prevent >2
  IF v_cnt > 2 THEN
    RAISE EXCEPTION 'direct conversation cannot have more than 2 members' USING ERRCODE='23514';
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_direct_member_count_ins ON app.conversation_members;
CREATE TRIGGER trg_enforce_direct_member_count_ins
AFTER INSERT ON app.conversation_members
FOR EACH ROW EXECUTE FUNCTION app.trg_enforce_direct_member_count();

DROP TRIGGER IF EXISTS trg_enforce_direct_member_count_del ON app.conversation_members;
CREATE TRIGGER trg_enforce_direct_member_count_del
AFTER DELETE ON app.conversation_members
FOR EACH ROW EXECUTE FUNCTION app.trg_enforce_direct_member_count();


-- 4) permissions: allow app_user to call the safe APIs
GRANT EXECUTE ON FUNCTION app.create_direct_conversation(uuid) TO app_user;
GRANT EXECUTE ON FUNCTION app.send_message(bigint, text) TO app_user;

COMMIT;
