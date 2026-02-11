# 🔐 Roles and Permissions

This document outlines the role-based access control (RBAC) and Row-Level Security (RLS) strategy for MarketplaceDB.

## Security Architecture

MarketplaceDB implements a **database-centric security model** with:
- **Row-Level Security (RLS)** - PostgreSQL native security at the row level
- **Session-based authentication** - Using `app.current_user_id` session variable
- **Security-definer functions** - Controlled privilege escalation for complex operations
- **Privacy functions** - Business logic for visibility rules (private accounts, follows, etc.)

---

## Authentication Model

### Session Variables

Authentication is simulated via PostgreSQL session configuration:

```sql
-- Set current authenticated user
SELECT set_config('app.current_user_id', '<user_uuid>', true);

-- Set admin flag
SELECT set_config('app.is_admin', 'true', true);
```

### Helper Functions

```sql
-- Get current authenticated user
CREATE FUNCTION app.current_user_id() RETURNS uuid;

-- Check if current user is admin
CREATE FUNCTION app.is_admin() RETURNS boolean;

-- Convenience procedure for testing
CREATE PROCEDURE app.set_current_user(p_user uuid, p_is_admin boolean);
```

**Usage:**
```sql
-- Login as a specific user
CALL app.set_current_user('12345678-1234-1234-1234-123456789abc');

-- Login as admin
CALL app.set_current_user('admin-uuid', true);
```

---

## Role Types

### 1. **Anonymous (unauthenticated)**
- No `app.current_user_id` set
- Can view public content only
- Cannot perform any write operations
- Most RLS policies deny access

### 2. **Authenticated User**
- Has `app.current_user_id` set
- Can read their own data
- Can read public or followed users' content
- Can create/update/delete their own resources
- Subject to privacy rules

### 3. **Admin**
- Has `app.is_admin()` = true
- Bypasses most RLS policies
- Can read/write all resources
- Used for moderation and system operations

---

## Row-Level Security Policies

### Users Table

**Read:** Everyone can view basic user info (public discovery)
```sql
CREATE POLICY users_select ON app.users
FOR SELECT USING (true);
```

**Update:** Users can only update themselves (or admin)
```sql
CREATE POLICY users_update_self ON app.users
FOR UPDATE
USING (app.is_admin() OR id = app.current_user_id())
WITH CHECK (app.is_admin() OR id = app.current_user_id());
```

---

### Profiles Table

**Read:** All profiles are viewable (public)
```sql
CREATE POLICY profiles_select ON app.profiles
FOR SELECT USING (true);
```

**Insert/Update:** Users can only modify their own profile
```sql
CREATE POLICY profiles_upsert_self ON app.profiles
FOR INSERT
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());
```

---

### Posts Table

**Read:** Privacy-aware visibility (public posts + followed users' posts)
```sql
CREATE POLICY posts_select ON app.posts
FOR SELECT
USING (app.is_admin() OR app.can_view_post(app.current_user_id(), id));
```

**Create:** Users can only create posts for themselves
```sql
CREATE POLICY posts_insert_self ON app.posts
FOR INSERT
WITH CHECK (app.is_admin() OR user_id = app.current_user_id());
```

**Update/Delete:** Users can only modify/delete their own posts
```sql
CREATE POLICY posts_update_self ON app.posts
FOR UPDATE
USING (app.is_admin() OR user_id = app.current_user_id());

CREATE POLICY posts_delete_self ON app.posts
FOR DELETE
USING (app.is_admin() OR user_id = app.current_user_id());
```

---

### Post Media, Likes, Comments

**Read:** Inherit visibility from parent post
```sql
CREATE POLICY post_media_select ON app.post_media
FOR SELECT
USING (
  app.is_admin()
  OR EXISTS (
    SELECT 1 FROM app.posts p
    WHERE p.id = post_id
      AND app.can_view_post(app.current_user_id(), p.id)
  )
);
```

**Write:** Only post owner can manage media/comments
- Media: Only post owner can add/modify
- Likes: Any user can like visible posts
- Comments: Any user can comment on visible posts

---

### Social Graph (Follows)

**Read:** Anyone can view follows (for follower/following counts)
```sql
CREATE POLICY follows_select ON app.follows
FOR SELECT USING (true);
```

**Insert/Delete:** Users can only manage their own follows
```sql
CREATE POLICY follows_insert_self ON app.follows
FOR INSERT
WITH CHECK (app.is_admin() OR follower_id = app.current_user_id());

CREATE POLICY follows_delete_self ON app.follows
FOR DELETE
USING (app.is_admin() OR follower_id = app.current_user_id());
```

---

### Follow Requests (Private Accounts)

**Read:** Users can see requests they sent or received
```sql
CREATE POLICY follow_requests_select ON app.follow_requests
FOR SELECT
USING (
  app.is_admin()
  OR requester_id = app.current_user_id()
  OR target_id = app.current_user_id()
);
```

**Create:** Users can only create requests as themselves
```sql
CREATE POLICY follow_requests_insert_self ON app.follow_requests
FOR INSERT
WITH CHECK (app.is_admin() OR requester_id = app.current_user_id());
```

**Update:** Only target can accept/reject; requester can cancel
```sql
CREATE POLICY follow_requests_update ON app.follow_requests
FOR UPDATE
USING (
  app.is_admin()
  OR (target_id = app.current_user_id() AND status = 'pending')
  OR (requester_id = app.current_user_id() AND status = 'pending')
);
```

---

### Messages & Conversations

**Read:** Only conversation members can view messages
```sql
CREATE POLICY messages_select ON app.messages
FOR SELECT
USING (
  app.is_admin()
  OR EXISTS (
    SELECT 1 FROM app.conversation_members cm
    WHERE cm.conversation_id = messages.conversation_id
      AND cm.user_id = app.current_user_id()
  )
);
```

**Create:** Only via `app.send_message()` function (enforces privacy rules)
```sql
-- Direct INSERT blocked by RLS
-- Users MUST call app.send_message(conversation_id, body)
```

**Delete:** Soft delete only; enforced by triggers
```sql
-- Physical DELETE blocked
-- Updates set deleted_at timestamp
```

---

### Notifications

**Read:** Users can only see their own notifications
```sql
CREATE POLICY notifications_select ON app.notifications
FOR SELECT
USING (app.is_admin() OR user_id = app.current_user_id());
```

**Update:** Users can only mark their own notifications as read
```sql
CREATE POLICY notifications_update_self ON app.notifications
FOR UPDATE
USING (app.is_admin() OR user_id = app.current_user_id());
```

---

## Privacy Functions

### `app.can_view_post(viewer_id, post_id)`
Determines if a user can view a specific post based on:
1. Post visibility (`public` vs `followers`)
2. Account privacy (public vs private)
3. Follow relationship
4. Post ownership

```sql
-- Example implementation
CREATE FUNCTION app.can_view_post(p_viewer uuid, p_post_id bigint)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM app.posts p
    JOIN app.users u ON u.id = p.user_id
    WHERE p.id = p_post_id
      AND (
        -- Own post
        p.user_id = p_viewer
        -- OR post is public
        OR (p.visibility = 'public' AND u.is_private = false)
        -- OR following the user
        OR EXISTS (
          SELECT 1 FROM app.follows f
          WHERE f.follower_id = p_viewer
            AND f.followed_id = p.user_id
        )
      )
  );
$$ LANGUAGE sql STABLE;
```

### `app.can_message(sender_id, receiver_id)`
Determines if a user can send messages to another user:
1. Cannot message yourself
2. If receiver is private, must be following
3. If receiver is public, anyone can message

---

## Security-Definer Functions

These functions run with elevated privileges to enforce complex business logic:

### `app.create_direct_conversation(p_other uuid)`
- Enforces `can_message()` privacy rule
- Prevents duplicate conversations
- Ensures both users are members

### `app.send_message(p_conversation_id bigint, p_body text)`
- Verifies sender is conversation member
- Re-checks `can_message()` for direct messages
- Prevents unauthorized message insertion

### `app.accept_follow_request(p_request_id bigint)`
- Verifies user is the request target
- Creates follow relationship
- Sends notification

---

## Force RLS

All tables have `FORCE ROW LEVEL SECURITY` enabled:
```sql
ALTER TABLE app.users FORCE ROW LEVEL SECURITY;
ALTER TABLE app.posts FORCE ROW LEVEL SECURITY;
-- ... etc
```

This prevents even table owners (superusers) from bypassing RLS unless they explicitly disable the policies.

---

## Permission Matrix

| Resource | Anonymous | Authenticated | Owner | Admin |
|----------|-----------|---------------|-------|-------|
| **Users** | Read (all) | Read (all) | Update (self) | All |
| **Profiles** | Read (all) | Read (all), Create (self) | Update (self) | All |
| **Posts** | Read (public) | Read (visible) | CRUD (own) | All |
| **Likes** | ❌ | Create/Delete (on visible) | - | All |
| **Comments** | ❌ | Create/Update (own), Read (visible) | Delete (own) | All |
| **Follows** | Read (all) | Create/Delete (own) | - | All |
| **Follow Requests** | ❌ | Create (own), Update (own/received) | - | All |
| **Messages** | ❌ | Read (member), Create (via function) | Soft Delete | All |
| **Notifications** | ❌ | Read (own), Update (own) | - | All |

---

## Testing RLS

### Test as specific user
```sql
-- Login as user
CALL app.set_current_user('user-uuid-here');

-- Try to view posts
SELECT * FROM app.posts LIMIT 10;

-- Try to create a post
INSERT INTO app.posts (user_id, caption) 
VALUES (app.current_user_id(), 'Test post');
```

### Test privacy violations
```sql
-- Try to view another user's private post
SELECT * FROM app.posts WHERE user_id != app.current_user_id();

-- Try to update another user's profile (should fail)
UPDATE app.profiles SET bio = 'hacked' 
WHERE user_id != app.current_user_id();
```

### Test admin override
```sql
-- Login as admin
CALL app.set_current_user('admin-uuid', true);

-- Should bypass all RLS
SELECT COUNT(*) FROM app.messages;
UPDATE app.users SET status = 'disabled' WHERE id = 'bad-user-uuid';
```

---

## Security Best Practices

1. **Never expose database credentials** to client applications
2. **Always validate input** in security-definer functions
3. **Use prepared statements** to prevent SQL injection
4. **Audit admin actions** via audit schema/logging
5. **Regularly review RLS policies** for security gaps
6. **Test negative cases** (unauthorized access attempts)
7. **Keep session variables secure** in application layer
8. **Rotate admin credentials** regularly

---

## Future Enhancements

- **JWT-based authentication** (via PostgreSQL extensions like `pgjwt`)
- **Role hierarchy** (moderators, support staff)
- **IP-based rate limiting** (via `pg_stat_statements`)
- **Audit logging** (using triggers to `audit` schema)
- **Two-factor authentication** (session metadata)
