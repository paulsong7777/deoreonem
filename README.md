# DeoReoNem / 덜어냄

> *"오늘은 여기까지 해도 됩니다."*
> *"It's okay to stop here for today."*

---

## What is DeoReoNem?

**DeoReoNem** (덜어냄 — "to set down", "to unburden") is a desktop-first Digital Decompression app.

At the end of a workday, it's easy to carry unfinished thoughts, worries, and loose tasks into the evening. DeoReoNem gives you a small, calm space to dump that mental residue — classify each item, pick one thing to care about tomorrow, and then let go.

This is not a full-screen productivity system. It's a lightweight mini desktop app you open briefly at the end of work, spend 5 minutes in, and close — leaving work at work.

---

## Repository Structure

This is a monorepo containing all components of the DeoReoNem platform.

```
deoreonem/
├── apps/
│   └── deoreonem_desktop/     # Flutter Windows desktop client (MVP 0.1)
├── server/
│   └── deoreonem_api/         # Spring Boot 3.x REST API backend
├── docs/
│   ├── 00_PRODUCT_SPEC.md     # Product concept, UX feeling, MVP scope
│   ├── 01_DESKTOP_UX_SPEC.md  # Screen-by-screen UX specification
│   ├── 02_ARCHITECTURE.md     # System architecture and component diagram
│   ├── 03_API_SPEC.md         # REST API contract and endpoint definitions
│   ├── 04_DATA_SPEC.md        # Database schema and entity model
│   └── 05_DEVELOPMENT_PLAN.md # Phased development plan
├── README.md                  # This file
├── TASKS.md                   # Task tracking (Backlog / In Progress / Done)
├── CHECKPOINT.md              # Phase milestone records
└── WORK_LOG.md                # Daily work session log
```

---

## Technology Stack

### Flutter Desktop Client (`apps/deoreonem_desktop`)

| Concern | Choice |
|---|---|
| Framework | Flutter / Dart |
| Primary target | Windows desktop (MVP 0.1) |
| Future targets | macOS, Linux, Mobile (Flutter) |
| HTTP client | Dio |
| State management | Riverpod |
| Local persistence | Deferred (post-MVP) |

### Spring Boot API Server (`server/deoreonem_api`)

| Concern | Choice |
|---|---|
| Language | Java 21 |
| Framework | Spring Boot 3.x |
| ORM / SQL | MyBatis |
| Database | PostgreSQL 15+ |
| Build tool | Gradle |
| Testing | JUnit 5 |
| API Documentation | Swagger / OpenAPI |
| Authentication | Spring Security (deferred, post-MVP) |

---

## MVP 0.1 Scope

### In Scope

- Small Flutter Windows desktop shell
- Start a decompression session
- Add lingering thoughts, worries, or unfinished tasks as Items
- Classify each Item into one of 7 categories: `NOW`, `TOMORROW`, `THIS_WEEK`, `WAITING`, `MEMO`, `WORRY_ONLY`, `DROP`
- Choose one First Action for tomorrow
- View a session summary of entrusted items
- Complete the session
- Calm completion screen: *"오늘은 여기까지 해도 됩니다."*
- Spring Boot REST API covering the full session flow
- Database persistence for sessions and items
- Swagger / OpenAPI documentation of the API

### Out of Scope (MVP 0.1)

- AI-based item classification
- Push notifications
- Calendar sync
- Integrations (Slack, Gmail, Notion, KakaoTalk)
- Team / shared workspace features
- App store packaging
- Desktop system tray icon
- Global keyboard shortcut
- Auto-launch on startup
- Advanced analytics or reporting
- Mobile app implementation

---

## Documentation

| Document | Description |
|---|---|
| `docs/00_PRODUCT_SPEC.md` | Product vision, UX feeling, session flow, item categories |
| `docs/01_DESKTOP_UX_SPEC.md` | Screen designs, navigation flow, visual tone |
| `docs/02_ARCHITECTURE.md` | Component architecture, API contract principles, tech decisions |
| `docs/03_API_SPEC.md` | REST API endpoints, request/response formats, error handling |
| `docs/04_DATA_SPEC.md` | Database schema for sessions and items |
| `docs/05_DEVELOPMENT_PLAN.md` | Phased implementation plan |

---

## Architecture Principles

1. **Flutter clients never touch the database directly.** All data access goes through the REST API.
2. **The API server owns everything.** Authentication, persistence, business rules, and sync are backend responsibilities.
3. **Versioned API.** All endpoints live under `/api/v1`.
4. **API contract first.** The OpenAPI/Swagger spec is the source of truth for the client–server contract.
5. **Same API for all clients.** The Flutter desktop and future Flutter mobile apps consume the same REST API.

---

## Status

> **Current phase: MVP 0.1 — Live and verified**

Full end-to-end flow verified: Start → Dump → Classify → First Action → Summary → Complete → Close.

See `TASKS.md` for current task status and `CHECKPOINT.md` for milestone records.

---

## Getting Started

### Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Java | 21+ | Spring Boot backend |
| Flutter | 3.41+ | Desktop client |
| Docker | any | PostgreSQL database |
| Visual Studio | 2022+ with "Desktop development with C++" | Flutter Windows build |

### 1. Start PostgreSQL

```bash
docker run -d -p 5432:5432 \
  -e POSTGRES_DB=deoreonem \
  -e POSTGRES_USER=deoreonem \
  -e POSTGRES_PASSWORD=deoreonem \
  --name deoreonem-db \
  postgres:15
```

### 2. Start the Backend

```bash
cd server/deoreonem_api
./gradlew.bat bootRun --no-daemon
```

Verify: `curl http://localhost:8080/api/v1/health` → `{"status":"UP","service":"deoreonem-api","version":"0.1.0"}`

Swagger UI: http://localhost:8080/swagger-ui/index.html

### 3. Run the Flutter Desktop App

```bash
cd apps/deoreonem_desktop
flutter run -d windows
```

### 4. Run from Release Build

```bash
cd apps/deoreonem_desktop
flutter build windows --release
```

The executable is at: `build/windows/x64/runner/Release/deoreonem_desktop.exe`

You can copy the entire `Release/` folder to another machine and run `deoreonem_desktop.exe` directly. The backend must be running at `http://localhost:8080`.

---

## Running Tests

### Backend Tests

```bash
cd server/deoreonem_api
./gradlew.bat test --no-daemon
```

28 tests: service unit tests + controller tests (no database required for tests).

### Flutter Tests

```bash
cd apps/deoreonem_desktop
flutter test
```

36 tests: model serialization + API service + providers + widget tests (all mocked, no network required).

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `Connection refused: localhost:5432` | Start the PostgreSQL Docker container |
| `flutter run` fails with C4819/C2001 error | Window title uses Unicode escapes — ensure `main.cpp` is UTF-8 |
| MyBatis UUID type handler error | `UuidTypeHandler` is registered in `application.yml` via `type-handlers-package` |
| `SystemNavigator.pop()` doesn't close app | CompletionScreen uses `dart:io exit(0)` for Windows |
| Flutter `flutter doctor` shows Visual Studio missing | Install "Desktop development with C++" workload |
| Backend Flyway error on fresh DB | Ensure PostgreSQL database `deoreonem` exists; Flyway auto-applies V1-V3 |
