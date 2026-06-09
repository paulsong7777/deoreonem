# DeoReoNem — Development Plan

**Version:** 0.1 (MVP)
**Last Updated:** Phase 0

---

## Overview

This document outlines the phased implementation plan for DeoReoNem MVP 0.1. Each phase has a clear scope, defined deliverables, and explicit boundaries. Work within a phase should be completed and reviewed before the next phase begins.

The goal is to reach a working end-to-end MVP: a Flutter Windows desktop app that communicates with a Spring Boot API, persists sessions to a database, and delivers the full decompression session experience.

---

## Phase 0 — Documentation & Scaffolding

**Status:** ✅ In Progress

**Goal:** Establish the project structure and all steering documentation before any product code is written. This phase ensures the architecture, API contract, data model, and UX are understood and agreed upon.

### Deliverables
- [x] Monorepo directory structure created
- [x] `README.md` — Project overview and stack summary
- [x] `docs/00_PRODUCT_SPEC.md` — Product concept, session flow, item categories
- [x] `docs/01_DESKTOP_UX_SPEC.md` — Screen-by-screen UX specification
- [x] `docs/02_ARCHITECTURE.md` — System architecture and component diagram
- [x] `docs/03_API_SPEC.md` — REST API endpoints and contracts
- [x] `docs/04_DATA_SPEC.md` — Database schema definitions
- [x] `docs/05_DEVELOPMENT_PLAN.md` — This document
- [x] `TASKS.md` — Task tracking initialized
- [x] `CHECKPOINT.md` — Checkpoint log initialized
- [x] `WORK_LOG.md` — Work log initialized
- [ ] `.kiro/specs/deoreonem-project-setup/requirements.md` — Kiro requirements spec

### Exit Criteria
All documents reviewed and accepted. No product code written.

---

## Phase 1 — API Server Skeleton

**Status:** 🔜 Not started

**Goal:** Create the Spring Boot project structure, connect to the database, define the schema, and verify the Swagger UI loads. No business logic yet — just the skeleton.

### Deliverables
- [ ] Spring Boot project scaffolded (`server/deoreonem_api`)
  - Java 21, Spring Boot 3.x, MyBatis, PostgreSQL driver
  - `build.gradle` with all dependencies pinned
  - Application properties configured (dev profile)
- [ ] PostgreSQL 15+ connection verified
- [ ] Schema created (`decompression_session` and `decompression_item` tables)
- [ ] `updated_at` trigger created for both tables
- [ ] MyBatis configured and basic connectivity test passes
- [ ] `springdoc-openapi` dependency added
- [ ] Swagger UI accessible at `/swagger-ui.html`
- [ ] Health check endpoint: `GET /api/v1/health` returns `{"status": "ok"}`
- [ ] CORS configured for local Flutter dev
- [ ] Project compiles and starts without errors

### Tech Decisions Required
- ~~MySQL vs PostgreSQL~~ → **PostgreSQL 15+**
- ~~UUID vs auto-increment for PKs~~ → **UUID**
- ~~Gradle vs Maven~~ → **Gradle**

### Exit Criteria
Spring Boot starts cleanly. Swagger UI loads. Database schema in place. Health endpoint responds.

---

## Phase 2 — MVP 0.1 Backend Implementation

**Status:** 🔜 Not started

**Goal:** Implement all REST API endpoints for the full session flow, with full persistence, validation, and error handling.

### Deliverables
- [ ] `DecompressionSession` entity and `decompression_session` mapper
- [ ] `DecompressionItem` entity and `decompression_item` mapper
- [ ] `POST /api/v1/decompression-sessions` — Create session
- [ ] `GET /api/v1/decompression-sessions/{id}` — Get session with items (ordered by sort_order)
- [ ] `POST /api/v1/decompression-sessions/{id}/items` — Add item (assign sort_order)
- [ ] `PATCH /api/v1/decompression-sessions/{id}/items/{itemId}/category` — Classify item
- [ ] `PUT /api/v1/decompression-sessions/{id}/first-action` — Set first action (update session.first_action_item_id)
- [ ] `GET /api/v1/decompression-sessions/{id}/summary` — Session summary (compute isFirstAction in DTO)
- [ ] `POST /api/v1/decompression-sessions/{id}/complete` — Complete session
- [ ] `DELETE /api/v1/decompression-sessions/{id}/items/{itemId}` — Delete item
- [ ] Global exception handler with consistent error envelope
- [ ] Input validation on all request bodies (`@Valid`, Bean Validation)
- [ ] JUnit 5 tests for service layer
- [ ] JUnit 5 integration tests for at least: create session, add item, classify, complete
- [ ] Swagger annotations on all endpoints
- [ ] All endpoints verified via Swagger UI manually

### Exit Criteria
All 8 endpoints pass their integration tests. Swagger UI shows full API. Manual end-to-end session flow works via Swagger.

---

## Phase 3 — Flutter Desktop Shell & API Integration

**Status:** 🔜 Not started

**Goal:** Build the Flutter Windows desktop app for MVP 0.1, integrating with the Phase 2 API.

### Deliverables
- [ ] Flutter project scaffolded (`apps/deoreonem_desktop`)
  - Windows desktop target enabled
  - Dio, Riverpod dependencies added
- [ ] App shell: window size, fonts, color theme applied
- [ ] API client service using Dio with base URL config
- [ ] Dart model classes for Session and Item (matching API DTOs)
- [ ] Screen 1: Start Screen — creates session via API
- [ ] Screen 2: Item Entry — adds items via API, live list
- [ ] Screen 3: Item Classification — classifies items via API
- [ ] Screen 4: First Action Selection — sets first action via API
- [ ] Screen 5: Session Summary — fetches and displays summary
- [ ] Screen 6: Completion Screen — completes session, shows final message
- [ ] Navigation flow wired end-to-end
- [ ] Loading states on async calls
- [ ] Inline error messages on API failures
- [ ] App tested manually on Windows: full session flow from start to completion screen

### Exit Criteria
Full session flow works end-to-end on Windows: open app → add items → classify → pick first action → view summary → complete → see "오늘은 여기까지 해도 됩니다." → close.

---

## Phase 4 — Polish, Testing & MVP 0.1 Release

**Status:** 🔜 Not started

**Goal:** Harden the MVP, fix edge cases, improve UX details, and produce a distributable build.

### Deliverables
- [ ] Edge case handling: empty sessions, network offline, server errors
- [ ] Visual polish pass on all screens
- [ ] Flutter widget tests for key screens
- [ ] Backend load tested informally (basic sanity)
- [ ] README updated with setup and run instructions
- [ ] Windows build (`flutter build windows`) verified
- [ ] Distributable `.exe` or MSIX package created (basic)

### Exit Criteria
App is demonstrable without crashes. Build artifact runs on a clean Windows machine.

---

## Deferred Phases (Post-MVP)

| Phase | Description |
|---|---|
| Phase 5 | Spring Security: user authentication (JWT), multi-user sessions |
| Phase 6 | Flutter mobile app (iOS/Android) using the same API |
| Phase 7 | AI-assisted item classification |
| Phase 8 | Cross-device sync, calendar integration |

---

## Technology Decisions Log

| Decision | Options Considered | Chosen | Phase | Notes |
|---|---|---|---|---|
| Database | MySQL 8.x, PostgreSQL 15.x | **PostgreSQL 15+** | Phase 0 | Resolved |
| Primary key | UUID, Auto-increment BIGINT | **UUID** | Phase 0 | Native UUID type in PostgreSQL |
| Build tool | Maven, Gradle | **Gradle** | Phase 0 | Resolved |
| State mgmt (Flutter) | Provider, Riverpod | **Riverpod** | Phase 0 | Resolved |
| Authentication | JWT, Session | JWT (deferred) | Phase 5 | Stateless API aligns with mobile clients |
