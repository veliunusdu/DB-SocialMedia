# 📊 Indexing Strategy

This document outlines the indexing strategy for the MarketplaceDB PostgreSQL database.

## Core Principles

1. **Index frequently queried columns** - Primary keys, foreign keys, and filters
2. **Optimize for read-heavy operations** - Social feeds, user lookups, message retrieval
3. **Balance write performance** - Avoid over-indexing to maintain insert/update speed
4. **Support full-text search** - Using trigram indexes for fuzzy matching

---

## User & Profile Indexes

### Users Table
```sql
-- Unique index on case-insensitive username
CREATE UNIQUE INDEX ux_users_username_ci ON app.users (lower(username));

-- Timestamp index for recent user queries
CREATE INDEX ix_users_created_at ON app.users (created_at DESC);

-- Email lookup (automatic via UNIQUE constraint)
-- Covered by: UNIQUE (email)
```

### Profiles Table
```sql
-- Foreign key index for user_id
CREATE INDEX ix_profiles_user_id ON app.profiles (user_id);
```

**Rationale:**
- Username searches are common and case-insensitive
- Recent user queries needed for registration analytics
- Profile lookups always by user_id (1:1 relationship)

---

## Posts & Engagement Indexes

### Posts Table
```sql
-- User's posts lookup
CREATE INDEX ix_posts_user_id ON app.posts (user_id);

-- Recent posts (for feeds)
CREATE INDEX ix_posts_created_at ON app.posts (created_at DESC);

-- Composite index for user's recent posts
CREATE INDEX ix_posts_user_created ON app.posts (user_id, created_at DESC);
```

### Post Media
```sql
-- Enforce unique position per post
CREATE UNIQUE INDEX ux_post_media_position ON app.post_media (post_id, position);

-- Lookup media by post
CREATE INDEX ix_post_media_post_id ON app.post_media (post_id);
```

### Likes & Comments
```sql
-- Likes: PK (post_id, user_id) provides necessary coverage

-- Comments by post
CREATE INDEX ix_comments_post_id ON app.comments (post_id);

-- Comments by user
CREATE INDEX ix_comments_user_id ON app.comments (user_id);

-- Nested comment lookups
CREATE INDEX ix_comments_parent_id ON app.comments (parent_comment_id);
```

**Rationale:**
- Feed queries need efficient post retrieval by time
- User profile pages need quick access to user's posts
- Media carousel depends on ordered position lookups
- Comment threads require parent-child navigation

---

## Social Graph Indexes

### Follows Table
```sql
-- PK (follower_id, followed_id) provides coverage for:
--   - "Who does UserX follow?" (follower_id lookup)
--   - "Who follows UserX?" (followed_id lookup via index on second column)

-- Additional index for reverse lookups
CREATE INDEX ix_follows_followed_id ON app.follows (followed_id);
```

### Follow Requests
```sql
-- Requester's pending requests
CREATE INDEX ix_follow_requests_requester ON app.follow_requests (requester_id);

-- Target's incoming requests
CREATE INDEX ix_follow_requests_target ON app.follow_requests (target_id);

-- Status-based queries (pending requests)
CREATE INDEX ix_follow_requests_status ON app.follow_requests (status);

-- Composite for efficient "pending requests for user X"
CREATE INDEX ix_follow_requests_target_status 
ON app.follow_requests (target_id, status);
```

**Rationale:**
- Social graph queries are bidirectional (followers/following)
- Private accounts need efficient pending request lookups
- Feed generation requires knowing follow relationships

---

## Messaging Indexes

### Conversations
```sql
-- User's conversations
CREATE INDEX ix_conversation_members_user_id 
ON app.conversation_members (user_id);

-- Conversation membership lookup
CREATE INDEX ix_conversation_members_conversation_id 
ON app.conversation_members (conversation_id);
```

### Messages
```sql
-- Messages in a conversation (ordered)
CREATE INDEX ix_messages_conversation_created 
ON app.messages (conversation_id, created_at DESC);

-- Sender's messages
CREATE INDEX ix_messages_sender_id ON app.messages (sender_id);

-- Soft delete support
CREATE INDEX ix_messages_deleted_at ON app.messages (deleted_at) 
WHERE deleted_at IS NOT NULL;
```

**Rationale:**
- Message retrieval is always conversation-scoped and time-ordered
- Partial index on `deleted_at` for efficient soft-deleted message queries
- User membership checks must be fast for RLS enforcement

---

## Notifications Indexes

```sql
-- User's notifications (ordered by time)
CREATE INDEX ix_notifications_user_created 
ON app.notifications (user_id, created_at DESC);

-- Unread notifications count
CREATE INDEX ix_notifications_user_read 
ON app.notifications (user_id, is_read) 
WHERE is_read = false;
```

**Rationale:**
- Notification feed is per-user, time-ordered
- Partial index on unread notifications improves badge counts

---

## Full-Text Search (Trigram)

```sql
-- Enable pg_trgm extension
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Fuzzy username search
CREATE INDEX ix_users_username_trgm 
ON app.users USING gin (username gin_trgm_ops);

-- Bio search
CREATE INDEX ix_profiles_bio_trgm 
ON app.profiles USING gin (bio gin_trgm_ops);

-- Post caption search
CREATE INDEX ix_posts_caption_trgm 
ON app.posts USING gin (caption gin_trgm_ops);
```

**Rationale:**
- User discovery needs fuzzy matching ("john" → "johnny", "jon", etc.)
- Search functionality in posts and profiles

---

## Index Maintenance

### Monitoring Unused Indexes
```sql
SELECT 
  schemaname, 
  tablename, 
  indexname, 
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Reindexing (if needed)
```sql
-- Rebuild all indexes in app schema
REINDEX SCHEMA app;

-- Rebuild specific index
REINDEX INDEX app.ix_posts_user_created;
```

---

## Performance Considerations

1. **Compound Indexes:**
   - Order columns by cardinality (high → low)
   - Match query patterns (WHERE + ORDER BY)

2. **Partial Indexes:**
   - Use for filtered queries (`WHERE deleted_at IS NOT NULL`)
   - Reduces index size and maintenance cost

3. **Covering Indexes:**
   - Include frequently accessed columns in index (PostgreSQL INCLUDE clause)
   - Avoid table lookups for common queries

4. **Avoid Over-Indexing:**
   - Each index slows down INSERT/UPDATE operations
   - Monitor `pg_stat_user_tables.n_tup_ins/upd/del` vs `idx_scan`

---

## Future Optimizations

- **Partitioning:** Consider partitioning `messages` and `posts` by date
- **Materialized Views:** For expensive feed/analytics queries
- **BRIN Indexes:** For time-series data (if tables grow very large)
