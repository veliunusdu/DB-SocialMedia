
 MarketplaceDB

A production-grade PostgreSQL backend architecture for a social marketplace platform.
Designed with strict Row-Level Security (RLS), role isolation, messaging integrity, and trigger-based domain logic.

This project demonstrates advanced database engineering patterns using pure PostgreSQL.

 Project Overview

MarketplaceDB is a database-first backend implementation of a social marketplace platform with features similar to:

Instagram-style posts

Private accounts

Follow / follow-request flow

Direct messaging system

Notifications engine

Feed views

Analytics queries

All business logic, security, and integrity rules are implemented at the database layer.

No ORM magic.
No framework shortcuts.
Just solid PostgreSQL engineering.

 Core Features
 Row-Level Security (RLS)

Multi-tenant isolation

Users can only see their own notifications

Conversation members can only see their own messages

Admin override support

FORCE ROW LEVEL SECURITY enabled

 Direct Messaging Engine

Direct conversations

Conversation membership control

Message notifications via triggers

Integrity constraints preventing unauthorized inserts

Guardrails against invalid deletion

 Social Graph

Follow system

Follow request flow (for private accounts)

Unique constraints for pending requests

Trigger-based notification creation

 Feed System

Privacy-aware feed views

Public/private filtering

Optimized with proper indexing strategy

 Analytics & Reporting

Trending queries

Performance explain plans

Structured reporting queries

 Architecture Philosophy

This project follows a database-centric architecture:

Business logic lives in SQL functions & procedures

Security is enforced with RLS policies

Integrity is protected with constraints + triggers

Application role is minimal (app_user)

Session identity is managed using custom session variables

 Security Model
Roles

postgres → superuser (infrastructure)

app_user → application role

Session Identity

User context is set using:

CALL app.set_current_user(<uuid>, <is_admin>);


This writes to:

app.current_user_id
app.is_admin


RLS policies reference these session variables.

RLS Enforcement

All critical tables use:

ENABLE ROW LEVEL SECURITY;
FORCE ROW LEVEL SECURITY;


Policies include:

users_select

posts_select

messages_select_member

notifications_select_self

follow_requests_update_target

etc.

 Project Structure
marketplaceDB/
├─ docker/
│  ├─ docker-compose.yml
│  └─ init.sql
├─ migrations/
│  ├─ 001_extensions.sql
│  ├─ ...
│  ├─ 070_security_helpers.sql
│  ├─ 071_rls_enable.sql
│  ├─ 072_rls_policies.sql
│  ├─ 073_grants.sql
│  ├─ 074_messages_rls_tighten.sql
│  ├─ 075_force_rls.sql
│  ├─ 076_conversation_integrity.sql
│  └─ 077_message_delete_guard.sql
├─ seeds/
├─ tests/
├─ reports/
├─ docs/
└─ scripts/

 How To Run
1️⃣ Start Database
cd docker
docker compose up -d

2️⃣ Apply Migrations
cd ..
.\scripts\migrate.ps1

3️⃣ Run RLS Tests
docker compose exec -T postgres psql -U app_user -d instagram -f /tmp_rls_test.sql

🧪 Testing Strategy

The project includes:

Constraint tests

Trigger tests

Procedure tests

Security tests (RLS isolation)

Tests simulate different users by switching session context using:

CALL app.set_current_user(...)

 Performance Considerations

Composite indexes for feed queries

GIN index for text search (pg_trgm)

Indexes for follower relationships

Indexes for notification unread filtering

See:

docs/indexing_strategy.md
reports/explain_plans.sql

🛡 Guardrails Implemented

Unique constraint for pending follow requests

Message integrity checks

Conversation membership enforcement

FORCE RLS on sensitive tables

Session-level identity persistence

🎯 Why This Project Matters

This repository demonstrates:

Advanced PostgreSQL usage

Real-world RLS implementation

Database-first architecture

Security-driven design

Production-grade guardrails

It is intended as a backend engineering portfolio project.

🏁 Future Improvements

Partitioning for large-scale posts/messages

Background job simulation

Rate limiting layer

Full-text search ranking

Soft-delete audit log extension
