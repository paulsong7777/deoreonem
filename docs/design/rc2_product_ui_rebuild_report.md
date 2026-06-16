# RC2 Product UI Rebuild Report

## Summary

Full product UI rebuilt from approved source-of-truth reference boards A and B.

**Build Status**: ✅ All tests passing (134/134), release build successful.

---

## Changes Made

### Design Tokens (`lib/design/app_tokens.dart`)
- Updated all color values to match Reference A board exactly
- Added new tokens: sageLight, ivory, warmWhite, sand, charcoal, softBlue, lavender
- Updated typography: titleBanner (48pt), heading (24pt), body (16pt), caption (13pt)
- Updated spacing: radiusLarge→20, radiusCard→14, sectionGap→24

### Plant Stage System (`lib/services/plant_stage_helper.dart`)
- Expanded from 5 stages to 9 stages per Reference B
- New thresholds: 0/1/4/7/11/16/22/30/40
- All stage messages updated to new Korean copy

### Quiet Tree Overlay (`lib/widgets/quiet_garden_patch.dart`)
- Added MouseRegion hover interaction (scale 1.02 + translate -2px)
- Added wind animation controller (8s cycle, ±3° + ±2px lateral)
- Combined idle sway + wind + hover animations
- CustomPaint expanded for all 9 stages with progressive canopy/trunk detail
- Branches drawn for stages 5+, extra branches for stages 7+

### Garden Overlay (`lib/garden_overlay.dart`)
- Window size updated to 250×280

### Screen Headings (all screens)
- StartScreen: "덜어냄" banner (48pt), tree preview without card
- DumpInputScreen: "마음속에 담긴 것을 적어주세요."
- ClassificationScreen: "이것은 어떤 것에 가까운가요?"
- FirstActionScreen: "이 일에 대해 지금 할 수 있는 행동은?"
- EntrustedSummaryScreen: "잘 맡겨두었어요"
- ReviewScreen: "잠시 맡겨둔 서랍"

### Theme (`lib/theme.dart`)
- scaffoldBackgroundColor: bgIvory
- All theme colors reference AppTokens directly
- ElevatedButton: sagePrimary, elevation 0, r12
- OutlinedButton: borderWarm, r12
- Card: surfaceWarm, r14, no elevation

### Tests Updated
- `plant_stage_helper_test.dart`: Full 9-stage coverage
- `quiet_garden_patch_test.dart`: Updated nutrient values, MouseRegion test
- `start_screen_test.dart`: Updated text assertions
- `dump_input_screen_test.dart`: Updated heading assertions
- `entrusted_summary_screen_test.dart`: Updated title assertion

---

## Validation Results

- `flutter test`: 134 tests passed, 0 failed
- `flutter build windows --release`: ✅ Success
- Audit (old terms): No matches for 작은 자리 / 조용한 정원 / 스며들 / 덜어냄 열기

---

## Protected Areas (Not Modified)

- ✅ _StableTextInput / Korean IME — untouched
- ✅ completed_sessions.json / local_storage_service.dart — untouched
- ✅ Review source-of-truth logic — untouched
- ✅ Session/classify/complete logic — untouched
- ✅ API / backend / runtime_paths / diagnostics_log / locks — untouched
