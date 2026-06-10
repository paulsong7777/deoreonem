# DeoReoNem — Work Log

> Log each work session here. Keep it brief but honest.
> Purpose: maintain continuity, track momentum, and record context for future sessions.

---

## Template

```
## YYYY-MM-DD

**Session duration:** ~Xh
**Phase:** Phase N

### Done
- ...

### Next
- ...

### Blockers / Notes
- ...
```

---

## 2026-06-10 (session 5)

**Session duration:** ~2h
**Phase:** Phase 4 — Flutter ↔ REST Integration

### Done

- Added Dart models: `SessionModel`, `ItemModel`, `SummaryModel` (fromJson/toJson/copyWith)
- Added `ApiException` and `DecompressionApiService` (Dio-based, 6 endpoints, error normalization)
- Added Riverpod providers: `apiServiceProvider`, `sessionProvider`, `itemsProvider`, `summaryProvider`
- Updated all 6 screens to use real providers + API calls:
  - StartScreen creates session on "시작하기"
  - DumpInputScreen adds items to real session
  - ClassificationScreen updates item categories one-at-a-time
  - FirstActionScreen sets first action for eligible items
  - EntrustedSummaryScreen loads summary and completes session
  - CompletionScreen stays static
- Added loading indicators and inline Korean error messages with retry
- Added dev dependencies: `http_mock_adapter`, `mocktail`
- Wrote 27 new tests: 3 model + 7 API service + 6 provider + 6 updated screen tests
- `flutter test` → 34 tests passed ✅

### Next

- Manual end-to-end verification with live backend
- Visual polish and edge case handling
- Windows build verification
- README setup instructions update

### Blockers / Notes

- Windows native build not verified (needs Visual Studio C++ Desktop workload)
- Manual e2e test needs: PostgreSQL Docker + Spring Boot running + Flutter Windows build
- `getReview` endpoint not wired to UI — no "next day review" screen in MVP 0.1
- **2026-06-10 verification attempt:**
  - PostgreSQL: RUNNING (Docker, port 5432) ✅
  - Flyway: migrations applied (schema up to date) ✅
  - MyBatis UUID fix: `UuidTypeHandler` registered ✅
  - `./gradlew.bat test --no-daemon`: BUILD SUCCESSFUL (28 tests) ✅
  - `./gradlew.bat bootRun --no-daemon`: started on port 8080 in 5.6s ✅
  - `GET /api/v1/health`: 200 `{"status":"UP","service":"deoreonem-api","version":"0.1.0"}` ✅
  - Visual Studio: Installed; `flutter build windows` succeeds ✅
  - `flutter test`: 34 tests pass ✅
  - `flutter build windows`: BUILD SUCCESSFUL ✅
  - Windows title encoding: Fixed (Unicode escapes) ✅

---

## 2026-06-10 (session 4)

**Session duration:** ~1.5h
**Phase:** Phase 3 — Flutter Desktop Shell

### Done

- Created Flutter project at `apps/deoreonem_desktop` (replaced .gitkeep)
- Configured `pubspec.yaml`: flutter_riverpod, dio, go_router
- Windows runner: title "덜어냄", 480×680px, non-resizable
- Created `lib/theme.dart` with warm color palette from UX spec
- Created `lib/router.dart` with go_router linear navigation (6 routes)
- Updated `lib/main.dart` with ProviderScope + MaterialApp.router
- Implemented all 6 screens with static mock data:
  - StartScreen, DumpInputScreen, ClassificationScreen
  - FirstActionScreen, EntrustedSummaryScreen, CompletionScreen
- Korean UI copy matches `docs/01_DESKTOP_UX_SPEC.md`
- Created 6 widget test files (7 test cases total)
- `flutter test` → 7 tests passed ✅

### Next

- Begin Phase 4: Wire Dio API client + Riverpod providers to real backend
- Create Dart model classes (SessionModel, ItemModel, SummaryModel)
- Replace mock data with real API responses

### Blockers / Notes

- Windows native build not verified (Visual Studio C++ toolchain needed)
- No real API calls in Phase 3 — all mock/local state
- dio and flutter_riverpod dependencies added but unused until Phase 4

---

## 2026-06-10 (session 3)

**Session duration:** ~2h
**Phase:** Phase 2 — Backend Decompression Flow

### Done

- Implemented entire Phase 2 backend:
  - Domain: `DecompressionSession`, `DecompressionItem`, `Category` enum
  - Exceptions: 6 custom exception classes extending `ApiException`
  - DTOs: 3 request + 8 response classes (including generic `ApiResponse<T>` envelope)
  - MyBatis: 2 mapper interfaces + 2 XML mapper files (full SQL)
  - Service: `DecompressionSessionService` with 7 methods and all business rules
  - Controller: `DecompressionSessionController` with 7 REST endpoints
  - Tests: `DecompressionSessionServiceTest` (16 tests) + `DecompressionSessionControllerTest` (10 tests)
- Ran `./gradlew.bat test --no-daemon`: BUILD SUCCESSFUL (28 tests, 0 failures)
- All business rules verified through unit tests:
  - Completed session guard
  - sort_order assignment
  - Category validation
  - First Action eligibility gate
  - Item-session ownership check
  - DROP exclusion from review
  - isFirstAction computed in DTO

### Next

- Begin Phase 3: Flutter desktop shell (6 screens, static UI, navigation)

### Blockers / Notes

- No blockers. Phase 2 complete.
- Mapper tests (`@MybatisTest`) deferred — would need embedded Postgres or Testcontainers
- DELETE item endpoint not in user's current Phase 2 scope

---

## 2026-06-10 (session 2)

**Session duration:** ~30min
**Phase:** Phase 1 — API Server Skeleton (Exit Verification)

### Done

- Started PostgreSQL via Docker (`postgres:15`, port 5432, db=deoreonem)
- Ran `./gradlew.bat bootRun --no-daemon`: server starts successfully
- Flyway applied all 3 migrations (V1 pgcrypto, V2 session table, V3 item table + triggers)
- Verified Swagger UI at `http://localhost:8080/swagger-ui/index.html` — loads correctly
- Verified `GET /api/v1/health` returns `200 OK` with `{"status":"UP","service":"deoreonem-api","version":"0.1.0"}`
- **Phase 1 exit criteria: ALL MET ✅**

### Next

- Begin Phase 2: implement decompression session/item business logic (domain objects, mappers, service, controller, tests)

### Blockers / Notes

- None. Phase 1 complete.

---

## 2026-06-10

**Session duration:** ~1.5h
**Phase:** Phase 1 — API Server Skeleton

### Done

- Scaffolded Spring Boot 3.3.5 project (`server/deoreonem_api`)
- Installed real Gradle 8.10.2 wrapper (JAR + scripts from nearby project)
- Fixed dependency resolution: upgraded Spring Boot 3.2.5 → 3.3.5 for Flyway 10.x compatibility
- Created all source files:
  - `DeoreonemApiApplication.java` (main class)
  - `HealthController.java` (`GET /api/v1/health`)
  - `CorsConfig.java` (CORS for Flutter desktop dev)
  - `SwaggerConfig.java` (OpenAPI 3 metadata)
  - `ApiException.java` + `ErrorCode.java` + `ErrorResponse.java` + `GlobalExceptionHandler.java`
  - `application.yml` (default + test profiles)
  - Flyway migrations: V1 (pgcrypto), V2 (decompression_session), V3 (decompression_item + triggers)
- Ran `./gradlew.bat test --no-daemon`: BUILD SUCCESSFUL
- `HealthControllerTest` passes (2 test methods, @WebMvcTest)

### Next

- Start PostgreSQL locally (Docker or native)
- Verify `bootRun` succeeds with real DB
- Confirm Swagger UI at `/swagger-ui/index.html`
- Confirm Flyway runs all 3 migrations cleanly
- Complete Phase 1 exit criteria, then begin Phase 2

### Blockers / Notes

- `bootRun` fails without PostgreSQL (`Connection refused: localhost:5432`)
- Tests pass via `@WebMvcTest` (web-slice only, no DB needed)
- Spring Boot 3.2.5 → 3.3.5 upgrade was required because `flyway-database-postgresql` is a Flyway 10.x artifact not present in Boot 3.2.x BOM

---

## 2026-06-09

**Session duration:** ~1h
**Phase:** Phase 0 — Documentation & Scaffolding

### Done

- Initialized monorepo
- Created all documentation files:
  - README.md
  - docs/00_PRODUCT_SPEC.md
  - docs/01_DESKTOP_UX_SPEC.md
  - docs/02_ARCHITECTURE.md
  - docs/03_API_SPEC.md
  - docs/04_DATA_SPEC.md
  - docs/05_DEVELOPMENT_PLAN.md
  - TASKS.md, CHECKPOINT.md, WORK_LOG.md
- Created Kiro requirements spec
- Resolved all open technical decisions:
  - Database → PostgreSQL 15+
  - Build tool → Gradle
  - Primary key strategy → UUID
  - Flutter state management → Riverpod
- Updated all docs to reflect: renamed tables (`decompression_session`, `decompression_item`), renamed API paths (`/api/v1/decompression-sessions`), PostgreSQL-native schema syntax, `sort_order` column, `is_first_action` computed in DTOs

### Next

- Phase 0 checkpoint: confirm all docs are satisfactory
- Begin Phase 1: Spring Boot project setup (Gradle + PostgreSQL)

### Blockers / Notes

- No blockers. All Phase 0 decisions resolved.

---

<!-- Add new entries above this line -->
