# DeoReoNem — Product Specification

**Version:** 0.1 (MVP)
**Last Updated:** Phase 0

---

## 1. Product Concept

**DeoReoNem** (덜어냄) is a Digital Decompression app. It is not a to-do list, a project manager, or a habit tracker. It is a decompression ritual — a small, intentional act of setting down the mental load of work before transitioning to rest.

### The Problem

At the end of a workday, the brain doesn't automatically stop working. Unfinished tasks, lingering worries, and half-formed thoughts follow users into the evening. This makes it harder to rest, be present, and recover. The result: low-quality rest and diminished performance the next day.

### The Solution

DeoReoNem gives users a structured ritual to:
1. **Dump** — get everything out of their head
2. **Classify** — decide what each item actually means
3. **Entrust** — hand it off to tomorrow (or drop it entirely)
4. **Close** — receive a gentle signal that it's okay to stop

The app does not try to solve all the problems. It just helps users park them safely.

---

## 2. Core Product Feeling

This product must feel like a **brief, calm, purposeful ritual** — not a productivity dashboard.

| Feeling | Not This | But This |
|---|---|---|
| Size | Full-screen power app | Small, focused window |
| Tone | Urgent, action-packed | Calm, unhurried |
| Interaction | Complex workflows | Simple, linear flow |
| Feedback | Gamification, streaks | Quiet acknowledgment |
| Close | "You have 3 pending items" | "오늘은 여기까지 해도 됩니다." |

The completion message — *"오늘은 여기까지 해도 됩니다."* ("It's okay to stop here for today.") — is the emotional core of the product. The whole experience leads to this moment.

---

## 3. Item Categories

Each item entered during a session must be classified into one of the following seven categories:

| Category | Meaning | When to Use |
|---|---|---|
| `NOW` | Must be handled immediately, before sleeping | True urgency only — a production outage, a message that can't wait |
| `TOMORROW` | Intentionally saved for the next workday | The default for most unfinished work tasks |
| `THIS_WEEK` | Belongs somewhere in the current week, no specific day | Ongoing tasks, non-urgent follow-ups |
| `WAITING` | Blocked on someone else or an external event | "Waiting for client feedback", "Waiting for merge" |
| `MEMO` | Worth remembering but requires no action | Ideas, references, things not to forget |
| `WORRY_ONLY` | A worry with no actionable resolution today | Acknowledged, not acted on — parked with care |
| `DROP` | Not worth carrying forward at all | Discard cleanly and intentionally |

### Category Philosophy

- `NOW` should be rare. If everything is NOW, nothing is.
- `WORRY_ONLY` is not giving up — it is honest recognition that some things can't be solved tonight.
- `DROP` is an act of intentional release, not laziness.
- The goal is for most items to land in `TOMORROW` or `THIS_WEEK` — safe, clear, and accounted for.

---

## 4. MVP 0.1 Session Flow

A single Session represents one decompression ritual. The flow is linear and guided.

### Step 1: Start Session
- The user opens DeoReoNem.
- A start screen presents a brief, calm prompt: *"오늘 머릿속에 남아있는 것들을 꺼내 보세요."* ("Empty what's lingering in your mind today.")
- The user presses "Start" to begin.

### Step 2: Item Entry
- The user types items one at a time into a simple input field.
- Each item is added to a list as a card.
- The user continues until they feel the dump is complete.
- Items have no category yet — this is the raw dump phase.

### Step 3: Item Classification
- The user reviews each item and selects one of the 7 categories.
- Classification is done item by item.
- The UI presents the category options clearly for each item.

### Step 4: First Action Selection
- After classification, the user picks **one** item as their First Action for tomorrow.
- Only items in `NOW`, `TOMORROW`, or `THIS_WEEK` categories are eligible.
- This is the single most important thing to do when work resumes.

### Step 5: Session Summary
- The user sees a summary of all classified items grouped by category.
- The First Action is highlighted.
- A count of total items entrusted is displayed.

### Step 6: Complete Session
- The user presses "Complete" (or equivalent).
- The API_Server persists the final session state.

### Step 7: Completion Screen
- A calm, full-content screen is shown.
- It displays: *"오늘은 여기까지 해도 됩니다."*
- No urgency, no CTAs, no notifications.
- A quiet close button is available.

---

## 5. Out of Scope — MVP 0.1

The following features are explicitly deferred. They may appear in future versions but must not be built or planned for MVP 0.1:

- AI-based item classification or suggestions
- Push notifications (desktop or mobile)
- Calendar integration (Google Calendar, Outlook)
- Third-party integrations (Slack, Gmail, Notion, KakaoTalk)
- Team or shared workspace features
- App Store or Microsoft Store packaging
- Desktop system tray integration
- Global keyboard shortcut / hotkey registration
- Auto-launch on system startup
- Advanced analytics, trends, or reporting
- Mobile app implementation (iOS / Android)
- Recurring item templates
- User authentication (deferred to post-MVP backend phase)
- Multi-language support beyond Korean/English content

---

## 6. Target User

The primary user of DeoReoNem in MVP 0.1 is:

- A knowledge worker (developer, designer, PM, writer, etc.)
- Who works primarily on a Windows desktop
- Who struggles to mentally "leave" work at the end of the day
- Who wants a lightweight, private ritual — not another system to maintain

The product respects the user's time. A session should take 5–10 minutes, not 30.
