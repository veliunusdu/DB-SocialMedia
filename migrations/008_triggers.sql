BEGIN;

-- ===== USERS & PROFILES =====
DROP TRIGGER IF EXISTS trg_users_set_updated_at ON app.users;
CREATE TRIGGER trg_users_set_updated_at
BEFORE UPDATE ON app.users
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

DROP TRIGGER IF EXISTS trg_profiles_set_updated_at ON app.profiles;
CREATE TRIGGER trg_profiles_set_updated_at
BEFORE UPDATE ON app.profiles
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

-- ===== POSTS =====
DROP TRIGGER IF EXISTS trg_posts_set_updated_at ON app.posts;
CREATE TRIGGER trg_posts_set_updated_at
BEFORE UPDATE ON app.posts
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

-- ===== COMMENTS =====
DROP TRIGGER IF EXISTS trg_comments_set_updated_at ON app.comments;
CREATE TRIGGER trg_comments_set_updated_at
BEFORE UPDATE ON app.comments
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

-- ===== FOLLOW REQUESTS =====
DROP TRIGGER IF EXISTS trg_follow_requests_set_updated_at ON app.follow_requests;
CREATE TRIGGER trg_follow_requests_set_updated_at
BEFORE UPDATE ON app.follow_requests
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

-- ===== CONVERSATIONS =====
DROP TRIGGER IF EXISTS trg_conversations_set_updated_at ON app.conversations;
CREATE TRIGGER trg_conversations_set_updated_at
BEFORE UPDATE ON app.conversations
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

-- ===== MESSAGES =====
DROP TRIGGER IF EXISTS trg_messages_set_updated_at ON app.messages;
CREATE TRIGGER trg_messages_set_updated_at
BEFORE UPDATE ON app.messages
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

COMMIT;
