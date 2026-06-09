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
