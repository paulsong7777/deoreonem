# DeoReoNem — Data Specification

**Version:** 0.1 (MVP)
**Last Updated:** 2026-06-09

---

## 1. Overview

All persistent data is stored in **PostgreSQL 15+**. The database is accessed exclusively by the Spring Boot API Server via MyBatis. No client application accesses the database directly.

---

## 2. Primary Key Strategy

**Decision:** UUID — PostgreSQL native `UUID` type.

UUIDs are safe to expose in API URLs and responses. They require no database round-trip to generate and carry no sequence information.

All primary keys use `UUID NOT NULL DEFAULT gen_random_uuid()`.

> The first migration file must include the following before any table that uses `gen_random_uuid()`:
> ```sql
> CREATE EXTENSION IF NOT EXISTS pgcrypto;
> ```
> This is required on PostgreSQL versions below 13. On PostgreSQL 13+, `gen_random_uuid()` is built-in, but including this line is harmless and ensures compatibility.

---

## 3. Table: `decompression_session`

Stores one row per decompression session initiated by a user.

```sql
CREATE TABLE decompression_session (
    session_id             UUID         NOT NULL DEFAULT gen_random_uuid(),
    status                 VARCHAR(20)  NOT NULL DEFAULT 'IN_PROGRESS',
    first_action_item_id   UUID         NULL,
    completed_at           TIMESTAMPTZ  NULL,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_decompression_session PRIMARY KEY (session_id),
    CONSTRAINT chk_decompression_session_status CHECK (status IN ('IN_PROGRESS', 'COMPLETED'))
);
```

> `updated_at` is kept current via a trigger (see Section 6).

### Column Definitions

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `session_id` | UUID | NOT NULL | `gen_random_uuid()` | Primary key |
| `status` | VARCHAR(20) | NOT NULL | `IN_PROGRESS` | Session state. One of: `IN_PROGRESS`, `COMPLETED` |
| `first_action_item_id` | UUID | NULL | null | Soft reference to `decompression_item.item_id`. The user's chosen First Action. Nullable until set. |
| `completed_at` | TIMESTAMPTZ | NULL | null | Timestamp when session was completed. Null until completion. |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | When the session was started |
| `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | Last update time. Managed by trigger. |

### Notes
- `first_action_item_id` is a soft reference (no hard FK constraint in MVP to avoid circular dependency). Integrity is enforced at the service layer.
- `status` transitions: `IN_PROGRESS` → `COMPLETED` only. Completed sessions cannot revert.
- `isFirstAction` in API response DTOs is **computed** by comparing `itemId == firstActionItemId`. It is not stored in `decompression_item`.

---

## 4. Table: `decompression_item`

Stores one row per item (thought, worry, task, or memo) within a session.

```sql
CREATE TABLE decompression_item (
    item_id     UUID         NOT NULL DEFAULT gen_random_uuid(),
    session_id  UUID         NOT NULL,
    content     VARCHAR(500) NOT NULL,
    category    VARCHAR(20)  NULL,
    sort_order  INT          NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_decompression_item PRIMARY KEY (item_id),
    CONSTRAINT fk_decompression_item_session
        FOREIGN KEY (session_id)
        REFERENCES decompression_session(session_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_decompression_item_category CHECK (
        category IS NULL
        OR category IN ('NOW', 'TOMORROW', 'THIS_WEEK', 'WAITING', 'MEMO', 'WORRY_ONLY', 'DROP')
    )
);

CREATE INDEX idx_decompression_item_session_id ON decompression_item (session_id);
```

> `updated_at` is kept current via a trigger (see Section 6).

### Column Definitions

| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `item_id` | UUID | NOT NULL | `gen_random_uuid()` | Primary key |
| `session_id` | UUID | NOT NULL | — | FK to `decompression_session.session_id`. Which session this item belongs to. |
| `content` | VARCHAR(500) | NOT NULL | — | The user's raw text: the thought, worry, or task |
| `category` | VARCHAR(20) | NULL | null | Classification. Null until assigned. One of the 7 valid values or null. |
| `sort_order` | INT | NOT NULL | — | Preserves the order in which the user entered items. Assigned sequentially (1, 2, 3, …) at insert time. |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | When the item was added |
| `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | Last update time. Managed by trigger. |

### Notes
- `category` is nullable — items start with no category and are classified during the session.
- `is_first_action` is **not stored** in the database. The API service layer computes `isFirstAction` in response DTOs by comparing `item_id` with `decompression_session.first_action_item_id`.
- `sort_order` is assigned at insert time (e.g., `MAX(sort_order) + 1` for the session). Items are returned ordered by `sort_order ASC`.
- `ON DELETE CASCADE` ensures items are removed when their parent session is deleted.
- The index on `session_id` optimizes the common query: "get all items for session X, ordered by sort_order".

---

## 5. Category Enum Values

The `category` column in `decompression_item` accepts exactly these values (or NULL before classification):

| Value | Description |
|---|---|
| `NOW` | Must be handled tonight, before sleeping |
| `TOMORROW` | Intentionally saved for the next workday |
| `THIS_WEEK` | Belongs somewhere in the current week |
| `WAITING` | Blocked on someone else or an external event |
| `MEMO` | Worth remembering but no action required |
| `WORRY_ONLY` | A worry with no actionable resolution today |
| `DROP` | Discarded intentionally — not worth carrying forward |

---

## 6. `updated_at` Trigger

PostgreSQL does not support `ON UPDATE CURRENT_TIMESTAMP`. An `updated_at` trigger is required for both tables.

```sql
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decompression_session_updated_at
    BEFORE UPDATE ON decompression_session
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_decompression_item_updated_at
    BEFORE UPDATE ON decompression_item
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

---

## 7. Entity Relationships

```
decompression_session 1 ──── N decompression_item
          │                             │
          │  first_action_item_id       │
          │  (soft ref, no FK)          │
          └────────────────────────────►│
                                     item_id
```

- One session has zero or more items.
- One item belongs to exactly one session.
- One session has at most one First Action, tracked via `first_action_item_id` on `decompression_session`.
- `isFirstAction` in API responses is computed: `item.item_id == session.first_action_item_id`.

---

## 8. MyBatis Mapper Interfaces (Planned)

During Phase 1/2 implementation, the following MyBatis mapper interfaces will be created:

| Interface | Key Methods |
|---|---|
| `DecompressionSessionMapper` | `insertSession`, `findById`, `updateStatus`, `updateFirstAction`, `updateCompletedAt` |
| `DecompressionItemMapper` | `insertItem`, `findById`, `findBySessionIdOrderBySortOrder`, `updateCategory`, `deleteById`, `getMaxSortOrder` |

SQL will be defined in XML mapper files under `src/main/resources/mapper/`.

---

## 9. Next-Day Review (MVP 0.1 Scope Note)

Since user authentication is deferred past MVP 0.1, there is no server-side user-scoped session listing endpoint in this phase.

The desktop client may persist the last completed `sessionId` locally (e.g., in shared preferences or a local file) and use `GET /api/v1/decompression-sessions/{sessionId}/summary` to reopen that session summary.

User-based review endpoints (`GET /api/v1/decompression-sessions` with auth) are deferred until Spring Security is introduced.

---

## 10. Future Schema Additions (Post-MVP)

| Addition | Description |
|---|---|
| `users` table | User accounts for authentication (Spring Security phase) |
| `user_id` FK on `decompression_session` | Associate sessions with a user |
| Soft deletes | `deleted_at` on `decompression_item` to support undo |
| Tags | Many-to-many tags on items for richer classification |
| Recurring items | Template sessions or carried-over items |
