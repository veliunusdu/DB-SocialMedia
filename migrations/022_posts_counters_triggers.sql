BEGIN;

-- likes_count maintenance
CREATE OR REPLACE FUNCTION app.trg_posts_like_counter()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE app.posts
    SET likes_count = likes_count + 1
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE app.posts
    SET likes_count = GREATEST(likes_count - 1, 0)
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_post_likes_counter_ins ON app.post_likes;
CREATE TRIGGER trg_post_likes_counter_ins
AFTER INSERT ON app.post_likes
FOR EACH ROW
EXECUTE FUNCTION app.trg_posts_like_counter();

DROP TRIGGER IF EXISTS trg_post_likes_counter_del ON app.post_likes;
CREATE TRIGGER trg_post_likes_counter_del
AFTER DELETE ON app.post_likes
FOR EACH ROW
EXECUTE FUNCTION app.trg_posts_like_counter();


-- comments_count maintenance
CREATE OR REPLACE FUNCTION app.trg_posts_comment_counter()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE app.posts
    SET comments_count = comments_count + 1
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE app.posts
    SET comments_count = GREATEST(comments_count - 1, 0)
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_comments_counter_ins ON app.comments;
CREATE TRIGGER trg_comments_counter_ins
AFTER INSERT ON app.comments
FOR EACH ROW
EXECUTE FUNCTION app.trg_posts_comment_counter();

DROP TRIGGER IF EXISTS trg_comments_counter_del ON app.comments;
CREATE TRIGGER trg_comments_counter_del
AFTER DELETE ON app.comments
FOR EACH ROW
EXECUTE FUNCTION app.trg_posts_comment_counter();

COMMIT;
