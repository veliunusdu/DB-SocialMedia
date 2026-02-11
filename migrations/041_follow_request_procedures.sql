BEGIN;

-- Accept follow request (transaction-safe)
CREATE OR REPLACE PROCEDURE app.accept_follow_request(
  p_request_id bigint,
  p_actor uuid
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_requester uuid;
  v_target uuid;
  v_status text;
BEGIN
  SELECT requester_id, target_id, status
    INTO v_requester, v_target, v_status
  FROM app.follow_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'follow_request % not found', p_request_id USING ERRCODE = 'P0002';
  END IF;

  IF v_status <> 'pending' THEN
    RAISE EXCEPTION 'follow_request % is not pending (status=%)', p_request_id, v_status USING ERRCODE = 'P0001';
  END IF;

  IF p_actor <> v_target THEN
    RAISE EXCEPTION 'only target can accept this request' USING ERRCODE = '42501';
  END IF;

  UPDATE app.follow_requests
  SET status = 'accepted', updated_at = now()
  WHERE id = p_request_id;

  INSERT INTO app.follows(follower_id, followed_id)
  VALUES (v_requester, v_target)
  ON CONFLICT DO NOTHING;

  -- optional: notify requester that they are now followed (accepted)
  INSERT INTO app.notifications(user_id, actor_id, type)
  VALUES (v_requester, v_target, 'follow');

END;
$$;


-- Reject follow request
CREATE OR REPLACE PROCEDURE app.reject_follow_request(
  p_request_id bigint,
  p_actor uuid
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_target uuid;
  v_status text;
BEGIN
  SELECT target_id, status INTO v_target, v_status
  FROM app.follow_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'follow_request % not found', p_request_id USING ERRCODE = 'P0002';
  END IF;

  IF v_status <> 'pending' THEN
    RAISE EXCEPTION 'follow_request % is not pending (status=%)', p_request_id, v_status USING ERRCODE = 'P0001';
  END IF;

  IF p_actor <> v_target THEN
    RAISE EXCEPTION 'only target can reject this request' USING ERRCODE = '42501';
  END IF;

  UPDATE app.follow_requests
  SET status = 'rejected', updated_at = now()
  WHERE id = p_request_id;

END;
$$;


-- Cancel follow request (requester cancels)
CREATE OR REPLACE PROCEDURE app.cancel_follow_request(
  p_request_id bigint,
  p_actor uuid
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_requester uuid;
  v_status text;
BEGIN
  SELECT requester_id, status INTO v_requester, v_status
  FROM app.follow_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'follow_request % not found', p_request_id USING ERRCODE = 'P0002';
  END IF;

  IF v_status <> 'pending' THEN
    RAISE EXCEPTION 'follow_request % is not pending (status=%)', p_request_id, v_status USING ERRCODE = 'P0001';
  END IF;

  IF p_actor <> v_requester THEN
    RAISE EXCEPTION 'only requester can cancel this request' USING ERRCODE = '42501';
  END IF;

  UPDATE app.follow_requests
  SET status = 'cancelled', updated_at = now()
  WHERE id = p_request_id;

END;
$$;

COMMIT;
