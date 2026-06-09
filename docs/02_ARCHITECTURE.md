# DeoReoNem — Architecture

**Version:** 0.1 (MVP)
**Last Updated:** Phase 0

---

## 1. System Overview

DeoReoNem follows a **client-server architecture** with a clear separation of concerns:

- The **Flutter Desktop App** is a thin client responsible only for UI rendering, user interaction, and API communication.
- The **Spring Boot API Server** owns all business logic, data persistence, authentication, and cross-client sync.
- A **PostgreSQL 15+** relational database stores all persistent data and is accessible only to the API Server.

### Core Architecture Principle

> **Flutter clients MUST NOT access the database directly.**
> All data access goes exclusively through the REST API.

This ensures that:
- Business logic lives in one place (the backend)
- The same API can serve both the Flutter desktop app and future Flutter mobile app
- The database schema can evolve independently of client code
- Security and validation are enforced at the API layer

---

## 2. Component Diagram

```
┌─────────────────────────────────────────────────┐
│              User's Windows Desktop              │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │        Flutter Desktop App                 │  │
│  │  (apps/deoreonem_desktop)                  │  │
│  │                                            │  │
│  │  UI Layer         State Layer              │  │
│  │  (Screens/        (Riverpod)              │  │
│  │       │                │                  │  │
│  │       └────────┬───────┘                  │  │
│  │                │                          │  │
│  │         API Client Layer                  │  │
│  │         (Dio HTTP Client)                 │  │
│  └────────────────┼───────────────────────────┘  │
└───────────────────┼─────────────────────────────┘
                    │
             HTTPS / REST
             /api/v1/...
                    │
┌───────────────────▼─────────────────────────────┐
│          Spring Boot API Server                  │
│          (server/deoreonem_api)                  │
│                                                  │
│  Controller Layer  (/api/v1/*)                  │
│       │                                          │
│  Service Layer     (Business Logic)              │
│       │                                          │
│  Repository Layer  (MyBatis Mappers)             │
│       │                                          │
│  OpenAPI / Swagger (API Documentation)           │
└───────────────────┬─────────────────────────────┘
                    │
              JDBC / MyBatis
                    │
┌───────────────────▼─────────────────────────────┐
│         PostgreSQL 15+                           │
│                                                  │
│   decompression_session  │  decompression_item   │
└──────────────────────────────────────────────────┘
```

---

## 3. Flutter Desktop Client

**Directory:** `apps/deoreonem_desktop`

### Responsibilities
- Render all UI screens (Start, Item Entry, Classification, First Action, Summary, Completion)
- Manage local UI state and screen navigation
- Call the REST API for all data operations
- Handle API errors gracefully and display user-friendly messages

### Technology Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter (Dart) | Enables future mobile/desktop targets |
| Primary target | Windows desktop | MVP 0.1 |
| HTTP client | Dio | Interceptors, error handling, timeout config |
| State management | Riverpod | Selected for MVP 0.1 |
| Local persistence | None (MVP 0.1) | Deferred |
| Authentication | None (MVP 0.1) | Deferred |

### API Communication Rules
- All API calls use the base URL configured at build time (e.g., `http://localhost:8080/api/v1`)
- Dio interceptors handle request logging and error normalization
- All responses are deserialized into typed Dart model classes
- Network errors show non-alarming inline messages; no crash dialogs

---

## 4. Spring Boot API Server

**Directory:** `server/deoreonem_api`

### Responsibilities
- Expose all REST API endpoints under `/api/v1`
- Validate all incoming request data
- Execute business rules for session and item management
- Persist all data via MyBatis to the relational database
- Serve the OpenAPI/Swagger documentation UI
- Enforce authentication and authorization (deferred to post-MVP)

### Technology Stack

| Concern | Choice | Notes |
|---|---|---|
| Language | Java 21 | LTS release |
| Framework | Spring Boot 3.x | Auto-configuration, embedded server |
| SQL mapping | MyBatis | Explicit SQL control, no ORM magic |
| Database | PostgreSQL 15+ | Selected for MVP 0.1 |
| Build tool | Gradle | Selected for MVP 0.1 |
| Testing | JUnit 5 | Unit + integration tests |
| API docs | Swagger / OpenAPI 3 | springdoc-openapi |
| Authentication | Spring Security | **Deferred — not in MVP 0.1** |

### Layer Structure

```
server/deoreonem_api/src/main/java/
└── com.deoreonem.api/
    ├── controller/     # REST controllers (@RestController)
    ├── service/        # Business logic (@Service)
    ├── mapper/         # MyBatis mapper interfaces
    ├── model/          # Domain entities (Session, Item)
    ├── dto/            # Request/response DTOs
    ├── config/         # Spring config (CORS, Swagger, etc.)
    └── exception/      # Global exception handling
```

---

## 5. Database

**Access:** Exclusively through the API Server via MyBatis.

**Database:** PostgreSQL 15+

**Schema:** See `docs/04_DATA_SPEC.md` for full table definitions.

**Key Tables:**
- `decompression_session` — one row per decompression session
- `decompression_item` — one row per item within a session

---

## 6. API Contract

All communication between clients and the API Server uses:
- **Protocol:** HTTP/HTTPS
- **Format:** JSON (request and response bodies)
- **Base path:** `/api/v1`
- **Session endpoints:** `/api/v1/decompression-sessions`
- **Versioning:** URL-based (`/api/v1`, `/api/v2`, etc.)
- **Documentation:** OpenAPI 3.x spec served at `/swagger-ui.html` and `/v3/api-docs`

The OpenAPI spec is the **source of truth** for the client–server contract. Any change to API behavior must be reflected in the spec.

See `docs/03_API_SPEC.md` for endpoint definitions.

---

## 7. CORS Configuration

During development, the API Server will allow cross-origin requests from the Flutter desktop app's local origin. For MVP 0.1, a permissive CORS config is acceptable. Tighten for production.

---

## 8. Authentication (Deferred)

Spring Security is included as a planned dependency but is **not activated in MVP 0.1**.

Future authentication design (post-MVP):
- JWT-based stateless authentication
- `/api/v1/auth/login`, `/api/v1/auth/register` endpoints
- All session/item endpoints require a valid JWT
- User entity and ownership model for sessions

---

## 9. Future Platform Expansion

The architecture is designed to support additional clients without backend changes:

| Future Client | Status |
|---|---|
| Flutter mobile (iOS/Android) | Planned post-MVP |
| macOS / Linux desktop | Possible via Flutter |
| Web app | Not planned (desktop-first philosophy) |

All clients consume the same `/api/v1` REST API, ensuring consistency and reducing backend duplication.
