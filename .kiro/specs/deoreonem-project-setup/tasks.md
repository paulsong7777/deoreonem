# Implementation Plan: DeoReoNem Project Setup

## Overview

Incremental implementation across 4 phases: Phase 1 sets up the Spring Boot API skeleton with Flyway migrations, health endpoint, and Swagger UI. Phase 2 implements all 8 session/item endpoints with full domain rule enforcement and property-based tests. Phase 3 scaffolds the Flutter Windows desktop shell with 6 static screens. Phase 4 wires the Flutter client to the live API via Dio and Riverpod.

---

## In Progress

_(empty — start a task to populate this section)_

---

## Backlog

### Phase 1 — API Server Skeleton

- [x] 1.1 Create Gradle project structure for `server/deoreonem_api`
  - Initialize Spring Boot 3.x Gradle project with Java 21 (`settings.gradle`, `build.gradle`)
  - Add all required dependencies: `spring-boot-starter-web`, `spring-boot-starter-validation`, `mybatis-spring-boot-starter`, `postgresql`, `springdoc-openapi-starter-webmvc-ui`, `flyway-core`, `spring-boot-starter-test`; add `spring-boot-devtools` as `developmentOnly`
  - Create `DeoreonemApiApplication.java` main class in `com.deoreonem.api`
  - _Requirements: 8.2_

- [x] 1.2 Create Spring Boot package structure
  - Create empty packages: `controller/`, `service/`, `mapper/`, `domain/`, `dto/`, `config/`, `exception/` under `com.deoreonem.api`
  - _Requirements: 8.2_

- [x] 1.3 Write `application.yml` with `default` and `test` profiles
  - `default` profile: datasource pointing to PostgreSQL (configurable host/port/db), MyBatis mapper locations, Flyway enabled, server port 8080, Swagger UI enabled at `/swagger-ui.html`
  - `test` profile: separate datasource for test DB, Flyway `baseline-on-migrate: true`
  - _Requirements: 8.2_

- [x] 1.4 Write Flyway migration `V1__create_extensions.sql`
  - Content: `CREATE EXTENSION IF NOT EXISTS pgcrypto;`
  - Place in `src/main/resources/db/migration/`
  - _Requirements: 7.1, 7.4, 8.2_

- [x] 1.5 Write Flyway migration `V2__create_decompression_session.sql`
  - Full DDL for `decompression_session` table as defined in `docs/04_DATA_SPEC.md` Section 3: `session_id` UUID PK, `status` VARCHAR(20) NOT NULL default `IN_PROGRESS`, `first_action_item_id` UUID NULL, `completed_at` TIMESTAMPTZ NULL, `created_at` TIMESTAMPTZ NOT NULL default `now()`, `updated_at` TIMESTAMPTZ NOT NULL default `now()`, CHECK constraint on `status`, no FK on `first_action_item_id`
  - Place in `src/main/resources/db/migration/`
  - _Requirements: 7.1, 7.4, 8.2_

- [x] 1.6 Write Flyway migration `V3__create_decompression_item_and_triggers.sql`
  - Full DDL for `decompression_item` table: `item_id` UUID PK, `session_id` UUID NOT NULL FK → `decompression_session` ON DELETE CASCADE, `content` VARCHAR(500) NOT NULL, `category` VARCHAR(20) NULL with CHECK constraint for all 7 enum values, `sort_order` INT NOT NULL, `created_at`/`updated_at` TIMESTAMPTZ
  - Index: `idx_decompression_item_session_id ON decompression_item (session_id)`
  - `set_updated_at()` plpgsql trigger function and `BEFORE UPDATE` triggers for both tables
  - Place in `src/main/resources/db/migration/`
  - _Requirements: 7.2, 7.3, 7.5, 8.2_

- [x] 1.7 Implement `CorsConfig.java`
  - `@Configuration` class implementing `WebMvcConfigurer` in `com.deoreonem.api.config`
  - Allow origins: `http://localhost` (all ports via pattern), allowed methods: GET, POST, PUT, PATCH, DELETE, OPTIONS, allowed headers: `*`, credentials: false
  - _Requirements: 5.1, 8.2_

- [x] 1.8 Implement `SwaggerConfig.java`
  - `@Configuration` bean in `com.deoreonem.api.config` configuring `springdoc-openapi`: API title "DeoReoNem API", version "0.1.0", description
  - Ensure Swagger UI is accessible at `/swagger-ui.html` and OpenAPI JSON at `/v3/api-docs`
  - _Requirements: 6.4, 8.2_

- [x] 1.9 Implement `ApiException` base class and `GlobalExceptionHandler` skeleton
  - `ApiException.java` in `com.deoreonem.api.exception`: base unchecked exception with `errorCode` (String) and `httpStatus` fields
  - Define all 8 error code constants as `public static final String` in a companion `ErrorCodes` class or as an enum: `VALIDATION_ERROR`, `SESSION_NOT_FOUND`, `ITEM_NOT_FOUND`, `SESSION_ALREADY_COMPLETE`, `ITEM_NOT_IN_SESSION`, `INVALID_CATEGORY`, `FIRST_ACTION_INELIGIBLE`, `INTERNAL_ERROR`
  - `GlobalExceptionHandler.java` annotated `@ControllerAdvice`: skeleton handlers returning the error envelope `{ "success": false, "error": { "code": "...", "message": "..." } }` — handler methods stubbed for each error code but no business routing yet
  - _Requirements: 6.5, 8.2_

- [x] 1.10 Implement `HealthController`
  - `@RestController` in `com.deoreonem.api.controller` mapping `GET /api/v1/health`
  - Returns `200 OK` with JSON body `{ "status": "UP", "service": "deoreonem-api", "version": "0.1.0" }`
  - _Requirements: 8.2_

- [x] 1.11 Write `HealthControllerTest`
  - JUnit 5 + `@WebMvcTest(HealthController.class)` or `@SpringBootTest` with MockMvc
  - Test: `GET /api/v1/health` returns 200, `status == "UP"`, `service == "deoreonem-api"`, `version == "0.1.0"`
  - _Requirements: 8.2_

- [x] 1.12 Phase 1 exit criteria — verify server starts, Swagger UI loads, health endpoint returns 200
  - Ensure all Phase 1 tests pass (`./gradlew test`)
  - Confirm `GET /api/v1/health` returns `200 OK` with correct body
  - Confirm Swagger UI accessible at `http://localhost:8080/swagger-ui.html`
  - _Requirements: 8.2_

---

### Phase 2 — Backend Decompression Flow

- [x] 2.1 Implement `DecompressionSession` and `DecompressionItem` domain objects
  - `DecompressionSession.java` in `com.deoreonem.api.domain`: fields `sessionId` (UUID), `status` (String), `firstActionItemId` (UUID, nullable), `completedAt` (OffsetDateTime, nullable), `createdAt` (OffsetDateTime), `updatedAt` (OffsetDateTime), `items` (List<DecompressionItem>, for JOIN results)
  - `DecompressionItem.java` in `com.deoreonem.api.domain`: fields `itemId` (UUID), `sessionId` (UUID), `content` (String), `category` (String, nullable), `sortOrder` (int), `createdAt` (OffsetDateTime), `updatedAt` (OffsetDateTime)
  - Note: `isFirstAction` is NOT a field on `DecompressionItem`; it is computed in DTOs
  - _Requirements: 7.1, 7.2, 7.6_

- [x] 2.2 Implement all request and response DTOs
  - Request DTOs in `com.deoreonem.api.dto`: `CreateSessionRequest` (empty body), `AddItemRequest` (`@NotBlank @Size(max=500) String content`), `UpdateItemCategoryRequest` (`@NotNull String category`), `SetFirstActionRequest` (`@NotNull UUID itemId`)
  - Response DTOs: `SessionResponse`, `SessionWithItemsResponse` (extends/wraps SessionResponse + `List<ItemResponse> items`), `ItemResponse` (includes computed `boolean isFirstAction`), `SummaryResponse` (sessionId, status, totalItems, firstActionItem, `Map<String, List<...>> itemsByCategory`), `CompleteSessionResponse`, `FirstActionResponse`, `DeleteItemResponse`
  - All response DTOs wrapped in an `ApiResponse<T>` envelope with `success: true` and `data: T`
  - _Requirements: 6.1, 6.2, 6.6, 7.6_

- [x] 2.3 Implement `DecompressionSessionMapper` interface and XML
  - Interface `com.deoreonem.api.mapper.DecompressionSessionMapper` annotated `@Mapper`: `insertSession(DecompressionSession)`, `findById(UUID)`, `findByIdWithItems(UUID)` (JOIN returning session + ordered items), `updateStatus(UUID, String)`, `updateFirstAction(UUID, UUID)`, `updateCompletedAt(UUID, OffsetDateTime)`
  - XML mapper file `src/main/resources/mapper/DecompressionSessionMapper.xml` with all SQL statements; `findByIdWithItems` uses a `<resultMap>` with nested `<collection>` for items ordered by `sort_order ASC`
  - _Requirements: 7.1, 8.3_

- [x] 2.4 Implement `DecompressionItemMapper` interface and XML
  - Interface `com.deoreonem.api.mapper.DecompressionItemMapper` annotated `@Mapper`: `insertItem(DecompressionItem)`, `findById(UUID)`, `findBySessionIdOrderBySortOrder(UUID)`, `updateCategory(UUID, String)`, `deleteById(UUID)`, `getMaxSortOrder(UUID)` (returns `Integer`, nullable)
  - XML mapper file `src/main/resources/mapper/DecompressionItemMapper.xml` with all SQL statements; `findBySessionIdOrderBySortOrder` orders by `sort_order ASC`; `getMaxSortOrder` returns `MAX(sort_order)` for given session
  - _Requirements: 7.2, 8.3_

- [x] 2.5 Implement custom exception classes for all 8 error codes
  - One exception class per error code in `com.deoreonem.api.exception`: `SessionNotFoundException`, `ItemNotFoundException`, `SessionAlreadyCompleteException`, `ItemNotInSessionException`, `InvalidCategoryException`, `FirstActionIneligibleException` — all extend `ApiException`; `ValidationException` handled by Spring's `MethodArgumentNotValidException`
  - Complete `GlobalExceptionHandler` handlers: map each exception type to its HTTP status and error code as defined in `docs/03_API_SPEC.md` Section 2
  - _Requirements: 6.5_

- [x] 2.6 Implement `DecompressionSessionService` — session creation and retrieval
  - `createSession()`: constructs `DecompressionSession`, calls `sessionMapper.insertSession`, returns `SessionResponse`
  - `getSession(UUID sessionId)`: calls `sessionMapper.findByIdWithItems`, throws `SessionNotFoundException` if null, computes `isFirstAction` for each item in response, returns `SessionWithItemsResponse`
  - _Requirements: 6.1, 6.2_

- [x] 2.7 Implement `DecompressionSessionService` — add item with `sort_order` assignment
  - `addItem(UUID sessionId, AddItemRequest)`: loads session (throws `SessionNotFoundException`); checks `COMPLETED` → throws `SessionAlreadyCompleteException`; calls `itemMapper.getMaxSortOrder(sessionId)`, assigns `sortOrder = max + 1` (or 1 if null); calls `itemMapper.insertItem`; returns `ItemResponse` with `isFirstAction = false`
  - _Requirements: 6.1, 7.2_

- [x] 2.8 Implement `DecompressionSessionService` — update item category
  - `updateCategory(UUID sessionId, UUID itemId, UpdateItemCategoryRequest)`: validates session exists and is `IN_PROGRESS`; validates item exists; checks item belongs to session (throws `ItemNotInSessionException`); validates category is one of 7 valid values (throws `InvalidCategoryException`); calls `itemMapper.updateCategory`; returns `ItemResponse` with computed `isFirstAction`
  - _Requirements: 6.1, 6.2_

- [x] 2.9 Implement `DecompressionSessionService` — set First Action with category gate
  - `setFirstAction(UUID sessionId, SetFirstActionRequest)`: validates session exists and is `IN_PROGRESS`; loads item (throws `ItemNotFoundException`); checks item's category ∈ {NOW, TOMORROW, THIS_WEEK} (throws `FirstActionIneligibleException` for WAITING, MEMO, WORRY_ONLY, DROP, or null); calls `sessionMapper.updateFirstAction`; returns `FirstActionResponse`
  - _Requirements: 6.1_

- [x] 2.10 Implement `DecompressionSessionService` — get summary
  - `getSummary(UUID sessionId)`: loads session with items; computes `isFirstAction` per item; groups items by category into `Map<String, List<...>>`; includes all 7 category keys (empty list for categories with no items); identifies `firstActionItem` by `firstActionItemId`; returns `SummaryResponse`
  - _Requirements: 6.1, 6.6, 7.6_

- [x] 2.11 Implement `DecompressionSessionService` — complete session
  - `completeSession(UUID sessionId)`: loads session; checks already `COMPLETED` → throws `SessionAlreadyCompleteException`; calls `sessionMapper.updateStatus(sessionId, "COMPLETED")` and `sessionMapper.updateCompletedAt(sessionId, OffsetDateTime.now())`; returns `CompleteSessionResponse`
  - _Requirements: 6.1, 6.2_

- [x] 2.12 Implement `DecompressionSessionService` — delete item
  - `deleteItem(UUID sessionId, UUID itemId)`: validates session exists and is `IN_PROGRESS`; loads item (throws `ItemNotFoundException`); checks item belongs to session; calls `itemMapper.deleteById`; returns `DeleteItemResponse` with `deleted: true`
  - _Requirements: 6.1_

- [x] 2.13 Implement `DecompressionSessionController` with all 8 endpoints
  - `@RestController @RequestMapping("/api/v1/decompression-sessions")` in `com.deoreonem.api.controller`
  - Map all 8 endpoints: `POST /` → 201, `GET /{sessionId}` → 200, `POST /{sessionId}/items` → 201, `PATCH /{sessionId}/items/{itemId}/category` → 200, `PUT /{sessionId}/first-action` → 200, `GET /{sessionId}/summary` → 200, `POST /{sessionId}/complete` → 200, `DELETE /{sessionId}/items/{itemId}` → 200
  - Delegate to `DecompressionSessionService`; wrap all responses in `ApiResponse<T>` envelope
  - Add `@Operation` / `@ApiResponse` springdoc annotations per endpoint
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 2.14 Write `DecompressionSessionServiceTest` (unit tests, JUnit 5 + Mockito)
  - Mock `DecompressionSessionMapper` and `DecompressionItemMapper`
  - Test: COMPLETED session rejects `addItem`, `updateCategory`, `setFirstAction`, `complete` — each throws correct exception
  - Test: `setFirstAction` with each ineligible category (WAITING, MEMO, WORRY_ONLY, DROP, null) throws `FirstActionIneligibleException`
  - Test: `setFirstAction` with eligible categories (NOW, TOMORROW, THIS_WEEK) succeeds
  - Test: `isFirstAction` computed correctly — true only for item matching `firstActionItemId`, false for all others, zero when `firstActionItemId` is null
  - _Requirements: 6.1, 6.2, 6.6_

- [x] 2.15 Write mapper tests (`@MybatisTest`)
  - Use `@MybatisTest` with embedded or test PostgreSQL
  - Test: `insertItem` assigns `sort_order = MAX(sort_order) + 1` relative to the session; first item gets `sort_order = 1`
  - Test: `findBySessionIdOrderBySortOrder` returns items in strict ascending `sort_order` order regardless of insertion timing
  - Test: `deleteById` removes exactly the target item; other session items are unaffected; item count decreases by exactly 1
  - _Requirements: 7.2_

- [x] 2.16 Write API integration tests (`@SpringBootTest`)
  - Full request/response cycle using `MockMvc` or `TestRestTemplate` for each of the 8 endpoints
  - Test error envelope shape for every named error code: `{ "success": false, "error": { "code": "...", "message": "..." } }`
  - Test `GET .../summary` groups items correctly by category; `DROP` items appear in summary but are excluded from First Action eligibility
  - Test `isFirstAction` flags in summary response
  - _Requirements: 6.1, 6.2, 6.5, 6.6_

- [ ]* 2.17 Write property-based test: Property 1 — Session state machine is terminal on completion
  - **Property 1: Session state machine is terminal on completion**
  - **Validates: Requirements 6.1, 6.2**
  - Use jqwik `@Property` with `@ForAll` session and random mutating operation selection
  - Generate random sessions, complete them, then attempt each of the 4 mutating operations (`addItem`, `updateCategory`, `setFirstAction`, `complete`); verify all throw/return `SESSION_ALREADY_COMPLETE`
  - Minimum 100 iterations
  - Tag: `// Feature: deoreonem-project-setup, Property 1: Session state machine is terminal on completion`

- [ ]* 2.18 Write property-based test: Property 2 — Item sort_order reflects insertion sequence
  - **Property 2: Item sort_order reflects insertion sequence**
  - **Validates: Requirements 7.2**
  - Use jqwik `@Property` generating sequences of 1–50 items added to a session
  - Verify retrieved items have `sort_order` values 1, 2, …, N in ascending order matching insertion sequence
  - Minimum 100 iterations
  - Tag: `// Feature: deoreonem-project-setup, Property 2: Item sort_order reflects insertion sequence`

- [ ]* 2.19 Write property-based test: Property 3 — isFirstAction is consistent with session state
  - **Property 3: isFirstAction is consistent with session state**
  - **Validates: Requirements 6.6, 7.6**
  - Use jqwik `@Property` generating sessions with random item lists and random (or null) `firstActionItemId`
  - Verify: exactly one item has `isFirstAction = true` when `firstActionItemId` is non-null and matches; zero items have `isFirstAction = true` when `firstActionItemId` is null
  - Minimum 100 iterations
  - Tag: `// Feature: deoreonem-project-setup, Property 3: isFirstAction is consistent with session state`

- [ ]* 2.20 Write property-based test: Property 4 — First Action eligibility is category-gated
  - **Property 4: First Action eligibility is category-gated**
  - **Validates: Requirements 6.1**
  - Use jqwik `@Property` generating items with all 7 category values plus null
  - Verify: `setFirstAction` succeeds iff category ∈ {NOW, TOMORROW, THIS_WEEK}; all other categories (WAITING, MEMO, WORRY_ONLY, DROP, null) throw `FirstActionIneligibleException`
  - Minimum 100 iterations
  - Tag: `// Feature: deoreonem-project-setup, Property 4: First Action eligibility is category-gated`

- [x] 2.21 Phase 2 exit criteria — all 8 endpoints pass integration tests; all domain rules verified
  - Run `./gradlew test`; all unit, mapper, integration, and property-based tests pass
  - Verify all 8 error codes are reachable and return the correct HTTP status and envelope shape
  - _Requirements: 6.1, 6.2, 6.5, 7.2, 8.3_

---

### Phase 3 — Flutter Desktop Shell

- [x] 3.1 Create Flutter Windows project for `apps/deoreonem_desktop`
  - Run `flutter create --platforms=windows apps/deoreonem_desktop` from monorepo root
  - Set window title to "덜어냄" in `windows/runner/main.cpp` or via `window_manager`
  - Set window size to approximately 480×680px, non-resizable in `windows/runner/main.cpp`
  - _Requirements: 4.1, 4.5_

- [x] 3.2 Configure `pubspec.yaml` with required dependencies
  - Add dependencies: `flutter_riverpod`, `dio`, `go_router` (or `Navigator 2.0`)
  - Ensure `flutter` SDK minimum version is compatible with the chosen packages
  - _Requirements: 5.4, 5.5_

- [x] 3.3 Scaffold all 6 screen files under `lib/screens/`
  - Create: `start_screen.dart`, `dump_input_screen.dart`, `classification_screen.dart`, `first_action_screen.dart`, `entrusted_summary_screen.dart`, `completion_screen.dart`
  - Each file: `StatefulWidget` or `ConsumerWidget` with a `Scaffold` and a placeholder `Column`
  - _Requirements: 4.1_

- [x] 3.4 Implement `StartScreen` static UI
  - App name "덜어냄" large centered light-weight text
  - Subtitle: "오늘 머릿속에 남아있는 것들을 꺼내 보세요."
  - "시작하기" button (disabled/mock — navigation only in Phase 3)
  - Version number footer
  - _Requirements: 4.1, 4.2_

- [x] 3.5 Implement `DumpInputScreen` static UI
  - Title: "오늘 남은 것들"
  - `TextField` with placeholder "생각, 걱정, 할 일... 하나씩 적어보세요"
  - Add button (and Enter key) — appends item to local mock list and clears input
  - Scrollable item list with delete (×) buttons on each card
  - "Next: Classify" button — enabled only when at least one item exists
  - _Requirements: 4.1, 4.2_

- [x] 3.6 Implement `ClassificationScreen` static UI (one-at-a-time layout)
  - Shows one item card at the top with mock item text
  - Progress indicator: "N / M 분류됨"
  - 7 category buttons each showing Korean label and short description per `docs/01_DESKTOP_UX_SPEC.md` table
  - Tapping a category advances to the next mock item; completes to "Next" when all done
  - _Requirements: 4.1, 4.2_

- [x] 3.7 Implement `FirstActionScreen` static UI
  - Prompt: "내일 가장 먼저 할 일 하나를 고르세요."
  - List of mock eligible items (NOW/TOMORROW/THIS_WEEK only) with selectable radio/highlight
  - "Next" button enabled after selection; "Skip" option
  - _Requirements: 4.1, 4.2_

- [x] 3.8 Implement `EntrustedSummaryScreen` static UI
  - Title: "오늘의 덜어냄"
  - Mock items grouped by category (flat lists per category, collapsible optional)
  - First Action highlighted at top with accent color or star
  - Total count: "총 N개를 맡겼습니다."
  - "완료하기" button
  - _Requirements: 4.1, 4.2_

- [x] 3.9 Implement `CompletionScreen` static UI
  - Large centered message: "오늘은 여기까지 해도 됩니다."
  - Small subtitle: "수고하셨어요."
  - Small bottom-aligned close button: "닫기"
  - No CTAs, no navigation prompts, no notifications
  - _Requirements: 4.1, 4.4_

- [x] 3.10 Wire linear navigation across all 6 screens
  - Configure `go_router` (or Navigator) routes: StartScreen → DumpInputScreen → ClassificationScreen → FirstActionScreen → EntrustedSummaryScreen → CompletionScreen
  - Each screen's primary action button navigates to the next screen
  - "닫기" on CompletionScreen calls `SystemNavigator.pop()` or `exit(0)`
  - No back navigation in MVP 0.1 (or limited to the immediately preceding screen only)
  - _Requirements: 4.3_

- [ ]* 3.11 Write widget tests for all 6 screens
  - One `testWidgets` test per screen verifying key UI elements render:
    - `StartScreen`: app name text, subtitle text, start button
    - `DumpInputScreen`: title, text field, next button (disabled when list empty)
    - `ClassificationScreen`: item card, 7 category buttons, progress indicator
    - `FirstActionScreen`: prompt text, item list, next button
    - `EntrustedSummaryScreen`: title, total count text, complete button
    - `CompletionScreen`: main message text, close button; no extra CTAs
  - _Requirements: 4.1, 4.4_

- [x] 3.12 Phase 3 exit criteria — all 6 screens render; linear navigation flows end-to-end
  - Run `flutter test`; all widget tests pass
  - Verify all 6 screens navigate in correct order with mock data
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

---

### Phase 4 — Flutter ↔ REST Integration

- [ ] 4.1 Create Dart model classes in `lib/models/`
  - `session_model.dart`: `SessionModel` with fields `sessionId`, `status`, `firstActionItemId` (nullable), `createdAt`, `updatedAt`; factory `fromJson`, `toJson`, immutable `copyWith`
  - `item_model.dart`: `ItemModel` with fields `itemId`, `sessionId`, `content`, `category` (nullable), `isFirstAction`, `sortOrder`, `createdAt`, `updatedAt`; factory `fromJson`, `toJson`, immutable `copyWith`
  - `summary_model.dart`: `SummaryModel` with fields `sessionId`, `status`, `totalItems`, `firstActionItem` (nullable `ItemModel`), `itemsByCategory` (`Map<String, List<ItemModel>>`); factory `fromJson`, `toJson`, immutable `copyWith`
  - _Requirements: 6.2_

- [ ] 4.2 Implement `DecompressionApiClient` in `lib/api/`
  - Create `decomposition_api_client.dart` wrapping Dio: base URL `http://localhost:8080/api/v1`, connect timeout 10s, receive timeout 30s
  - Add logging interceptor (request/response logging)
  - Add error normalization interceptor: parse `{ "success": false, "error": { "code": "...", "message": "..." } }` envelopes and throw typed `ApiException` instances with error code and message
  - Implement all 8 typed async methods matching each endpoint in `docs/03_API_SPEC.md`
  - _Requirements: 5.4, 6.1, 6.5_

- [ ] 4.3 Implement Riverpod providers in `lib/providers/`
  - `session_provider.dart`: `StateNotifierProvider` holding current `SessionModel?`; `createSession()` calls API client and updates state; `resetSession()` invalidates provider
  - `items_provider.dart`: `StateNotifierProvider` holding `List<ItemModel>`; `addItem`, `updateCategory`, `deleteItem` call API and update list
  - `classification_provider.dart`: derived provider from `itemsProvider` tracking unclassified items (category == null)
  - `first_action_provider.dart`: `StateNotifierProvider` holding selected First Action item ID; `setFirstAction()` calls API
  - All providers invalidated/reset on new session start via `ref.invalidate(...)` or notifier reset
  - _Requirements: 5.5_

- [ ] 4.4 Wire `StartScreen` to real API
  - "시작하기" button calls `sessionProvider.createSession()`, shows inline spinner while in-flight, navigates to `DumpInputScreen` on success, shows inline error with retry on failure
  - _Requirements: 4.1, 5.4, 5.5_

- [ ] 4.5 Wire `DumpInputScreen` to real API
  - Add button calls `itemsProvider.addItem(content)`, shows inline spinner; new item appears in list on success; inline error with retry on failure
  - Delete (×) calls `itemsProvider.deleteItem(itemId)` with inline loading state
  - "Next: Classify" navigates when at least one item exists
  - _Requirements: 4.1, 5.4, 5.5_

- [ ] 4.6 Wire `ClassificationScreen` to real API
  - Category tap calls `itemsProvider.updateCategory(itemId, category)`, shows per-item spinner, advances to next item on success; inline error on failure
  - Progress derived from `classificationProvider`
  - Navigates to `FirstActionScreen` when all items are classified
  - _Requirements: 4.1, 5.4, 5.5_

- [ ] 4.7 Wire `FirstActionScreen` to real API
  - "Next" button calls `firstActionProvider.setFirstAction(itemId)`, shows inline spinner, navigates to `EntrustedSummaryScreen` on success; inline error on failure
  - Item list sourced from real API via `itemsProvider` filtered to eligible categories
  - _Requirements: 4.1, 5.4, 5.5_

- [ ] 4.8 Wire `EntrustedSummaryScreen` to real API
  - On mount: calls `GET .../summary` and displays real grouped data
  - "완료하기" button calls complete session API, shows inline spinner, navigates to `CompletionScreen` on success; inline error on failure
  - _Requirements: 4.1, 5.4, 5.5_

- [ ] 4.9 Implement inline error handling across all screens
  - Inline error messages (no modal dialogs) for API failures: "연결에 문제가 생겼어요. 다시 시도해 주세요."
  - Retry buttons for transient errors (network timeout, 5xx)
  - Inline domain error messages for non-retryable domain errors (e.g., SESSION_ALREADY_COMPLETE)
  - All action buttons disabled during in-flight requests
  - _Requirements: 4.1_

- [ ] 4.10 Write `DecompressionApiClient` unit tests
  - Mock Dio responses using `dio`'s `HttpClientAdapter` mock or a test double
  - Verify correct HTTP method, path, and request body for each of the 8 API calls
  - Verify error normalization interceptor maps each of the 8 named error codes to typed `ApiException`
  - _Requirements: 6.1, 6.5_

- [ ]* 4.11 Write property-based test: Property 5 — Dart model serialization round-trip preserves data
  - **Property 5: Dart model serialization round-trip preserves data**
  - **Validates: Requirements 6.2**
  - Using `dart_test` with a custom generator (e.g., `faker` or manual random generation)
  - Generate random `ItemModel` and `SessionModel` instances including nullable fields
  - Verify `fromJson(model.toJson()) == model` for all generated instances
  - Tag: `// Feature: deoreonem-project-setup, Property 5: Dart model serialization round-trip preserves data`

- [ ]* 4.12 Update widget tests: buttons trigger API calls and navigation advances on success
  - Update each screen's widget test to use mocked `DecompressionApiClient` via Riverpod provider override
  - Verify primary action buttons invoke the correct API client method
  - Verify navigation advances to the correct next screen on API success
  - _Requirements: 4.1, 4.3_

- [ ] 4.13 Phase 4 exit criteria — full end-to-end session flow works against local API server
  - Run `flutter test`; all unit tests, widget tests, and property test pass
  - Full session flow (Start → Dump → Classify → First Action → Summary → Complete) works end-to-end against the running API server
  - _Requirements: 4.1, 5.4, 5.5, 6.1_

---

## Completed

### Phase 0 — Documentation & Scaffolding

- [x] Create `docs/00_PRODUCT_SPEC.md` — product vision, core feeling, category definitions, 7-step session flow, out-of-scope list
- [x] Create `docs/01_DESKTOP_UX_SPEC.md` — all 6 screens, visual tone, navigation flow, error states, platform notes
- [x] Create `docs/02_ARCHITECTURE.md` — system diagram, component responsibilities, tech stack decisions, authentication deferral note
- [x] Create `docs/03_API_SPEC.md` — all 8 REST endpoints with request/response bodies, error codes, Swagger note
- [x] Create `docs/04_DATA_SPEC.md` — full DDL for both tables, trigger DDL, entity relationships, MyBatis mapper plan
- [x] Create `docs/05_DEVELOPMENT_PLAN.md` — phased plan (Phase 0–4), deferred items list (Spring Security, mobile, AI)
- [x] Create `README.md` at monorepo root with product description, directory structure, tech stack, doc index, getting started
- [x] Create `TASKS.md` at monorepo root for task tracking
- [x] Create `CHECKPOINT.md` at monorepo root with Phase 0 entry recording completed deliverables and technical decisions
- [x] Create `WORK_LOG.md` at monorepo root with dated entry template and initial Phase 0 log entry
- [x] Create `apps/deoreonem_desktop/` directory placeholder
- [x] Create `server/deoreonem_api/` directory placeholder

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP path
- Each task references specific requirements for traceability
- Checkpoints at end of each phase ensure incremental validation before proceeding
- Property tests (jqwik for Java, dart_test for Dart) validate universal correctness properties across broad input space
- Unit tests focus on concrete examples, specific error conditions, and integration points
- The design document uses Java/Spring Boot and Dart/Flutter as specified languages — no language selection prompt needed
- Phase 1 does NOT include any session/item business logic; all business logic is Phase 2

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "1.4"] },
    { "id": 2, "tasks": ["1.5", "1.7", "1.8", "1.9"] },
    { "id": 3, "tasks": ["1.6", "1.10"] },
    { "id": 4, "tasks": ["1.11"] },
    { "id": 5, "tasks": ["1.12", "2.1"] },
    { "id": 6, "tasks": ["2.2", "2.3", "2.4"] },
    { "id": 7, "tasks": ["2.5"] },
    { "id": 8, "tasks": ["2.6", "2.7", "2.8", "2.9", "2.10", "2.11", "2.12"] },
    { "id": 9, "tasks": ["2.13"] },
    { "id": 10, "tasks": ["2.14", "2.15", "2.16", "2.17", "2.18", "2.19", "2.20"] },
    { "id": 11, "tasks": ["2.21", "3.1"] },
    { "id": 12, "tasks": ["3.2", "3.3"] },
    { "id": 13, "tasks": ["3.4", "3.5", "3.6", "3.7", "3.8", "3.9"] },
    { "id": 14, "tasks": ["3.10"] },
    { "id": 15, "tasks": ["3.11"] },
    { "id": 16, "tasks": ["3.12", "4.1"] },
    { "id": 17, "tasks": ["4.2"] },
    { "id": 18, "tasks": ["4.3"] },
    { "id": 19, "tasks": ["4.4", "4.5", "4.6", "4.7", "4.8", "4.9"] },
    { "id": 20, "tasks": ["4.10", "4.11"] },
    { "id": 21, "tasks": ["4.12"] },
    { "id": 22, "tasks": ["4.13"] }
  ]
}
```
