# Design Document: DeoReoNem Product Architecture (Phase 1+)

## Overview

This document is the implementation design for DeoReoNem (덜어냄) — a desktop-first Digital Decompression application. It covers the full product architecture starting from Phase 1: the Spring Boot API server skeleton, PostgreSQL schema, Flutter Windows desktop client, and the REST API that connects them.

The design is organized to guide an implementer through each layer in the order they are built:
- Phase 1: Spring Boot project scaffold, Flyway migrations, Swagger UI, health check
- Phase 2: All 8 session/item REST endpoints with full domain logic
- Phase 3: Flutter desktop shell — all 6 screens scaffolded with static UI
- Phase 4: Dio API client wired to real backend, Riverpod state live end-to-end

Reference documents:
- `docs/02_ARCHITECTURE.md` — component diagram and tech-stack decisions
- `docs/03_API_SPEC.md` — full endpoint definitions (source of truth for the API contract)
- `docs/04_DATA_SPEC.md` — full DDL, trigger DDL, and entity relationships

---

## Architecture

### System Overview

DeoReoNem uses a **client-server architecture** with strict layer boundaries:

```
┌─────────────────────────────────────────────────────────┐
│                 User's Windows Desktop                   │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │            Flutter Desktop App                     │  │
│  │        (apps/deoreonem_desktop)                    │  │
│  │                                                    │  │
│  │  Screens (lib/screens/)                            │  │
│  │       │                                            │  │
│  │  Riverpod Providers (lib/providers/)               │  │
│  │       │                                            │  │
│  │  Dio API Client (lib/api/)                         │  │
│  └────────────────┬───────────────────────────────────┘  │
└───────────────────┼─────────────────────────────────────┘
                    │  HTTP/REST  /api/v1/...
                    │
┌───────────────────▼─────────────────────────────────────┐
│             Spring Boot API Server                       │
│             (server/deoreonem_api)                       │
│                                                          │
│  Controller Layer   (@RestController)                    │
│       │                                                  │
│  Service Layer      (business logic, domain rules)       │
│       │                                                  │
│  MyBatis Mapper Layer  (SQL)                             │
└───────────────────┬─────────────────────────────────────┘
                    │  JDBC / MyBatis
                    │
┌───────────────────▼─────────────────────────────────────┐
│                  PostgreSQL 15+                          │
│    decompression_session  │  decompression_item          │
└──────────────────────────────────────────────────────────┘
```

**Core architecture principle:** Flutter clients MUST NOT access the database directly. All data access goes exclusively through the REST API. This ensures business rules are enforced in one place, the same API can serve a future mobile client, and the schema can evolve independently of client code.

---

## Components and Interfaces

### Monorepo Directory Structure

```
deoreonem/
├── apps/
│   └── deoreonem_desktop/              ← Flutter Windows desktop client
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── main.dart
│       │   ├── screens/
│       │   │   ├── start_screen.dart
│       │   │   ├── dump_input_screen.dart
│       │   │   ├── classification_screen.dart
│       │   │   ├── first_action_screen.dart
│       │   │   ├── entrusted_summary_screen.dart
│       │   │   └── completion_screen.dart
│       │   ├── providers/              ← Riverpod providers
│       │   ├── api/                    ← Dio API client layer
│       │   ├── models/                 ← Dart model classes
│       │   └── widgets/                ← Reusable UI components
│       └── windows/                    ← Windows platform runner
│
├── server/
│   └── deoreonem_api/                  ← Spring Boot 3.x REST API
│       ├── build.gradle
│       ├── settings.gradle
│       ├── src/main/java/com/deoreonem/api/
│       │   ├── DeoreonemApiApplication.java
│       │   ├── controller/
│       │   ├── service/
│       │   ├── mapper/
│       │   ├── domain/                 ← renamed from "model" — plain Java objects
│       │   ├── dto/
│       │   ├── config/
│       │   └── exception/
│       ├── src/main/resources/
│       │   ├── application.yml
│       │   ├── db/migration/           ← Flyway migration SQL files
│       │   └── mapper/                 ← MyBatis XML mapper files
│       └── src/test/java/com/deoreonem/api/
│
├── docs/
│   ├── 00_PRODUCT_SPEC.md
│   ├── 01_DESKTOP_UX_SPEC.md
│   ├── 02_ARCHITECTURE.md
│   ├── 03_API_SPEC.md
│   ├── 04_DATA_SPEC.md
│   └── 05_DEVELOPMENT_PLAN.md
│
├── README.md
├── TASKS.md
├── CHECKPOINT.md
└── WORK_LOG.md
```

### Spring Boot Server — Package Structure

Each package has a single, well-defined responsibility:

| Package | Annotation | Purpose |
|---|---|---|
| `controller/` | `@RestController` | One controller per resource; handles HTTP mapping, delegates to service |
| `service/` | `@Service` | Business logic and domain rule enforcement; no SQL here |
| `mapper/` | `@Mapper` (MyBatis) | MyBatis interfaces; one per domain entity |
| `domain/` | POJO | Plain Java domain objects: `DecompressionSession`, `DecompressionItem` |
| `dto/` | POJO | Request and response DTOs; sub-packages per resource if needed |
| `config/` | `@Configuration` | `CorsConfig`, `SwaggerConfig`, `MyBatisConfig` |
| `exception/` | `@ControllerAdvice` | `GlobalExceptionHandler` + custom exception classes |

The `domain/` package uses the name "domain" rather than "model" to distinguish internal domain objects from DTOs and to follow DDD naming conventions.

### Flutter Client — Package Structure

| Directory | Purpose |
|---|---|
| `lib/screens/` | One file per screen; screen widgets contain only UI and navigation logic |
| `lib/providers/` | Riverpod providers; hold all application state |
| `lib/api/` | `DecompressionApiClient` class; wraps all Dio HTTP calls |
| `lib/models/` | Immutable Dart model classes with `fromJson`/`toJson` |
| `lib/widgets/` | Reusable UI components shared across screens |

---

## Data Models

### Spring Boot Domain Objects (`domain/`)

**`DecompressionSession`**

| Field | Java Type | Notes |
|---|---|---|
| `sessionId` | `UUID` | Maps to `session_id` PK |
| `status` | `String` | `IN_PROGRESS` or `COMPLETED` |
| `firstActionItemId` | `UUID` (nullable) | Soft reference to item |
| `completedAt` | `OffsetDateTime` (nullable) | Set on completion |
| `createdAt` | `OffsetDateTime` | Set at insert |
| `updatedAt` | `OffsetDateTime` | Managed by DB trigger |

**`DecompressionItem`**

| Field | Java Type | Notes |
|---|---|---|
| `itemId` | `UUID` | Maps to `item_id` PK |
| `sessionId` | `UUID` | FK to session |
| `content` | `String` | Max 500 chars |
| `category` | `String` (nullable) | One of 7 enum values or null |
| `sortOrder` | `int` | Assigned at insert; never reordered |
| `createdAt` | `OffsetDateTime` | Set at insert |
| `updatedAt` | `OffsetDateTime` | Managed by DB trigger |

Note: `isFirstAction` is NEVER a field on `DecompressionItem`. It is computed in response DTOs as `item.getItemId().equals(session.getFirstActionItemId())`.

### Request DTOs

| Class | Fields | Used by |
|---|---|---|
| `CreateSessionRequest` | _(empty body, accepted for future extensibility)_ | POST /decompression-sessions |
| `AddItemRequest` | `content: String` | POST .../items |
| `UpdateItemCategoryRequest` | `category: String` | PATCH .../category |
| `SetFirstActionRequest` | `itemId: UUID` | PUT .../first-action |

### Response DTOs

| Class | Key Fields | Used by |
|---|---|---|
| `SessionResponse` | sessionId, status, firstActionItemId, createdAt, updatedAt | POST /decompression-sessions |
| `SessionWithItemsResponse` | SessionResponse fields + `items: List<ItemResponse>` | GET /decompression-sessions/{id} |
| `ItemResponse` | itemId, sessionId, content, category, **isFirstAction**, sortOrder, createdAt, updatedAt | POST .../items, PATCH .../category |
| `SummaryResponse` | sessionId, status, totalItems, firstActionItem, itemsByCategory | GET .../summary |
| `CompleteSessionResponse` | sessionId, status, completedAt | POST .../complete |
| `FirstActionResponse` | sessionId, firstActionItemId | PUT .../first-action |
| `DeleteItemResponse` | deleted: boolean, itemId | DELETE .../items/{itemId} |

### Dart Model Classes (`lib/models/`)

**`SessionModel`**
- `sessionId`, `status`, `firstActionItemId` (nullable), `createdAt`, `updatedAt`
- Factory `fromJson`, `toJson`, immutable with `copyWith`

**`ItemModel`**
- `itemId`, `sessionId`, `content`, `category` (nullable), `isFirstAction`, `sortOrder`, `createdAt`, `updatedAt`
- Factory `fromJson`, `toJson`, immutable with `copyWith`

**`SummaryModel`**
- `sessionId`, `status`, `totalItems`, `firstActionItem` (nullable), `itemsByCategory: Map<String, List<ItemModel>>`
- Factory `fromJson`, `toJson`, immutable with `copyWith`

### Database Schema

#### Migration Files (Flyway)

Migrations live in `src/main/resources/db/migration/` and follow the naming convention `V{version}__{description}.sql`.

| File | Purpose |
|---|---|
| `V1__create_extensions.sql` | `CREATE EXTENSION IF NOT EXISTS pgcrypto;` |
| `V2__create_decompression_session.sql` | DDL for `decompression_session` table |
| `V3__create_decompression_item_and_triggers.sql` | DDL for `decompression_item` table + `updated_at` triggers for both tables |

#### `decompression_session` Table

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `session_id` | UUID | NOT NULL | `gen_random_uuid()` | PK |
| `status` | VARCHAR(20) | NOT NULL | `'IN_PROGRESS'` | CHECK: `IN_PROGRESS` or `COMPLETED` |
| `first_action_item_id` | UUID | NULL | null | Soft reference — no FK constraint (avoids circular dependency) |
| `completed_at` | TIMESTAMPTZ | NULL | null | Set on completion |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | Set at insert |
| `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | Managed by trigger |

#### `decompression_item` Table

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `item_id` | UUID | NOT NULL | `gen_random_uuid()` | PK |
| `session_id` | UUID | NOT NULL | — | FK → `decompression_session` ON DELETE CASCADE |
| `content` | VARCHAR(500) | NOT NULL | — | User's raw text |
| `category` | VARCHAR(20) | NULL | null | CHECK: NULL or one of 7 enum values |
| `sort_order` | INT | NOT NULL | — | Assigned as `MAX(sort_order)+1` at insert |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | Set at insert |
| `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | Managed by trigger |

**Key data invariants:**
- `sort_order` is assigned at insert time and never reordered; items are always returned `ORDER BY sort_order ASC`
- `first_action_item_id` is a soft reference; referential integrity is enforced in the service layer, not via DB FK
- `isFirstAction` is NEVER stored in `decompression_item`; it is computed in the DTO layer
- `DROP` category items are excluded from First Action eligibility (category gate enforced in service)
- A session in `COMPLETED` status cannot have items added, updated, or deleted

#### MyBatis Mapper Interfaces

**`DecompressionSessionMapper`**

| Method | Return | SQL |
|---|---|---|
| `insertSession(DecompressionSession)` | void | INSERT into decompression_session |
| `findById(UUID sessionId)` | DecompressionSession | SELECT by PK |
| `findByIdWithItems(UUID sessionId)` | DecompressionSession | JOIN with decompression_item, items ordered by sort_order |
| `updateStatus(UUID sessionId, String status)` | void | UPDATE status |
| `updateFirstAction(UUID sessionId, UUID itemId)` | void | UPDATE first_action_item_id |
| `updateCompletedAt(UUID sessionId, OffsetDateTime completedAt)` | void | UPDATE completed_at |

**`DecompressionItemMapper`**

| Method | Return | SQL |
|---|---|---|
| `insertItem(DecompressionItem)` | void | INSERT into decompression_item |
| `findById(UUID itemId)` | DecompressionItem | SELECT by PK |
| `findBySessionIdOrderBySortOrder(UUID sessionId)` | List\<DecompressionItem\> | SELECT WHERE session_id ORDER BY sort_order ASC |
| `updateCategory(UUID itemId, String category)` | void | UPDATE category |
| `deleteById(UUID itemId)` | void | DELETE by PK |
| `getMaxSortOrder(UUID sessionId)` | Integer (nullable) | SELECT MAX(sort_order) for session |

SQL for all mapper methods is defined in XML files in `src/main/resources/mapper/`.

---

## REST API Design

### Gradle Dependencies (Phase 1)

The `build.gradle` for `server/deoreonem_api` includes these dependencies:

| Dependency | Purpose |
|---|---|
| `spring-boot-starter-web` | Spring MVC, embedded Tomcat |
| `spring-boot-starter-validation` | Bean Validation (`@NotBlank`, `@Size`, etc.) |
| `mybatis-spring-boot-starter` | MyBatis integration |
| `postgresql` | PostgreSQL JDBC driver |
| `springdoc-openapi-starter-webmvc-ui` | Swagger UI + OpenAPI 3 spec generation |
| `flyway-core` | Database migration management |
| `spring-boot-starter-test` | JUnit 5, Mockito, MockMvc |
| `spring-boot-devtools` | Hot reload during development (optional, `developmentOnly`) |

Spring Security is **not** added to `build.gradle` in MVP 0.1. It is explicitly deferred to Phase 5. Adding it later requires adding the `spring-boot-starter-security` dependency and configuring a `SecurityFilterChain` bean.

### CORS Configuration

Configured in `CorsConfig.java` implementing `WebMvcConfigurer`:

| Setting | Value |
|---|---|
| Allowed origins | `http://localhost` (all ports, for Flutter desktop dev) |
| Allowed methods | `GET, POST, PUT, PATCH, DELETE, OPTIONS` |
| Allowed headers | `*` |
| Credentials | `false` (no auth in MVP 0.1) |

### Health Check Endpoint (Phase 1)

Implemented in a dedicated `HealthController`:

```
GET /api/v1/health
→ 200 OK
{
  "status": "UP",
  "service": "deoreonem-api",
  "version": "0.1.0"
}
```

This is the Phase 1 exit criterion: the endpoint returns 200 and Swagger UI loads at `/swagger-ui.html`.

### Session and Item Endpoints (Phase 2)

All endpoints are under the base path `/api/v1`.

| # | Method | Path | Description |
|---|---|---|---|
| 1 | POST | `/api/v1/decompression-sessions` | Create a new session |
| 2 | GET | `/api/v1/decompression-sessions/{sessionId}` | Get session + items (ordered by sortOrder) |
| 3 | POST | `/api/v1/decompression-sessions/{sessionId}/items` | Add item to session |
| 4 | PATCH | `/api/v1/decompression-sessions/{sessionId}/items/{itemId}/category` | Assign/update item category |
| 5 | PUT | `/api/v1/decompression-sessions/{sessionId}/first-action` | Set First Action item |
| 6 | GET | `/api/v1/decompression-sessions/{sessionId}/summary` | Session summary grouped by category |
| 7 | POST | `/api/v1/decompression-sessions/{sessionId}/complete` | Complete session (terminal state) |
| 8 | DELETE | `/api/v1/decompression-sessions/{sessionId}/items/{itemId}` | Delete item from session |

Full request/response bodies, path parameters, and error tables for each endpoint are defined in `docs/03_API_SPEC.md`.

### Validation Rules

Applied via Bean Validation annotations on request DTOs:

| Field | Rule | Annotation |
|---|---|---|
| `content` | Required, not blank, max 500 chars | `@NotBlank`, `@Size(max=500)` |
| `category` | Required, must be valid Category enum value | `@NotNull` + custom validator |
| `itemId` (SetFirstActionRequest) | Required, valid UUID | `@NotNull` |
| Path parameter UUIDs | Validated at controller level | Return 400 for malformed UUIDs |

---

## Flutter Desktop App Design

### Target Platform

- Windows desktop, primary target for MVP 0.1
- Window size: approximately 480×680px, non-resizable for MVP 0.1
- No system tray, no global shortcut, no auto-launch in MVP 0.1
- No mobile implementation in MVP 0.1

### Screen Inventory (6 Screens)

| Screen | File | API Calls | Purpose |
|---|---|---|---|
| StartScreen | `start_screen.dart` | `POST /decompression-sessions` | Entry point; "Start Session" button creates a new session |
| DumpInputScreen | `dump_input_screen.dart` | `POST .../items` per item | Free-text item entry; "Add" appends item; "Done" navigates forward |
| ClassificationScreen | `classification_screen.dart` | `PATCH .../category` per item | Shows each unclassified item; user taps one of 7 category buttons |
| FirstActionScreen | `first_action_screen.dart` | `PUT .../first-action` | Shows only NOW/TOMORROW/THIS_WEEK items; user selects one |
| EntrustedSummaryScreen | `entrusted_summary_screen.dart` | `GET .../summary`, `POST .../complete` | Grouped summary view; "Complete" button finalizes session |
| CompletionScreen | `completion_screen.dart` | _(none)_ | Static screen showing "오늘은 여기까지 해도 됩니다." — no required CTAs |

### Navigation Flow

Linear navigation — no back-stack in MVP 0.1:

```
StartScreen → DumpInputScreen → ClassificationScreen → FirstActionScreen → EntrustedSummaryScreen → CompletionScreen
```

CompletionScreen may optionally offer a "Start New Session" action that navigates back to StartScreen and resets all providers.

### Riverpod State Management

| Provider | Holds | Lifecycle |
|---|---|---|
| `sessionProvider` | Current `SessionModel` (UUID + status) | Created on `POST /decompression-sessions`; reset on new session |
| `itemsProvider` | `List<ItemModel>` for the session | Updated on every add/patch/delete |
| `classificationProvider` | Tracks which items are classified vs pending | Derived from `itemsProvider` (category != null) |
| `firstActionProvider` | Selected First Action item ID | Set on `PUT .../first-action` |

All providers are invalidated/reset when a new session starts via `ref.invalidate(...)` or a `StateNotifier` reset method.

### Dio API Client (`lib/api/DecompressionApiClient`)

| Setting | Value |
|---|---|
| Base URL | `http://localhost:8080/api/v1` (configurable) |
| Connect timeout | 10 seconds |
| Receive timeout | 30 seconds |
| Interceptors | Request/response logging; error normalization to `ApiException` |

The client wraps all 8 session/item endpoints as typed async methods. HTTP error envelopes (`{ "success": false, "error": {...} }`) are mapped to typed `ApiException` instances by the error normalization interceptor, so callers never deal with raw HTTP error bodies.

---

## Phase Plan

| Phase | Name | Key Deliverables | Exit Criteria |
|---|---|---|---|
| 0 | Documentation & Scaffolding | All 6 docs, monorepo skeleton, TASKS/CHECKPOINT/WORK_LOG | All docs complete, directories created |
| 1 | API Server Skeleton | Spring Boot init, Flyway migrations (V1–V3), Swagger UI, `HealthController` | `GET /api/v1/health` → 200; Swagger UI loads at `/swagger-ui.html` |
| 2 | Backend Decompression Flow | All 8 endpoints, domain rule enforcement, JUnit 5 + jqwik tests | All 8 endpoints pass integration tests; all domain rules verified by property tests |
| 3 | Flutter Desktop Shell | All 6 screens scaffolded, navigation wired, static UI (mock data) | All 6 screens render; navigation flows end-to-end with mock data |
| 4 | Flutter ↔ REST Integration | Dio client wired to real API, Riverpod state hooked up, error handling | Full end-to-end session flow works against local API server |
| 5+ | Deferred | Spring Security, JWT auth, mobile app, AI classification | Not planned for MVP 0.1 |

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

The following properties apply to the Phase 2 backend business logic. Property-based tests are implemented using **jqwik** (Java property-based testing library) in the `src/test/java/` tree. Each test runs a minimum of 100 iterations with randomly generated inputs.

### Property 1: Session state machine is terminal on completion

*For any* decompression session that has been transitioned to COMPLETED status, every mutating operation (add item, update item category, set first action, complete again) SHALL be rejected with `SESSION_ALREADY_COMPLETE`.

**Validates: Requirements 6.1, 6.2**

### Property 2: Item sort_order reflects insertion sequence

*For any* sequence of N items added to an in-progress session, retrieving the session SHALL return the items ordered by `sort_order` with values 1, 2, …, N in ascending order, matching the original insertion sequence.

**Validates: Requirements 7.2**

### Property 3: isFirstAction is consistent with session state

*For any* session and its associated item list, exactly one item SHALL have `isFirstAction = true` when the session's `firstActionItemId` is non-null and equals that item's `itemId`; zero items SHALL have `isFirstAction = true` when `firstActionItemId` is null.

**Validates: Requirements 6.6, 7.6**

### Property 4: First Action eligibility is category-gated

*For any* item, the `setFirstAction` operation SHALL succeed if and only if the item's category is one of `NOW`, `TOMORROW`, or `THIS_WEEK`. Items with any other category value — including `WAITING`, `MEMO`, `WORRY_ONLY`, `DROP`, or null — SHALL be rejected with `FIRST_ACTION_INELIGIBLE`.

**Validates: Requirements 6.1**

### Property 5: Dart model serialization round-trip preserves data

*For any* `ItemModel` or `SessionModel` Dart object, calling `fromJson(model.toJson())` SHALL produce an object equal to the original — all fields preserved, including nullable fields and nested objects.

**Validates: Requirements 6.2** *(Phase 4 — Flutter API client)*

---

## Error Handling

### Backend: Global Exception Handler

`GlobalExceptionHandler` (annotated `@ControllerAdvice`) intercepts all exceptions thrown from controllers and services and converts them to the standard error envelope:

```json
{
  "success": false,
  "error": {
    "code": "SESSION_NOT_FOUND",
    "message": "Session with id '550e8400-...' was not found."
  }
}
```

| Error Code | HTTP Status | Thrown When |
|---|---|---|
| `VALIDATION_ERROR` | 400 | Bean Validation fails on request DTO |
| `SESSION_NOT_FOUND` | 404 | No session found for given sessionId |
| `ITEM_NOT_FOUND` | 404 | No item found for given itemId |
| `SESSION_ALREADY_COMPLETE` | 409 | Mutating operation attempted on COMPLETED session |
| `ITEM_NOT_IN_SESSION` | 400 | Item exists but belongs to a different session |
| `INVALID_CATEGORY` | 400 | category value is not one of the 7 valid enum values |
| `FIRST_ACTION_INELIGIBLE` | 400 | Item category is not NOW, TOMORROW, or THIS_WEEK |
| `INTERNAL_ERROR` | 500 | Unexpected exception |

All custom exception classes live in `com.deoreonem.api.exception`. The `GlobalExceptionHandler` maps each custom exception type to its corresponding error code and HTTP status.

### Flutter: Inline Error Handling

Errors in the Flutter client are displayed as inline, non-alarming messages — no modal dialogs, no crash screens. The `DecompressionApiClient` error normalization interceptor converts HTTP error envelopes to typed `ApiException` instances. Callers receive an `ApiException` with a typed error code and human-readable message, which screens display inline.

- Loading states: inline spinner; action buttons are disabled while a request is in-flight
- Transient errors (network timeout, 5xx): inline error message with a retry button
- Domain errors (e.g., SESSION_ALREADY_COMPLETE): inline message explaining the state; no retry

---

## Testing Strategy

### Backend Unit Tests (Phase 2)

`DecompressionSessionServiceTest` (JUnit 5, Mockito):
- A COMPLETED session rejects `addItem`, `updateCategory`, `setFirstAction`, and `complete` — each returns `SESSION_ALREADY_COMPLETE`
- Setting First Action with an ineligible category throws `FIRST_ACTION_INELIGIBLE` for all ineligible categories: `WAITING`, `MEMO`, `WORRY_ONLY`, `DROP`, and null
- `isFirstAction` is correctly computed as true for exactly the item matching `firstActionItemId` and false for all others
- `sort_order` values for a session with N items are sequential starting at 1

### Mapper Tests (Phase 2)

`@MybatisTest` with a test PostgreSQL instance or embedded Postgres:
- `insertItem` assigns `sort_order = MAX(sort_order) + 1` relative to the session
- `findBySessionIdOrderBySortOrder` returns items strictly ordered by sort_order ASC
- `deleteById` removes exactly the target item; other items in the session are unaffected

### API Integration Tests (Phase 2)

`@SpringBootTest` with `MockMvc` or `TestRestTemplate`:
- Full request/response cycle for each of the 8 endpoints
- Error response envelope shape is correct for every named error code
- `GET .../summary` groups items correctly by category with correct `isFirstAction` flags
- `DROP` items appear in summary but are never eligible as First Action

### Property-Based Tests (Phase 2, jqwik)

Each property test runs a minimum of 100 iterations. Test methods are tagged with:

```
// Feature: deoreonem-project-setup, Property N: <property text>
```

- **Property 1 test** — Generates random sessions, completes them, then attempts each of the 4 mutating operations; verifies all return `SESSION_ALREADY_COMPLETE`
- **Property 2 test** — Generates sequences of 1–50 items for a session; verifies retrieved items have `sort_order` = 1…N in order
- **Property 3 test** — Generates sessions with random item lists and random (or null) `firstActionItemId`; verifies `isFirstAction` count invariant holds for all items
- **Property 4 test** — Generates items with all 7 category values (plus null); verifies `setFirstAction` succeeds iff category ∈ {NOW, TOMORROW, THIS_WEEK}

### Flutter Tests (Phase 4)

Widget tests (one per screen):
- All required UI elements render for the screen's initial state
- Buttons trigger the expected `DecompressionApiClient` calls (verified with mocked Dio)
- Navigation advances to the correct next screen on success

`DecompressionApiClient` unit tests:
- Mock Dio responses; verify correct HTTP method, path, and request body for each of the 8 calls
- Error normalization interceptor maps error envelopes to typed `ApiException` for every error code

**Property 5 test** (Dart, using `dart_test` + custom generator):
- Generates random `ItemModel` and `SessionModel` instances
- Verifies `fromJson(model.toJson()) == model` for all generated instances

### Dual Testing Balance

Unit tests cover specific examples, integration points, and error conditions. Property-based tests handle broad input coverage. Avoid writing redundant unit tests for scenarios already covered by property tests — keep unit tests focused on concrete examples that document intended behavior.

---

## Key Technical Design Decisions

### UUID vs Sequential IDs

UUIDs are safe to expose in API URLs — they carry no sequence information enabling enumeration. `gen_random_uuid()` runs at insert time with no round-trip. The 16-byte storage overhead vs `BIGINT` is irrelevant at MVP scale.

### MyBatis vs JPA/Hibernate

For a small, well-defined schema with 8 endpoints and no complex ORM graph traversal, explicit SQL is easier to reason about, debug, and optimize. JPA's lazy-loading proxy behavior adds unnecessary cognitive overhead for a focused MVP.

### Riverpod vs Provider vs Bloc

Riverpod is the successor to Provider: compile-time safety, no BuildContext dependency for read access, simpler testing. Bloc adds more boilerplate than a 6-screen linear app warrants.

### Authentication Deferral

The core decompression session is entirely local in MVP 0.1 — no multi-user or cross-device requirement. Deferring Spring Security removes JWT middleware, user entity, session ownership, and auth flow from Phase 2, letting it focus entirely on session/item business logic. Authentication is planned for Phase 5.

### `isFirstAction` Computed vs Stored

Storing `is_first_action` as a boolean column would require updating multiple rows on every First Action change (clear old, set new). Storing only `first_action_item_id` on `decompression_session` means a single-row update. The DTO computation is trivial: `item.itemId == session.firstActionItemId`.

### `sort_order` Explicit Column

Relying on `created_at` for ordering introduces millisecond-level collision risk and is non-obvious in the schema. An explicit `sort_order INT NOT NULL` makes ordering intent clear and deterministic. It is assigned as `MAX(sort_order) + 1` at insert time and never reordered.

### `updated_at` via Trigger

PostgreSQL does not support `ON UPDATE CURRENT_TIMESTAMP`. A `BEFORE UPDATE` trigger (`set_updated_at()`) on each table is the idiomatic PostgreSQL solution. The trigger DDL is included in `V3__create_decompression_item_and_triggers.sql`.

### `domain/` Package Name

The Java package is named `domain/` rather than `model/` to clearly distinguish internal domain objects from DTOs and to use conventional DDD terminology. This prevents confusion between `ItemResponse` (a DTO) and `DecompressionItem` (the domain object).
