# DeoReoNem — Desktop Garden Overlay Plan

**Version:** 0.4-alpha
**Last Updated:** 2025-06-13

---

## Product Intent

The desktop garden overlay is a quiet visual trace of worries that the user has consciously let go.
It sits on the desktop as a small ground patch where let-go worries quietly seep in and grow a tree.

- This is not a game character.
- This is not a farming game.
- This is not a reward system.
- The user does not need to tend or feed the tree.

Visual metaphor: "내려놓은 걱정이 작은 자리에 스며들어 조용히 나무가 자란다."

---

## What is included in 0.4-alpha

- Same-exe garden overlay mode via `--garden` argument
- `window_manager` for frameless, always-on-top, compact window
- `QuietGardenPatch` widget with CustomPaint tree stages
- Reads existing `total_worry_nutrients` from SharedPreferences
- Draggable overlay window
- Plant stage helper with garden-oriented messages
- "작은 자리 보기" launcher from main app (spawns overlay process)

---

## What is deferred

- Live cross-process nutrient sync (overlay updates on reopen for now)
- Official Windows Widget panel integration
- Tree customization / seasons / weather
- Stickers / decorations / wallpaper
- Animation beyond basic static rendering
- Install/startup automation (auto-launch garden on boot)
- Multi-display positioning
- Drag position persistence

---

## Technical Path

**Chosen: A) Same-exe garden mode with window_manager**

The app detects `--garden` in `main(args)` and launches a small overlay window.
No multi-window plugin needed. One executable, two modes.

---

## Manual Verification Checklist

1. Run: `deoreonem_desktop.exe` → normal app opens
2. Run: `deoreonem_desktop.exe --garden` → small overlay opens
3. Overlay shows ground patch + tree stage visual
4. Overlay is frameless, compact (~220x160)
5. Overlay is always-on-top
6. Overlay can be dragged
7. Overlay shows calm Korean message
8. Normal app "작은 자리 보기" launches overlay process
9. Letting go of a worry updates nutrient count
10. Reopening garden overlay reflects updated nutrient count

---

## Known Risks

- `window_manager` transparency may not work on all Windows versions
- Process.start may not detach cleanly on all environments
- Developer Mode still required for shared_preferences plugin symlinks
