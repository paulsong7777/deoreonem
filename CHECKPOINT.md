# DeoReoNem — Checkpoint Log

> Record each major phase milestone here when it is completed.
> Include: what was done, what decisions were made, current state of the project, and what comes next.

---

## Template

```
## Checkpoint: Phase N — [Phase Name]
**Date:** YYYY-MM-DD
**Status:** ✅ Complete

### What Was Completed
- ...

### Key Decisions Made
- ...

### Current Project State
- ...

### Known Issues / Open Questions
- ...

### What Comes Next
- Phase N+1: [description]
```

---

## Checkpoint: Phase 0 — Documentation & Scaffolding

**Date:** 2026-06-09
**Status:** ✅ Complete

### What Was Completed

- Monorepo directory structure established
- Full product and architecture documentation written:
  - `README.md` — project overview, stack, MVP scope
  - `docs/00_PRODUCT_SPEC.md` — product concept, session flow, item categories
  - `docs/01_DESKTOP_UX_SPEC.md` — screen-by-screen UX specification
  - `docs/02_ARCHITECTURE.md` — component architecture, API principles
  - `docs/03_API_SPEC.md` — full REST API endpoint contracts (paths: `/api/v1/decompression-sessions`)
  - `docs/04_DATA_SPEC.md` — PostgreSQL schema for `decompression_session` and `decompression_item`
  - `docs/05_DEVELOPMENT_PLAN.md` — phased implementation plan
- Kiro spec created: `.kiro/specs/deoreonem-project-setup/requirements.md`
- Task tracker, checkpoint log, and work log initialized
- All open technical decisions resolved (see below)

### Key Decisions Made

- **Architecture:** Flutter clients never access DB directly; all data flows through Spring Boot REST API
- **API versioning:** URL-based versioning under `/api/v1`
- **API base path:** `/api/v1/decompression-sessions` (renamed for clarity)
- **Table names:** `decompression_session`, `decompression_item` (renamed for clarity)
- **Item categories:** 7 fixed categories: `NOW`, `TOMORROW`, `THIS_WEEK`, `WAITING`, `MEMO`, `WORRY_ONLY`, `DROP`
- **Authentication:** Spring Security deferred to post-MVP
- **Primary UX target:** Windows desktop (Flutter), small compact window (~480×680px)
- **Monorepo structure:** `apps/` for Flutter clients, `server/` for Spring Boot API, `docs/` for documentation
- **Database:** PostgreSQL 15+
- **Build tool:** Gradle
- **Primary key strategy:** UUID (native PostgreSQL `UUID` type)
- **Flutter state management:** Riverpod
- **First Action persistence:** `first_action_item_id` on `decompression_session`; `is_first_action` removed from DB, computed in response DTOs
- **Item sort order:** `sort_order INT NOT NULL` added to `decompression_item` to preserve entry order
- **Timestamps:** `TIMESTAMPTZ` (PostgreSQL); `updated_at` managed via trigger (no MySQL `ON UPDATE` syntax)
- **Next-day review:** No global user-based review API in MVP 0.1 (authentication deferred); client may store last sessionId locally

### Current Project State

- No product code written
- All documentation complete and decisions resolved
- Ready to begin Phase 1: API Server Skeleton

### What Comes Next

- **Phase 1:** Spring Boot project scaffold (Gradle), PostgreSQL connection, schema migration, Swagger UI verification

---

## Checkpoint: Phase 1 — API Server Skeleton

**Date:** 2026-06-10
**Status:** ✅ Complete

### What Was Completed

- Spring Boot 3.3.5 project scaffolded under `server/deoreonem_api`
- Gradle 8.10.2 wrapper installed (real JAR, scripts)
- Java 21 confirmed
- All dependencies resolved: Spring Boot Web, Validation, MyBatis, PostgreSQL, Flyway (10.10.0 via BOM), springdoc-openapi 2.5.0
- Package structure created: `controller/`, `service/`, `mapper/`, `domain/`, `dto/`, `config/`, `exception/`
- `application.yml` with default + test profiles
- Flyway migrations: V1 (pgcrypto), V2 (decompression_session), V3 (decompression_item + triggers) — all execute successfully
- `CorsConfig.java` — allows `http://localhost*` origins for `/api/**`
- `SwaggerConfig.java` — OpenAPI 3 bean: title "DeoReoNem API", version 0.1.0
- `ApiException.java` — base runtime exception with errorCode + httpStatus
- `ErrorCode.java` — all 8 named error code constants
- `ErrorResponse.java` — standard error envelope DTO
- `GlobalExceptionHandler.java` — `@ControllerAdvice` skeleton handling ApiException, validation errors, and catch-all
- `HealthController.java` — `GET /api/v1/health` returns `{ status: UP, service: deoreonem-api, version: 0.1.0 }`
- `HealthControllerTest.java` — `@WebMvcTest` verifying health endpoint returns 200 with correct fields
- **Live verification complete:**
  - PostgreSQL Docker container running
  - `bootRun` succeeds
  - Flyway migrations execute successfully (3 migrations applied)
  - Swagger UI accessible at `http://localhost:8080/swagger-ui/index.html`
  - `GET /api/v1/health` returns 200 with `{"status":"UP","service":"deoreonem-api","version":"0.1.0"}`

### Key Decisions Made

- **Spring Boot 3.3.5** (upgraded from 3.2.5) — required for Flyway 10.x `flyway-database-postgresql` module
- **Gradle 8.10.2** — matches locally cached distribution
- **`@WebMvcTest`** used for HealthControllerTest — avoids needing a running database for controller tests
- **`flyway-database-postgresql` as `runtimeOnly`** — Flyway 10.x modular design separates DB-specific dialects from core
- **PostgreSQL via Docker** for local development

### Current Project State

- Phase 1 exit criteria met: server starts, tests pass, Swagger UI accessible, health endpoint returns 200
- Spring Boot API skeleton is ready for Phase 2 business logic
- No decompression session or item logic implemented yet

### Known Issues / Open Questions

- None. All Phase 1 blockers resolved.

### What Comes Next

- **Phase 2:** Implement all 8 decompression session/item REST endpoints with domain rules, MyBatis mappers, service layer, and tests

---

## Checkpoint: Phase 2 — Backend Decompression Flow

**Date:** 2026-06-10
**Status:** ✅ Complete

### What Was Completed

- Domain objects: `DecompressionSession`, `DecompressionItem`, `Category` enum (validation + first-action eligibility)
- Custom exception classes (6): `SessionNotFoundException`, `ItemNotFoundException`, `SessionAlreadyCompleteException`, `ItemNotInSessionException`, `InvalidCategoryException`, `FirstActionIneligibleException`
- Request DTOs: `AddItemRequest`, `UpdateCategoryRequest`, `SetFirstActionRequest`
- Response DTOs: `ApiResponse<T>`, `SessionResponse`, `ItemResponse`, `SummaryResponse`, `CompleteSessionResponse`, `FirstActionResponse`, `DeleteItemResponse`, `ReviewResponse`
- MyBatis mappers: `DecompressionSessionMapper` + `DecompressionItemMapper` (interfaces + XML)
- Service layer: `DecompressionSessionService` with 7 methods and all business rule enforcement
- Controller: `DecompressionSessionController` with 7 REST endpoints
- Tests: 28 total (16 service unit tests + 10 controller tests + 2 health tests) — ALL PASS

### Endpoints Implemented

| Method | Path | HTTP Status |
|---|---|---|
| POST | `/api/v1/decompression-sessions` | 201 Created |
| POST | `/api/v1/decompression-sessions/{sessionId}/items` | 201 Created |
| PATCH | `/api/v1/decompression-items/{itemId}/category` | 200 OK |
| PATCH | `/api/v1/decompression-sessions/{sessionId}/first-action` | 200 OK |
| POST | `/api/v1/decompression-sessions/{sessionId}/complete` | 200 OK |
| GET | `/api/v1/decompression-sessions/{sessionId}/summary` | 200 OK |
| GET | `/api/v1/decompression-sessions/{sessionId}/review` | 200 OK |

### Business Rules Enforced

- Completed sessions reject all mutations → `SESSION_ALREADY_COMPLETE` (409)
- `first_action_item_id` must belong to same session → `ITEM_NOT_IN_SESSION` (400)
- First Action eligibility: only NOW/TOMORROW/THIS_WEEK → `FIRST_ACTION_INELIGIBLE` (400)
- Category validation: only 7 valid values → `INVALID_CATEGORY` (400)
- `sort_order` assigned as MAX+1 at insert time
- `isFirstAction` computed in DTOs, never stored in DB
- DROP items excluded from review endpoint

### Key Decisions Made

- **`Category` enum** with static validation methods rather than a plain constant class — cleaner for eligibility checks
- **`PATCH` for category and first-action** rather than PUT — partial update semantics
- **`ReviewResponse`** as separate endpoint for next-day review (excludes DROP items)
- **`@WebMvcTest` for controller tests** — fast, no DB needed; service layer mocked

### Current Project State

- Phase 2 complete: all 7 decompression endpoints implemented with full domain rules
- 28 tests pass (`./gradlew.bat test --no-daemon` → BUILD SUCCESSFUL)
- Ready for Phase 3: Flutter desktop shell

### Known Issues / Open Questions

- No `DELETE` endpoint implemented (not in the user's current endpoint list for Phase 2)
- Mapper tests (`@MybatisTest`) not written — would require embedded/test PostgreSQL container

### What Comes Next

- **Phase 3:** Flutter desktop shell — 6 screens with static UI, linear navigation

---

## Checkpoint: Phase 3 — Flutter Desktop Shell

**Date:** 2026-06-10
**Status:** ✅ Complete

### What Was Completed

- Flutter project created at `apps/deoreonem_desktop` (Flutter 3.41.1, Dart 3.11.0)
- Windows desktop target configured: 480×680px, non-resizable, title "덜어냄"
- Dependencies: `flutter_riverpod ^2.6.1`, `dio ^5.7.0`, `go_router ^14.6.2`
- App theme with warm color palette from `docs/01_DESKTOP_UX_SPEC.md`
- GoRouter linear navigation: `/` → `/dump` → `/classify` → `/first-action` → `/summary` → `/complete`
- All 6 screens implemented with static mock data and Korean UI copy:
  - StartScreen: app name, subtitle, start button, version footer
  - DumpInputScreen: text input, add/remove local items, disabled next when empty
  - ClassificationScreen: one-at-a-time layout, 7 category buttons, progress indicator
  - FirstActionScreen: eligible items with radio selection, skip option
  - EntrustedSummaryScreen: items grouped by category, first action highlight, total count
  - CompletionScreen: "오늘은 여기까지 해도 됩니다." + close button, no extra CTAs
- Widget tests: 7 tests across 6 screen test files — ALL PASS

### Key Decisions Made

- **go_router** for navigation — simplest option for a linear flow without deep linking
- **One-at-a-time classification** (Option A from UX spec) — keeps the 480px window uncluttered
- **No `window_manager` dependency** — used `windows/runner/main.cpp` modifications for window size and title
- **Mock data hardcoded in screens** — no Riverpod state management or API calls until Phase 4
- **`SystemNavigator.pop()`** for close button — simplest app exit for desktop

### Current Project State

- Phase 3 complete: 6 screens render with static UI, linear navigation works, tests pass
- No real API integration yet (Phase 4)
- Backend (Phase 2) remains unchanged and operational

### Known Issues / Open Questions

- Windows native build not verified (requires Visual Studio C++ toolchain installed)
- Dart model classes and API client deferred to Phase 4
- Loading states and error handling deferred to Phase 4

### What Comes Next

- **Phase 4:** Wire Flutter client to live REST API via Dio + Riverpod providers

---

## Checkpoint: Phase 4 — Flutter ↔ REST Integration

**Date:** 2026-06-10
**Status:** ✅ Complete (code + tests)

### What Was Completed

- Dart API models: `SessionModel`, `ItemModel`, `SummaryModel` with `fromJson`/`toJson`/`copyWith`
- API exception class: `ApiException` with code, message, statusCode
- `DecompressionApiService` — Dio-based service wrapping all 6 backend endpoints with error normalization
- Riverpod providers: `apiServiceProvider`, `sessionProvider` (StateNotifier), `itemsProvider` (StateNotifier), `summaryProvider` (StateNotifier)
- All 6 screens updated to use providers and real API calls:
  - StartScreen → creates session
  - DumpInputScreen → adds items
  - ClassificationScreen → updates category per item
  - FirstActionScreen → sets first action
  - EntrustedSummaryScreen → loads summary + completes session
  - CompletionScreen → static (no API call)
- Loading indicators and error handling (inline messages, retry, disabled buttons)
- 34 Flutter tests pass (3 model + 7 API service + 6 provider + 6 screen + 12 existing)
- Dev dependencies added: `http_mock_adapter`, `mocktail`

### Key Decisions Made

- **Dio injection** via constructor for testability — service accepts optional Dio instance
- **AsyncValue** from Riverpod for loading/error/data states — maps cleanly to UI
- **Error normalization interceptor** in `_request` method — parses backend error envelope or wraps DioException
- **No getReview integration in UI** — review endpoint exists but not wired to any screen in MVP 0.1 (would require a separate "next day" screen)
- **CompletionScreen stays static** — completeSession called from EntrustedSummaryScreen before navigation

### Current Project State

- Full Flutter ↔ REST integration complete
- 34 Flutter tests + 28 backend tests all pass
- End-to-end session flow: Start → Dump → Classify → First Action → Summary → Complete
- Manual verification with live backend pending (requires VS build tools + running PostgreSQL Docker)

### Known Issues / Open Questions

- **PostgreSQL not running** — RESOLVED: Docker container running, Flyway migrations applied
- **Windows build** — FIXED: Korean title → Unicode escapes; `flutter build windows` succeeds
- **MyBatis UUID TypeHandler** — FIXED: custom `UuidTypeHandler` registered; bootRun succeeds
- **ClassificationScreen crash** — FIXED: API path mismatch + empty-list guard added
- `getReview` endpoint not wired to UI (no "next day review" screen in MVP 0.1)
- Full live verification achieved: backend starts, health returns 200, Flutter builds and runs

### What Comes Next

- Manual end-to-end verification with backend running
- Visual polish pass
- Edge case handling (empty session, server errors)
- Windows distributable build
- README update with full setup instructions
