# DeoReoNem — Desktop UX Specification

**Version:** 0.1 (MVP)
**Platform:** Windows Desktop (Flutter)
**Last Updated:** Phase 0

---

## 1. Visual Tone & Design Philosophy

DeoReoNem is a **mini desktop app**, not a full-screen productivity suite. The visual design must reflect this.

### Principles

| Principle | Description |
|---|---|
| **Calm** | No bright accent colors, no urgent red badges, no progress bars urging completion |
| **Minimal** | Only what is needed for the current step. No clutter. |
| **Warm** | Slightly warm neutrals (off-white, warm grays) rather than cold tech blues |
| **Focused** | One task at a time. The UI guides without overwhelming. |
| **Human** | Gentle Korean/English language. Not system-speak. |

### Window Size

- Default window: approximately **480 × 680px** (compact, not full-screen)
- The window should feel like a notepad or small utility — not a web app
- Resizing: optional for MVP; fixed size is acceptable
- Window title: *"덜어냄"* or *"DeoReoNem"*

### Typography

- Clean sans-serif font (e.g., Noto Sans KR for Korean support)
- Generous line height for readability
- Body text: 14–16px equivalent
- Headings: 18–22px equivalent, light weight

### Colors (Suggested Palette)

| Role | Value |
|---|---|
| Background | `#F9F7F4` (warm off-white) |
| Surface / card | `#FFFFFF` |
| Border | `#E8E4DF` |
| Primary text | `#2C2C2C` |
| Secondary text | `#8A8380` |
| Accent (calm) | `#7B9E87` (muted sage green) |
| Drop / dismiss | `#C4A882` (warm sand) |

---

## 2. Screen Inventory

### Screen 1: Start Screen

**Purpose:** Entry point. Set the tone. Invite the user to begin.

**Elements:**
- App name: *"덜어냄"* (large, centered, light weight)
- Subtitle prompt: *"오늘 머릿속에 남아있는 것들을 꺼내 보세요."*
- Start button: *"시작하기"* ("Start")
- Version number (small, footer)

**Behavior:**
- Tapping "Start" creates a new Session via API and navigates to Item Entry.
- No authentication in MVP 0.1.

**Navigation:** → Item Entry Screen

---

### Screen 2: Item Entry Screen

**Purpose:** Raw dump phase. The user empties their mind without judgment.

**Elements:**
- Screen title: *"오늘 남은 것들"* ("What's left from today")
- Text input field: placeholder *"생각, 걱정, 할 일... 하나씩 적어보세요"*
- Add button (or Enter key) to add item to list
- Item list (cards, added in order)
  - Each card shows the item text
  - Each card shows a delete (×) button
- "Next: Classify" button — enabled once at least one item is added

**Behavior:**
- Pressing Enter or the Add button adds the typed text as a new Item card and clears the input.
- Items are saved to the API as they are added.
- The list is scrollable if many items are added.
- Empty input cannot be submitted.

**Navigation:** → Item Classification Screen

---

### Screen 3: Item Classification Screen

**Purpose:** The user assigns a category to each item, one at a time.

**Layout Option A (One at a time):**
- Shows one item card at the top
- 7 category buttons displayed below
- Progress indicator: *"3 / 7 분류됨"* ("3 of 7 classified")
- Tapping a category assigns it and advances to the next item

**Layout Option B (All at once):**
- Shows all item cards in a list
- Each card has a dropdown or button row for category selection
- "Next" button enabled when all items are classified

> **MVP Recommendation:** Option A (one at a time) — keeps the user focused and the window uncluttered.

**Category Display:**

Each category button shows:
- Category label in Korean and/or English
- Short description (1 line)

| Button | Korean Label | Short Description |
|---|---|---|
| NOW | 지금 | 오늘 안에 반드시 |
| TOMORROW | 내일 | 내일 첫 번째로 |
| THIS_WEEK | 이번 주 | 이번 주 안에 |
| WAITING | 대기 중 | 누군가를 기다리는 중 |
| MEMO | 메모 | 기억해두기 |
| WORRY_ONLY | 걱정만 | 지금은 어쩔 수 없는 걱정 |
| DROP | 버리기 | 내려놓기 |

**Navigation:** → First Action Selection Screen

---

### Screen 4: First Action Selection Screen

**Purpose:** Choose the single most important thing to do when work resumes.

**Elements:**
- Prompt: *"내일 가장 먼저 할 일 하나를 고르세요."* ("Choose one thing to do first tomorrow.")
- List of eligible items (category: `NOW`, `TOMORROW`, `THIS_WEEK`)
- Each item is selectable (radio button or tap to highlight)
- "Skip" option if the user does not want to pick (optional for MVP)
- "Next" button

**Behavior:**
- Only items in `NOW`, `TOMORROW`, `THIS_WEEK` are shown.
- Selected item is highlighted with the accent color.
- Selection is sent to API.

**Navigation:** → Session Summary Screen

---

### Screen 5: Session Summary Screen

**Purpose:** Show the user what they've entrusted to the system.

**Elements:**
- Title: *"오늘의 덜어냄"* ("Today's DeoReoNem")
- Items grouped by category (each group is a collapsible or flat list)
- First Action highlighted at the top with a star or accent
- Total count: *"총 N개를 맡겼습니다."* ("You've entrusted N items.")
- "완료하기" ("Complete") button

**Behavior:**
- Read-only. No editing on this screen.
- Complete button triggers session completion API call.

**Navigation:** → Completion Screen

---

### Screen 6: Completion Screen

**Purpose:** The emotional close of the session. Permission to rest.

**Elements:**
- The message, large and centered:
  > *"오늘은 여기까지 해도 됩니다."*
- Small subtitle (optional): *"수고하셨어요."* ("You worked hard.")
- Quiet close button: *"닫기"* ("Close") — subtle, small, bottom-aligned
- No urgency. No "What's next?" prompts. No notifications.

**Behavior:**
- Close button closes the app window.
- No navigation back to session from this screen.

**Visual Treatment:**
- Background may be slightly different (e.g., a subtle warm tint) to signal a mode change
- Large, unhurried typography
- No icons, badges, or progress indicators

---

## 3. Navigation Flow

```
Start Screen
    │
    ▼ [Start]
Item Entry Screen
    │
    ▼ [Next: Classify]
Item Classification Screen
    │
    ▼ [All classified]
First Action Selection Screen
    │
    ▼ [Next]
Session Summary Screen
    │
    ▼ [Complete]
Completion Screen
    │
    ▼ [Close]
(app closes)
```

The flow is strictly linear in MVP 0.1. There is no back navigation once the session begins (or back navigation is limited to the step directly before). Users cannot edit a completed session.

---

## 4. Error and Loading States

### Loading States
- Async API calls show a subtle inline spinner (not a full-screen loader)
- The "Next" or "Complete" button is disabled while a call is in flight

### Error States
- If an API call fails: show an inline, non-alarming message — *"연결에 문제가 생겼어요. 다시 시도해 주세요."*
- No modal popups for transient errors
- Retry button available

### Empty State
- Item Entry: if the list is empty, the "Next" button is disabled
- First Action: if no eligible items exist, the step is skipped or shows a gentle message

---

## 5. Platform Notes

### Windows Desktop (MVP 0.1)
- Target: Windows 10 and Windows 11
- Window decorations: default Flutter window frame (custom titlebar optional, deferred)
- No system tray integration in MVP 0.1
- No global keyboard shortcuts in MVP 0.1
- App launched manually by the user

### Future Platforms
Flutter enables DeoReoNem to expand to:
- macOS desktop
- Linux desktop
- iOS mobile
- Android mobile

The same session flow and API contract apply across all platforms. Mobile layouts will require separate UX adaptation (not in this spec).
