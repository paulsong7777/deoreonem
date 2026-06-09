# Requirements Document

## Introduction

DeoReoNem (덜어냄) is a desktop-first Digital Decompression application. It helps users unload lingering work thoughts, worries, and unfinished tasks into a lightweight desktop app at the end of a workday, so they can leave work at work and return to rest. The name means "to set down" or "to unburden" in Korean.

This spec covers the project scaffolding, documentation, and architecture setup for MVP 0.1. The system is a monorepo containing a Flutter Windows desktop client and a Spring Boot REST API backend. No product code is written in this phase — only steering documents, architecture docs, and project structure are established.

---

## Glossary

- **DeoReoNem**: The product name. Korean for "덜어냄" (to set down, to unburden).
- **Desktop_App**: The Flutter Windows desktop client application (`apps/deoreonem_desktop`).
- **API_Server**: The Spring Boot 3.x REST API backend (`server/deoreonem_api`).
- **Session**: A single decompression session where a user dumps and classifies mental items.
- **Item**: A single thought, worry, task, or memo added during a Session.
- **Category**: The classification assigned to an Item. One of: `NOW`, `TOMORROW`, `THIS_WEEK`, `WAITING`, `MEMO`, `WORRY_ONLY`, `DROP`.
- **First_Action**: The one Item the user selects as their top priority for tomorrow, chosen before completing a Session.
- **Completion_Screen**: The calm final screen shown after a Session is complete, displaying the message "오늘은 여기까지 해도 됩니다."
- **Monorepo**: The single Git repository containing all project components.
- **API_Contract**: The OpenAPI/Swagger specification describing all REST API endpoints.
- **REST_API**: The versioned HTTP API exposed by the API_Server under `/api/v1`.
- **Spec_Document**: A Markdown documentation file in the `docs/` directory describing one aspect of the product.
- **MyBatis**: The SQL mapping framework used by the API_Server for database access.
- **Provider_Riverpod**: The state management library used by the Desktop_App. **Riverpod** selected for MVP 0.1.

---

## Requirements

### Requirement 1: Monorepo Project Structure

**User Story:** As a developer, I want a well-defined monorepo structure, so that all components of the project are organized consistently and navigable from a single repository.

#### Acceptance Criteria

1. THE Monorepo SHALL contain the directory `apps/deoreonem_desktop` for the Flutter Windows desktop client.
2. THE Monorepo SHALL contain the directory `server/deoreonem_api` for the Spring Boot REST API backend.
3. THE Monorepo SHALL contain the directory `docs/` containing all six documentation files: `00_PRODUCT_SPEC.md`, `01_DESKTOP_UX_SPEC.md`, `02_ARCHITECTURE.md`, `03_API_SPEC.md`, `04_DATA_SPEC.md`, and `05_DEVELOPMENT_PLAN.md`.
4. THE Monorepo SHALL contain a `README.md` file at the root level.
5. THE Monorepo SHALL contain a `TASKS.md` file at the root level for tracking development tasks.
6. THE Monorepo SHALL contain a `CHECKPOINT.md` file at the root level for recording phase milestones.
7. THE Monorepo SHALL contain a `WORK_LOG.md` file at the root level for logging daily work progress.

---

### Requirement 2: README Documentation

**User Story:** As a developer or new contributor, I want a root-level README, so that I can understand what DeoReoNem is, how the repo is structured, and how to get started.

#### Acceptance Criteria

1. THE `README.md` SHALL contain the product name "DeoReoNem / 덜어냄" and a description of the product concept in no more than 3 sentences.
2. THE `README.md` SHALL describe the monorepo directory structure listing each top-level directory and its purpose.
3. THE `README.md` SHALL list the technology stack for both the Desktop_App and the API_Server covering all entries defined in `docs/02_ARCHITECTURE.md`.
4. THE `README.md` SHALL list each of the six documents available in `docs/` with a one-sentence description of each.
5. THE `README.md` SHALL state the MVP 0.1 in-scope items and out-of-scope items matching the lists defined in `docs/00_PRODUCT_SPEC.md`.
6. THE `README.md` SHALL include a "Getting Started" or equivalent section that tells a new developer what steps are needed to set up and run the project locally once product code exists.

---

### Requirement 3: Product Specification Document

**User Story:** As a product owner or developer, I want a product specification document, so that the full product vision, core UX feeling, and MVP scope are recorded in one place.

#### Acceptance Criteria

1. THE `docs/00_PRODUCT_SPEC.md` Spec_Document SHALL contain a named "Core Product Feeling" section with a table or list of at least 5 contrast pairs (e.g. "Not this → But this") illustrating the intended product tone versus anti-patterns.
2. THE `docs/00_PRODUCT_SPEC.md` Spec_Document SHALL define all seven Item categories (`NOW`, `TOMORROW`, `THIS_WEEK`, `WAITING`, `MEMO`, `WORRY_ONLY`, `DROP`), each entry providing both a meaning and a usage guideline.
3. THE `docs/00_PRODUCT_SPEC.md` Spec_Document SHALL describe the end-to-end MVP 0.1 Session flow as exactly 7 named steps — Step 1: Start Session, Step 2: Item Entry, Step 3: Item Classification, Step 4: First Action Selection, Step 5: Session Summary, Step 6: Complete Session, Step 7: Completion Screen — each describing both the user action and the system response.
4. THE `docs/00_PRODUCT_SPEC.md` Spec_Document SHALL list at least 14 features explicitly out of scope for MVP 0.1, covering at minimum: AI classification, push notifications, calendar sync, third-party integrations, team features, app store packaging, desktop tray, global shortcut, auto-launch, advanced analytics, mobile app, recurring templates, user authentication, and multi-language support.

---

### Requirement 4: Desktop UX Specification Document

**User Story:** As a UI/UX designer or Flutter developer, I want a desktop UX specification document, so that I can implement the correct screens, flow, and interaction design for the Windows desktop client.

#### Acceptance Criteria

1. THE `docs/01_DESKTOP_UX_SPEC.md` Spec_Document SHALL define all six screens in the Desktop_App for MVP 0.1 — Session Start, Item Entry, Item Classification, First Action Selection, Session Summary, and Completion Screen — each with a list of UI elements and their behaviors.
2. THE `docs/01_DESKTOP_UX_SPEC.md` Spec_Document SHALL contain a dedicated "Visual Tone" section that lists at least 3 named design principles (e.g. minimal, calm, compact) and provides a one-sentence rationale for each.
3. THE `docs/01_DESKTOP_UX_SPEC.md` Spec_Document SHALL describe the navigation flow as a linear sequence specifying, for each screen, which user action triggers the transition to the next screen.
4. THE `docs/01_DESKTOP_UX_SPEC.md` Spec_Document SHALL specify that the completion message "오늘은 여기까지 해도 됩니다." is displayed on the Completion Screen after the user triggers the complete session action, and that no additional CTAs or notifications appear on that screen.
5. THE `docs/01_DESKTOP_UX_SPEC.md` Spec_Document SHALL explicitly state that the Desktop_App targets Windows desktop as its primary platform for MVP 0.1, and that Flutter's cross-platform capability enables future targeting of mobile and other desktop platforms without rewriting the UI.

---

### Requirement 5: Architecture Document

**User Story:** As a backend or frontend developer, I want an architecture document, so that I understand how the Desktop_App and API_Server communicate, and what each layer is responsible for.

#### Acceptance Criteria

1. THE `docs/02_ARCHITECTURE.md` Spec_Document SHALL state that Flutter clients MUST NOT access the database directly, and that all data access goes through the REST_API.
2. THE `docs/02_ARCHITECTURE.md` Spec_Document SHALL specify that the API_Server exposes all endpoints under the versioned path `/api/v1`.
3. THE `docs/02_ARCHITECTURE.md` Spec_Document SHALL state that the API_Server owns authentication, persistence, business rules, and session sync.
4. THE `docs/02_ARCHITECTURE.md` Spec_Document SHALL specify that the Desktop_App uses `Dio` as its HTTP client for REST_API communication.
5. THE `docs/02_ARCHITECTURE.md` Spec_Document SHALL specify that the Desktop_App uses Riverpod for state management.
6. THE `docs/02_ARCHITECTURE.md` Spec_Document SHALL specify the API_Server technology stack: Java 21, Spring Boot 3.x, MyBatis, PostgreSQL 15+, Gradle, JUnit 5, Swagger/OpenAPI.
7. THE `docs/02_ARCHITECTURE.md` Spec_Document SHALL note that Spring Security integration is planned but deferred beyond MVP 0.1.
8. THE `docs/02_ARCHITECTURE.md` Spec_Document SHALL include a structural diagram (ASCII art or equivalent visual representation) illustrating the Desktop_App → REST_API → Database flow with labeled components and directional arrows or connectors.

---

### Requirement 6: API Specification Document

**User Story:** As a backend developer or API consumer, I want an API specification document, so that the REST API contract is defined clearly before implementation begins.

#### Acceptance Criteria

1. THE `docs/03_API_SPEC.md` Spec_Document SHALL define all REST_API endpoints required for MVP 0.1 Session flow, including: create session, get session, add item, update item category, select First_Action, delete item, complete session, and get session summary, all under the base path `/api/v1/decompression-sessions`.
2. THE `docs/03_API_SPEC.md` Spec_Document SHALL specify the HTTP method, URL path (including path parameters), request body, and response body for each endpoint.
3. THE `docs/03_API_SPEC.md` Spec_Document SHALL use the base path `/api/v1` for all endpoints, with session endpoints under `/api/v1/decompression-sessions`.
4. THE `docs/03_API_SPEC.md` Spec_Document SHALL specify that the API_Contract will be formally documented using OpenAPI/Swagger at runtime, accessible at `/swagger-ui.html`.
5. THE `docs/03_API_SPEC.md` Spec_Document SHALL define a standard error response envelope structure (with `success`, `error.code`, and `error.message` fields) and enumerate the named error codes used across all endpoints.
6. THE `docs/03_API_SPEC.md` Spec_Document SHALL specify that `isFirstAction` in item response DTOs is computed by comparing `itemId` with the session's `firstActionItemId`, and is not stored in the database.

---

### Requirement 7: Data Specification Document

**User Story:** As a backend developer or database administrator, I want a data specification document, so that the database schema and entity model are defined before implementation begins.

#### Acceptance Criteria

1. THE `docs/04_DATA_SPEC.md` Spec_Document SHALL define the `decompression_session` table schema with all columns: `session_id` (UUID, primary key), `status` (VARCHAR/ENUM, NOT NULL), `first_action_item_id` (UUID, nullable soft-reference to `decompression_item`), `completed_at` (TIMESTAMPTZ, nullable), `created_at` (TIMESTAMPTZ, NOT NULL, auto-set on insert), and `updated_at` (TIMESTAMPTZ, NOT NULL, managed by trigger).
2. THE `docs/04_DATA_SPEC.md` Spec_Document SHALL define the `decompression_item` table schema with all columns: `item_id` (UUID, primary key), `session_id` (UUID, NOT NULL, FK to `decompression_session`), `content` (VARCHAR(500), NOT NULL), `category` (VARCHAR/ENUM, nullable until classified), `sort_order` (INT, NOT NULL, preserves entry order), `created_at` (TIMESTAMPTZ, NOT NULL, auto-set on insert), and `updated_at` (TIMESTAMPTZ, NOT NULL, managed by trigger).
3. THE `docs/04_DATA_SPEC.md` Spec_Document SHALL define the allowed values for the `category` column as the enum: `NOW`, `TOMORROW`, `THIS_WEEK`, `WAITING`, `MEMO`, `WORRY_ONLY`, `DROP`, and SHALL specify that `category` is nullable (NULL is the valid state before an Item has been classified).
4. THE `docs/04_DATA_SPEC.md` Spec_Document SHALL specify that both `decompression_session` and `decompression_item` tables use PostgreSQL native `UUID` as their primary key type.
5. THE `docs/04_DATA_SPEC.md` Spec_Document SHALL specify `created_at` and `updated_at` as `TIMESTAMPTZ` columns for both tables, with `created_at` set automatically on insert and `updated_at` managed by a PostgreSQL trigger on every row change.
6. THE `docs/04_DATA_SPEC.md` Spec_Document SHALL specify that `isFirstAction` is NOT stored in `decompression_item`; it is computed in API response DTOs by comparing `item_id` with `decompression_session.first_action_item_id`.

---

### Requirement 8: Development Plan Document

**User Story:** As a developer, I want a phased development plan document, so that the implementation work is sequenced clearly and each phase has defined deliverables.

#### Acceptance Criteria

1. THE `docs/05_DEVELOPMENT_PLAN.md` Spec_Document SHALL define Phase 0 as project scaffolding and documentation with a checklist of deliverables matching the documents specified in Requirements 1–10.
2. THE `docs/05_DEVELOPMENT_PLAN.md` Spec_Document SHALL define Phase 1 as API_Server skeleton setup, including Spring Boot project creation, database schema migration, Swagger UI configuration, and a health check endpoint.
3. THE `docs/05_DEVELOPMENT_PLAN.md` Spec_Document SHALL define Phase 2 as MVP 0.1 backend implementation covering all 8 endpoints: `POST /decompression-sessions`, `GET /decompression-sessions/{id}`, `POST /decompression-sessions/{id}/items`, `PATCH /decompression-sessions/{id}/items/{itemId}/category`, `PUT /decompression-sessions/{id}/first-action`, `GET /decompression-sessions/{id}/summary`, `POST /decompression-sessions/{id}/complete`, and `DELETE /decompression-sessions/{id}/items/{itemId}` (all under `/api/v1`).
4. THE `docs/05_DEVELOPMENT_PLAN.md` Spec_Document SHALL define Phase 3 as Desktop_App Flutter skeleton setup and API integration for the complete MVP 0.1 session flow.
5. THE `docs/05_DEVELOPMENT_PLAN.md` Spec_Document SHALL explicitly list Spring Security and user authentication, Flutter mobile app implementation, and AI-assisted item classification as deferred to Phase 5 and beyond, not included in Phases 0–4.

---

### Requirement 9: Task Tracking Document

**User Story:** As a developer managing solo or small-team progress, I want a TASKS.md file, so that all pending, in-progress, and completed tasks are tracked in one place.

#### Acceptance Criteria

1. THE `TASKS.md` SHALL use a Markdown checklist format (`- [ ]` for incomplete, `- [x]` for complete) with three explicitly labelled sections in order: "Backlog", "In Progress", and "Completed".
2. THE `TASKS.md` SHALL include all Phase 0 documentation tasks as checklist items in the Completed section, since Phase 0 documentation is finished upon creation.
3. WHEN a task is completed, THE `TASKS.md` SHALL reflect the completed status by marking the checklist item with `- [x]` in-place without moving it to a different section, so that section membership reflects phase grouping rather than completion state.

---

### Requirement 10: Checkpoint and Work Log Documents

**User Story:** As a developer, I want CHECKPOINT.md and WORK_LOG.md files, so that I can record milestone decisions and daily progress for future reference.

#### Acceptance Criteria

1. THE `CHECKPOINT.md` SHALL contain a reusable template section that includes fields for: phase name, date, completion status, list of completed deliverables, key decisions made, current project state, known issues or open questions, and next phase description.
2. THE `WORK_LOG.md` SHALL contain a reusable dated entry template that includes fields for: date, summary of work done, list of specific items completed, blockers encountered, and what is planned next.
3. THE `CHECKPOINT.md` SHALL include a populated Phase 0 entry (not just the template) recording the completion of all Phase 0 documentation deliverables and listing the resolved technical decisions made during Phase 0.
