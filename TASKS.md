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
- [ ] Scaffold Flutter project (`apps/deoreonem_desktop`)
- [ ] Enable Windows desktop target
- [ ] Add dependencies: Dio, Riverpod
- [ ] Configure app theme (colors, fonts, window size)
- [ ] Create Dart model classes: DecompressionSession, DecompressionItem
- [ ] Create API client service with Dio (base URL: `/api/v1/decompression-sessions`)
- [ ] Implement Screen 1: Start Screen
- [ ] Implement Screen 2: Item Entry Screen
- [ ] Implement Screen 3: Item Classification Screen
- [ ] Implement Screen 4: First Action Selection Screen
- [ ] Implement Screen 5: Session Summary Screen
- [ ] Implement Screen 6: Completion Screen
- [ ] Wire navigation flow end-to-end
- [ ] Add loading states for async API calls
- [ ] Add inline error messages for API failures
- [ ] Manual end-to-end test on Windows

### Phase 4 — Polish & MVP Release

- [ ] Handle edge cases: empty session, offline, server errors
- [ ] Visual polish pass on all screens
- [ ] Write Flutter widget tests for key screens
- [ ] Update README with setup and run instructions
- [ ] Verify `flutter build windows` produces clean build
- [ ] Create distributable Windows package

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
