# 📐 Schema Diagrams

This document provides visual representations of the database schema using Entity-Relationship Diagrams (ERD).

## Overview

The MarketplaceDB schema is organized into several functional domains:

1. **Users & Authentication** - User accounts, profiles
2. **Posts & Media** - Content creation, media carousel
3. **Social Graph** - Follows, follow requests
4. **Engagement** - Likes, comments
5. **Messaging** - Direct messages, conversations
6. **Notifications** - Activity notifications

---

## 1. Users & Profiles Domain

```mermaid
erDiagram
    USERS ||--|| PROFILES : "has one"
    
    USERS {
        uuid id PK
        citext email UK
        text username UK
        text password_hash
        boolean is_private
        text status "active|disabled|deleted"
        timestamptz created_at
        timestamptz updated_at
    }
    
    PROFILES {
        uuid user_id PK,FK
        text full_name
        text bio
        text website
        text avatar_url
        int posts_count
        int followers_count
        int following_count
        timestamptz created_at
        timestamptz updated_at
    }
```

**Relationships:**
- One user has exactly one profile (1:1)
- Profile is deleted when user is deleted (CASCADE)

---

## 2. Posts & Media Domain

```mermaid
erDiagram
    USERS ||--o{ POSTS : "creates"
    POSTS ||--o{ POST_MEDIA : "contains"
    
    POSTS {
        bigint id PK
        uuid user_id FK
        text caption
        text visibility "public|followers"
        int likes_count
        int comments_count
        timestamptz created_at
        timestamptz updated_at
    }
    
    POST_MEDIA {
        bigint id PK
        bigint post_id FK
        text media_type "image|video"
        text url
        int position "unique per post"
        timestamptz created_at
    }
```

**Relationships:**
- One user can create many posts (1:N)
- One post can have multiple media items (1:N, carousel)
- Post media is deleted when post is deleted (CASCADE)
- Position ensures ordered carousel (1, 2, 3, ...)

---

## 3. Social Graph Domain

```mermaid
erDiagram
    USERS ||--o{ FOLLOWS_FOLLOWER : "follows"
    USERS ||--o{ FOLLOWS_FOLLOWED : "followed by"
    USERS ||--o{ FOLLOW_REQUESTS_REQ : "requests to follow"
    USERS ||--o{ FOLLOW_REQUESTS_TGT : "receives requests"
    
    FOLLOWS {
        uuid follower_id PK,FK
        uuid followed_id PK,FK
        timestamptz created_at
    }
    
    FOLLOW_REQUESTS {
        bigint id PK
        uuid requester_id FK
        uuid target_id FK
        text status "pending|accepted|rejected|cancelled"
        timestamptz created_at
        timestamptz updated_at
    }
```

**Relationships:**
- Many-to-many relationship between users (via FOLLOWS)
- Follow requests track pending/processed requests for private accounts
- Composite PK on FOLLOWS prevents duplicate follows
- CHECK constraint prevents self-follows

---

## 4. Engagement Domain

```mermaid
erDiagram
    POSTS ||--o{ POST_LIKES : "receives"
    USERS ||--o{ POST_LIKES : "gives"
    POSTS ||--o{ COMMENTS : "receives"
    USERS ||--o{ COMMENTS : "writes"
    COMMENTS ||--o{ COMMENTS : "replies to"
    
    POST_LIKES {
        bigint post_id PK,FK
        uuid user_id PK,FK
        timestamptz created_at
    }
    
    COMMENTS {
        bigint id PK
        bigint post_id FK
        uuid user_id FK
        bigint parent_comment_id FK "nullable"
        text body
        timestamptz created_at
        timestamptz updated_at
    }
```

**Relationships:**
- Many-to-many between users and posts (via POST_LIKES)
- Comments are hierarchical (self-referencing for replies)
- One post can have many comments (1:N)
- One comment can have many replies (1:N, via parent_comment_id)

---

## 5. Messaging Domain

```mermaid
erDiagram
    USERS ||--o{ CONVERSATIONS : "creates"
    CONVERSATIONS ||--o{ CONVERSATION_MEMBERS : "has"
    USERS ||--o{ CONVERSATION_MEMBERS : "participates"
    CONVERSATIONS ||--o{ MESSAGES : "contains"
    USERS ||--o{ MESSAGES : "sends"
    
    CONVERSATIONS {
        bigint id PK
        text kind "direct|group"
        uuid created_by FK "nullable"
        text title "nullable"
        timestamptz created_at
        timestamptz updated_at
    }
    
    CONVERSATION_MEMBERS {
        bigint conversation_id PK,FK
        uuid user_id PK,FK
        text role "member|admin"
        timestamptz joined_at
        bigint last_read_message_id FK "nullable"
    }
    
    MESSAGES {
        bigint id PK
        bigint conversation_id FK
        uuid sender_id FK
        text body
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at "soft delete"
    }
```

**Relationships:**
- One conversation can have many members (1:N)
- One user can be in many conversations (N:N via CONVERSATION_MEMBERS)
- One conversation can have many messages (1:N)
- Messages support soft delete (deleted_at timestamp)

---

## 6. Notifications Domain

```mermaid
erDiagram
    USERS ||--o{ NOTIFICATIONS : "receives"
    
    NOTIFICATIONS {
        bigint id PK
        uuid user_id FK
        text kind "like|comment|follow|follow_request|message"
        uuid actor_id FK "who triggered it"
        bigint entity_id "post_id, comment_id, etc"
        text entity_type "post|comment|follow|message"
        boolean is_read
        timestamptz created_at
    }
```

**Relationships:**
- One user can have many notifications (1:N)
- Notifications reference actors (other users)
- Entity ID + Entity Type provide polymorphic references

---

## Complete Schema Overview

```mermaid
erDiagram
    USERS ||--|| PROFILES : ""
    USERS ||--o{ POSTS : ""
    USERS ||--o{ POST_LIKES : ""
    USERS ||--o{ COMMENTS : ""
    USERS ||--o{ FOLLOWS_FOLLOWER : ""
    USERS ||--o{ FOLLOWS_FOLLOWED : ""
    USERS ||--o{ FOLLOW_REQUESTS : ""
    USERS ||--o{ CONVERSATIONS : ""
    USERS ||--o{ CONVERSATION_MEMBERS : ""
    USERS ||--o{ MESSAGES : ""
    USERS ||--o{ NOTIFICATIONS : ""
    
    POSTS ||--o{ POST_MEDIA : ""
    POSTS ||--o{ POST_LIKES : ""
    POSTS ||--o{ COMMENTS : ""
    
    CONVERSATIONS ||--o{ CONVERSATION_MEMBERS : ""
    CONVERSATIONS ||--o{ MESSAGES : ""
    
    COMMENTS ||--o{ COMMENTS : "parent"
```

---

## Database Schemas (Namespaces)

The database is organized into PostgreSQL schemas:

```mermaid
graph TD
    A[Database: instagram] --> B[Schema: app]
    A --> C[Schema: audit]
    A --> D[Schema: public]
    
    B --> E[Tables: users, posts, messages, etc.]
    B --> F[Functions: can_view_post, send_message, etc.]
    B --> G[Procedures: set_current_user, accept_follow_request]
    
    C --> H[Audit logs future]
    
    D --> I[Extensions: pgcrypto, citext, pg_trgm]
```

**Schema Organization:**
- **app** - All application tables, functions, views
- **audit** - Reserved for audit logging (future)
- **public** - Extensions only

---

## Key Constraints

### Uniqueness Constraints
- `users.email` - Case-insensitive email (via citext)
- `users.username` - Enforced via `lower(username)` index
- `post_media(post_id, position)` - One media per position per post
- `follows(follower_id, followed_id)` - Prevent duplicate follows

### Check Constraints
- `users.username` - Length (3-30 chars) and allowed characters
- `users.status` - Must be 'active', 'disabled', or 'deleted'
- `posts.visibility` - Must be 'public' or 'followers'
- `follows` - follower_id ≠ followed_id (no self-follows)

### Foreign Key Constraints
- All `user_id` references → `app.users(id) ON DELETE CASCADE`
- All `post_id` references → `app.posts(id) ON DELETE CASCADE`
- `comments.parent_comment_id` → `app.comments(id) ON DELETE CASCADE`
- Conversation/message relationships enforce referential integrity

---

## Trigger Summary

### Auto-Update Triggers
- `updated_at` triggers on: users, profiles, posts, comments, messages, etc.
- Ensures `updated_at` is always current

### Counter Triggers
- `posts` - Increment/decrement likes_count, comments_count
- `profiles` - Increment/decrement posts_count, followers_count, following_count
- Ensures denormalized counts stay accurate

### Notification Triggers
- `post_likes` - Notify post owner on new like
- `comments` - Notify post owner on new comment
- `follows` - Notify followed user
- `follow_requests` - Notify target user on new request
- `messages` - Notify conversation members on new message

### Security Triggers
- `messages` - Convert DELETE to UPDATE (soft delete)
- `messages` - Validate sender is conversation member (integrity guard)

---

## Views

### Feed Views
- `app.feed_posts` - Privacy-aware post feed for current user
- Filters based on follows and account privacy

### Analytics Views
(Future implementation)
- User engagement metrics
- Trending content
- Activity summaries

---

## Performance Considerations

### Denormalization
- Counter columns (likes_count, followers_count, etc.)
- Trade-off: Faster reads, slightly slower writes
- Maintained via triggers for consistency

### Soft Deletes
- Messages use `deleted_at` timestamp
- Preserves conversation integrity
- Requires index: `WHERE deleted_at IS NULL`

### Composite Indexes
- `(user_id, created_at)` for feed queries
- `(conversation_id, created_at)` for message retrieval
- Optimizes common query patterns

---

## Migration Strategy

Migrations are numbered sequentially:
1. `001-010` - Core schema setup
2. `020-029` - Posts domain
3. `030-039` - Social graph domain
4. `040-049` - Privacy & feed logic
5. `050-059` - Messaging domain
6. `070-079` - Security & RLS policies

This allows clear separation of concerns and easier rollback if needed.

---

## Visual Schema Tools

For interactive schema exploration, use:
- **pgAdmin** - Built-in ERD tool
- **DBeaver** - ER diagram generation
- **dbdiagram.io** - Online diagram editor
- **SchemaSpy** - Automatic documentation generation

To export schema:
```bash
pg_dump -U postgres -d instagram --schema-only > schema.sql
```

To generate ERD with SchemaSpy:
```bash
java -jar schemaspy.jar -t pgsql -db instagram -u postgres -p password -o output/
```
