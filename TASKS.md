# DeoReoNem — Task Tracker

> Track all development tasks here. Keep tasks grouped by phase.
> Mark completed tasks in place with `- [x]`. Do not move tasks between sections.

---

## 🔄 In Progress

_(empty)_

---

## 📋 Backlog

### Phase 1 — API Server Skeleton

- [x] Choose: PostgreSQL 15+
- [x] Choose: Gradle
- [x] Choose: UUID primary keys
- [x] Scaffold Spring Boot project (`server/deoreonem_api`) — Java 21, Spring Boot 3.3.5, Gradle 8.10.2
- [x] Add dependencies: Spring Boot Web, Validation, MyBatis, PostgreSQL driver, Flyway, springdoc-openapi, JUnit 5
- [x] Configure application.yml (default + test profiles)
- [x] Create database schema: `decompression_session` table (Flyway V2)
- [x] Create database schema: `decompression_item` table (Flyway V3)
- [x] Create `updated_at` trigger for both tables (Flyway V3)
- [x] Create pgcrypto extension (Flyway V1)
- [x] Configure CORS for local Flutter development (`CorsConfig.java`)
- [x] Configure Swagger/OpenAPI (`SwaggerConfig.java`)
- [x] Implement `ApiException` base class and `GlobalExceptionHandler` skeleton
- [x] Implement `GET /api/v1/health` health check endpoint
- [x] Write `HealthControllerTest` — passes ✅
- [x] Fix Gradle wrapper (real JAR, 8.10.2)
- [x] Fix Spring Boot version (3.2.5 → 3.3.5 for Flyway 10 compatibility)
- [x] Verify Swagger UI loads at `/swagger-ui/index.html` ✅
- [x] Verify: project starts cleanly with `bootRun` (PostgreSQL Docker) ✅

### Phase 2 — MVP 0.1 Backend

- [x] Implement `DecompressionSession` and `DecompressionItem` domain objects + `Category` enum
- [x] Implement custom exception classes: `SessionNotFoundException`, `ItemNotFoundException`, `SessionAlreadyCompleteException`, `ItemNotInSessionException`, `InvalidCategoryException`, `FirstActionIneligibleException`
- [x] Implement request DTOs: `AddItemRequest`, `UpdateCategoryRequest`, `SetFirstActionRequest`
- [x] Implement response DTOs: `ApiResponse<T>`, `SessionResponse`, `ItemResponse`, `SummaryResponse`, `CompleteSessionResponse`, `FirstActionResponse`, `DeleteItemResponse`, `ReviewResponse`
- [x] Implement `DecompressionSessionMapper` + XML
- [x] Implement `DecompressionItemMapper` + XML
- [x] Implement `DecompressionSessionService` — all 7 methods with business rules
- [x] Implement `DecompressionSessionController` — 7 endpoints:
  - `POST /api/v1/decompression-sessions` (201)
  - `POST /api/v1/decompression-sessions/{sessionId}/items` (201)
  - `PATCH /api/v1/decompression-items/{itemId}/category` (200)
  - `PATCH /api/v1/decompression-sessions/{sessionId}/first-action` (200)
  - `POST /api/v1/decompression-sessions/{sessionId}/complete` (200)
  - `GET /api/v1/decompression-sessions/{sessionId}/summary` (200)
  - `GET /api/v1/decompression-sessions/{sessionId}/review` (200)
- [x] Write `DecompressionSessionServiceTest` — 16 unit tests (Mockito) ✅
- [x] Write `DecompressionSessionControllerTest` — 10 controller tests (@WebMvcTest) ✅
- [x] All 28 tests pass: `./gradlew.bat test --no-daemon` BUILD SUCCESSFUL ✅

### Phase 3 — Flutter Desktop Client

- [x] Choose: Riverpod
- [x] Scaffold Flutter project (`apps/deoreonem_desktop`) — Flutter 3.41.1, Windows target
- [x] Enable Windows desktop target (non-resizable 480×680, title "덜어냄")
- [x] Add dependencies: flutter_riverpod, dio, go_router
- [x] Configure app theme (warm palette from UX spec, Noto Sans KR-compatible)
- [x] Implement Screen 1: StartScreen — app name, subtitle, start button, version
- [x] Implement Screen 2: DumpInputScreen — text input, add/remove items, disabled next when empty
- [x] Implement Screen 3: ClassificationScreen — one-at-a-time, 7 category buttons, progress
- [x] Implement Screen 4: FirstActionScreen — eligible items, radio selection, skip option
- [x] Implement Screen 5: EntrustedSummaryScreen — grouped by category, first action highlight
- [x] Implement Screen 6: CompletionScreen — closing message, no CTAs
- [x] Wire navigation flow end-to-end (go_router linear)
- [x] Widget tests for all 6 screens — 7 tests pass ✅
- [x] Manual end-to-end test on Windows — verified ✅

### Phase 4 — Polish & MVP Release

- [x] Wire StartScreen to real API (create session)
- [x] Wire DumpInputScreen to real API (add items)
- [x] Wire ClassificationScreen to real API (update category)
- [x] Wire FirstActionScreen to real API (set first action)
- [x] Wire EntrustedSummaryScreen to real API (load summary + complete session)
- [x] Add Dart model classes: SessionModel, ItemModel, SummaryModel
- [x] Add DecompressionApiService with Dio (all 6 endpoints)
- [x] Add Riverpod providers: session, items, summary
- [x] Add loading states for async API calls
- [x] Add inline error messages for API failures
- [x] Write model serialization tests ✅
- [x] Write API service tests (mocked Dio) ✅
- [x] Write provider tests (mocked service) ✅
- [x] Update widget tests with ProviderScope overrides ✅
- [x] All 34 Flutter tests pass ✅
- [x] Manual end-to-end test on Windows with backend running — verified ✅
- [ ] Handle edge cases: empty session, offline, server errors
- [ ] Visual polish pass on all screens
- [x] Update README with setup and run instructions ✅
- [x] Verify `flutter build windows` produces clean build ✅
- [ ] Create distributable Windows package

### MVP 0.3 — Deferred (Review Item Lifecycle)

- [ ] Add DONE category to backend enum/validation (new Flyway migration)
- [ ] Resolve NOW items before session completion (mini-flow in Summary screen)
- [ ] Store multiple completed session IDs locally (up to 7)
- [ ] Review item actions: mark DONE, mark DROP (mutate via updateCategory API)
- [ ] Windows installer (MSIX or Inno Setup)

---

## ✅ Completed

### Phase 0 — Documentation & Scaffolding

- [x] Create monorepo directory structure
- [x] Create `README.md`
- [x] Create `docs/00_PRODUCT_SPEC.md`
- [x] Create `docs/01_DESKTOP_UX_SPEC.md`
- [x] Create `docs/02_ARCHITECTURE.md`
- [x] Create `docs/03_API_SPEC.md`
- [x] Create `docs/04_DATA_SPEC.md`
- [x] Create `docs/05_DEVELOPMENT_PLAN.md`
- [x] Create `TASKS.md`
- [x] Create `CHECKPOINT.md`
- [x] Create `WORK_LOG.md`
- [x] Create `.kiro/specs/deoreonem-project-setup/requirements.md`
