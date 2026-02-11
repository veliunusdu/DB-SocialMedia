BEGIN;

-- Enable Row Level Security (RLS) on all tables
-- Policies will be defined in 070+ migrations

ALTER TABLE app.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.post_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.follow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.messages ENABLE ROW LEVEL SECURITY;

-- NOTE: Actual RLS policies are defined in 070-079 migration range
-- This file just enables RLS infrastructure

COMMIT;
