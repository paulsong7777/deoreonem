# RC2 Mockup #1 UI Specification

## Design Goal
- Warm minimal desktop product
- Calm ivory background, deep sage primary action
- Premium, quiet, not game-like
- "조용한 나무" as the visible metaphor
- StartScreen = product home screen, NOT a centered button stack
- Quiet Tree = floating companion object, NOT a beige rectangular card

## App Window Assumption
- Current window: ~700px wide, ~1000px tall (portrait-like)
- Layout: vertical product layout (not two-column for this width)

## Visual Tokens
| Token | Value |
|-------|-------|
| Background ivory | #FCF9F5 |
| Surface white-warm | #FFFEFC |
| Border warm gray | #EDE7DD |
| Text primary | #3A3530 |
| Text muted | #8C8580 |
| Sage primary | #5B8C6B |
| Sage hover | #4D7A5C |
| Glow amber | #D4A96A |
| Radius large | 28-32px |
| Radius button | 14px |

## StartScreen Layout (700px window)

### Root
- Background: `#FCF9F5`
- Centered column, maxWidth: 480px
- Horizontal padding: 48px
- Top spacing: ~100px from top

### A. Hero Text Block
- Title "덜어냄": 48px, weight 200, color primary, letterSpacing 2
- SizedBox(24)
- Subtitle: 17px, color muted, height 1.5, centered
  "오늘 머릿속에 남아있는 것들을\n잠시 내려놓아 보세요."
- SizedBox(8)
- Supporting: 13px, color muted 60% opacity
  "걱정은 잠시 맡겨두고, 필요한 것만 다시 꺼내볼 수 있습니다."

### B. Quiet Tree Preview Block
- SizedBox(36)
- Container:
  - width: 380px (or full parent width if smaller)
  - height: 200px
  - borderRadius: 32
  - color: #FFFEFC
  - border: 0.5px #EDE7DD
  - shadow: none
- Content (Column, centered):
  - Tree visual: SizedBox(150, 120) with CustomPaint
  - SizedBox(10)
  - Label "조용한 나무": 13px, weight 500, primary
  - SizedBox(4)
  - Copy: 11px, muted 70%, "내려놓은 걱정은 나무의 양분이 됩니다."

### C. Action Block
- SizedBox(32)
- Width matches preview (380px or parent width)
- Primary "시작하기": height 54, sage fill, radius 14, fontSize 15, weight 500
- SizedBox(10)
- Secondary "맡겨둔 것 확인하기": height 48, outlined, radius 14, fontSize 13
- SizedBox(14)
- Tertiary "조용한 나무 보기": TextButton, fontSize 12, muted 70%

### D. Footer
- At bottom with Spacer
- fontSize 10, muted 35% opacity
- "v{version} {channel} · {sha}"

## Quiet Tree Overlay Spec

### Window
- Size: 240×270 (taller than wide)
- Frameless, always-on-top

### Surface
- Background gradient:
  - Top: #FFFFFE (nearly white)
  - Bottom: #F8F4ED (barely warm)
- BorderRadius: 32
- Shadow: none
- Border: none

### Tree Visual
- Size: 180×150 (dominates the window)
- Vertically centered with Expanded
- Uses existing CustomPaint _GardenPainter

### Controls
- Top-left "…": size 10, opacity 0.15
- Top-right close: 14×14, icon 8, background alpha 0.03
- Nearly invisible but clickable

### Status Text
- Bottom, 14px padding
- "조용한 나무가 조금씩 자라고 있어요."
- fontSize 9, muted, maxLines 1, ellipsis

### Glow
- Amber #D4A96A
- Peak opacity 0.6
- blurRadius 32, spreadRadius 12
- Duration: 1500ms
- Container: 110×55
- Position: bottom 40

## Failure Conditions
- StartScreen fails if it still looks like title/subtitle/button/button/button centered
- StartScreen fails if tree preview is smaller than 150×120 or invisible
- Quiet Tree fails if it looks like a beige rectangular card
- Quiet Tree fails if tree visual is not the dominant element
- Quiet Tree fails if glow is not visible after worry let-go
