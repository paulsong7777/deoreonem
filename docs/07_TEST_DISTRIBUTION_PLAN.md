# DeoReoNem — Test Distribution Plan

**Version:** 0.3 RC
**Last Updated:** 2026-06-12

---

## Current Architecture Constraint

DeoReoNem desktop app requires:
- A running Spring Boot backend (`server/deoreonem_api`)
- A PostgreSQL 15+ database
- The app connects to `http://localhost:8080/api/v1`

Sending the Windows .exe ZIP alone does not work unless the API is reachable.

---

## Distribution Methods

### A. In-Person / Screen-Share Test (Recommended First)

1. Developer runs backend + PostgreSQL locally
2. Friend sits at the same machine or watches via screen share
3. Friend uses the app, developer observes and takes notes
4. Best for first 3 tests — immediate feedback, no setup burden on tester

### B. Remote Backend + Windows ZIP

**Target architecture:**
```
Friend's Windows app (deoreonem_desktop.exe)
    → HTTPS → https://deoreonem-api.scope-works.net/api/v1
        → Oracle Cloud server: Spring Boot backend
            → Oracle Cloud server: PostgreSQL
```

**Setup steps:**
1. Deploy Spring Boot backend to Oracle Cloud server
2. Configure HTTPS via `deoreonem-api.scope-works.net`
3. Update `DecompressionApiService` base URL to `https://deoreonem-api.scope-works.net/api/v1`
4. Build release: `flutter build windows --release`
5. ZIP the `build/windows/x64/runner/Release/` folder
6. Send ZIP to tester
7. Tester runs `deoreonem_desktop.exe` — connects to remote API

**Constraints:**
- No authentication in MVP 0.3 — anyone with the URL can access the API
- **Do not enter real company, customer, or private information**
- **Use test sentences only** during friend testing
- PostgreSQL is provisioned on the same Oracle Cloud server

### C. Later: Installer / MSIX (Post-MVP 0.3)

- Package as MSIX for Windows Store or sideloading
- Requires signing certificate
- Deferred until product is stable after friend testing

---

## Recommended Test Sequence

1. **3 in-person tests** — observe friend's reactions, collect UX feedback
2. **Fix critical issues** found during in-person tests
3. **1-2 remote ZIP tests** — verify the app works without developer present
4. **Collect written feedback** — simple form or chat notes
5. **Decide on public distribution** based on feedback

---

## Test Script (Suggested)

1. Launch app → first impression of the start screen
2. Tap "시작하기" → dump 3-5 thoughts (Korean, multiline)
3. Classify each item
4. Select first action (or skip)
5. Review summary → complete
6. Close → relaunch → check entrusted items
7. Let go of one item ("이제 괜찮아요")
8. Start a new session
9. Close with "그대로 두기" or "창 닫기"

---

## Feedback Questions

- 자연스럽게 쓸 수 있었나요?
- 어떤 부분이 어색하거나 혼란스러웠나요?
- 다시 사용하고 싶은 느낌이 들었나요?
- 앱을 닫을 때 기분이 어땠나요?
