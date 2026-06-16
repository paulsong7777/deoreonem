# RC2 Visual Source of Truth — Implementation Spec

## Overview

This document captures the definitive design implementation extracted from two approved reference boards (A and B) for the DeoReoNem desktop product.

---

## 1. Design Tokens (Reference A)

File: `lib/design/app_tokens.dart`

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| sagePrimary | `#4A6D57` | Primary action, buttons |
| sageLight | `#91B87A` | Accents |
| ivory / bgIvory | `#F8F4F4` | Page background |
| warmWhite | `#FFF0F6` | Warm surface variant |
| sand | `#A7AD6A` | Neutral accent |
| warmGray | `#A7A29A` | Neutral text |
| charcoal | `#2D3E88` | Deep neutral |
| amber / glowAmber | `#D4A96A` | Warm accent, tree glow |
| softBlue | `#8FA7E7` | Cool accent |
| lavender | `#B8AAC5` | Soft accent |
| surfaceWarm | `#FFFEFC` | Card surfaces |
| textPrimary | `#2D3530` | Main body text |
| textSecondary | `#A7A29A` | Secondary/caption text |
| borderWarm | `#E8E4DE` | Card borders |

### Typography
| Style | Size | Weight | Color |
|-------|------|--------|-------|
| titleBanner | 48 | w300 | textPrimary |
| heading / titleScreen | 24 | w500 | textPrimary |
| body | 16 | normal | textPrimary |
| caption | 13 | normal | textSecondary |

### Spacing & Radii
- Page padding: 32h × 24v
- Section gap: 24
- Card padding: 20 all
- radiusLarge: 20
- radiusCard: 14
- radiusButton: 12

---

## 2. Nine-Stage Growth System (Reference B)

File: `lib/services/plant_stage_helper.dart`

| Stage | Name | Threshold | Message |
|-------|------|-----------|---------|
| 1 | seed (씨앗) | 0 | 아직 내려놓은 걱정은 없습니다. |
| 2 | sprout (새싹) | ≥1 | 조용한 나무가 싹을 틔우고 있어요. |
| 3 | youngTree (어린 나무) | ≥4 | 조용한 나무가 조금씩 자라고 있어요. |
| 4 | youngTreePlus (어린 나무+) | ≥7 | 조용한 나무가 기반을 다지고 있어요. |
| 5 | greenTree (푸른 나무) | ≥11 | 조용한 나무가 풍성해지고 있어요. |
| 6 | growingTree (자라나는 나무) | ≥16 | 조용한 나무가 넓어지고 있어요. |
| 7 | strongTree (튼튼한 나무) | ≥22 | 조용한 나무가 깊어지고 있어요. |
| 8 | bigTree (큰 나무) | ≥30 | 조용한 나무가 따뜻해지고 있어요. |
| 9 | quietTree (조용한 나무) | ≥40 | 내려놓은 걱정들이 조용한 나무가 되었어요. |

---

## 3. Quiet Tree Overlay (Reference B)

File: `lib/widgets/quiet_garden_patch.dart`

### Animations
- **Idle sway**: 5s cycle, ±2.3° rotation from bottom center
- **Wind effect**: 8s cycle, ±3° rotation + ±2px horizontal translate
- **Hover motion**: On mouse enter → scale 1.02 + translate -2px Y over 300ms
- **Nutrient glow**: Amber glow from below on nutrient increase (1500ms fade)

### 9-Stage CustomPaint Progression
- Stages 1-2: Seed/sprout (minimal)
- Stages 3-4: Young tree with leaves
- Stages 5-6: Fuller canopy, branches appear
- Stages 7-8: Large multi-layered canopy, strong trunk with side branches
- Stage 9: Full quiet tree — maximum canopy layers, peak branch detail

### Overlay Window
- Size: 250×280 pixels
- Background: Near-transparent gradient
- Always on top, frameless, draggable

---

## 4. Screen Flow (Reference A Panels)

| Route | Screen | Heading |
|-------|--------|---------|
| `/` | StartScreen | 덜어냄 (48pt banner) |
| `/dump` | DumpInputScreen | 마음속에 담긴 것을 적어주세요. |
| `/classify` | ClassificationScreen | 이것은 어떤 것에 가까운가요? |
| `/first-action` | FirstActionScreen | 이 일에 대해 지금 할 수 있는 행동은? |
| `/summary` | EntrustedSummaryScreen | 잘 맡겨두었어요 |
| `/review` | ReviewScreen | 잠시 맡겨둔 서랍 |

### StartScreen Layout
1. Title "덜어냄" (titleBanner, 48pt)
2. Subtitle below
3. Tree visual in center
4. Primary "시작하기" button (sage green, full-width)
5. Secondary "맡겨둔 것 확인하기" (conditional)
6. Tertiary "조용한 나무 보기"

---

## 5. Theme Integration

File: `lib/theme.dart`

- scaffoldBackgroundColor: `AppTokens.bgIvory`
- ElevatedButton: sagePrimary, r12, elevation 0
- OutlinedButton: borderWarm border, r12
- Card: surfaceWarm, r14, no elevation
- Input: borderWarm borders, r12, sage focus border

---

## 6. Protected (DO NOT TOUCH)

- _StableTextInput / Korean IME logic
- completed_sessions.json / local_storage_service.dart
- Review source-of-truth logic
- Session/classify/complete logic
- API / backend / runtime_paths / diagnostics_log / locks
