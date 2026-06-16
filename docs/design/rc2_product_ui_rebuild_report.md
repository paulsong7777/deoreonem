# RC2 Product UI Rebuild Report

## Summary

Full visual-layer rebuild of DeoReoNem Desktop (Flutter/Windows). All screens updated to use a unified design system with warm minimal aesthetic. Zero behavioral logic changes.

## Design System Created (`lib/design/`)

### `app_tokens.dart`
- Color palette: bgIvory, surfaceWarm, surfaceElevated, sagePrimary, textPrimary/Secondary/Muted, borderWarm, glowAmber, errorMuted
- Spacing: pagePadding (32h/24v), sectionGap (28), cardPadding (20), buttonGap (10)
- Radii: radiusLarge (24), radiusCard (16), radiusButton (12), radiusInput (12)
- Typography: titleHero (44/w200), titleScreen (22/w400), body (14), bodyMuted (13), label (12), caption (11), buttonPrimary/Secondary

### `app_components.dart`
- `ProductSurface`: Reusable card surface with warm background, subtle border, configurable padding
- `CalmSnackBar`: Styled floating snackbar with warm dark background
- `EmptyStateView`: Shared empty state with poetic copy, action buttons

## Theme Rebuild (`lib/theme.dart`)
- scaffoldBackground → bgIvory
- ElevatedButton: sagePrimary, elevation 0, radius 12, height 48
- OutlinedButton: borderWarm, radius 12
- TextButton: textSecondary foreground
- Card: surfaceWarm, radius 16, elevation 0
- InputDecoration: radius 12, borderWarm, sagePrimary focus

## Screens Rebuilt

| Screen | Key Visual Changes |
|--------|-------------------|
| StartScreen | maxWidth 520, hero 44px/w200, ProductSurface tree preview, 52px primary button, consistent spacing |
| DumpInputScreen | pagePadding tokens, titleScreen style, CalmSnackBar errors, design-system button |
| ClassificationScreen | ProductSurface item card, grouped category buttons with token radii/colors, sage progress indicator |
| FirstActionScreen | ProductSurface radio cards, token typography, consistent button sizing |
| EntrustedSummaryScreen | ProductSurface for first-action highlight and item cards, token typography throughout |
| CompletionScreen | Token-based typography, clean textSecondary close button |
| ReviewScreen | Sage underline tabs, ProductSurface item cards, EmptyStateView component, CalmSnackBar for all errors |
| QuietGardenPatch | Token-based colors (glowAmber, textSecondary), radius 28 container |
| Garden Overlay | Token-based controls (close 14x14/alpha 0.03, menu 10/opacity 0.15) |

## Preserved (Untouched)

- `_StableTextInput` class (Korean IME stability)
- `completed_sessions.json` logic
- `local_storage_service.dart`
- Review source-of-truth logic
- Session/classify/complete logic
- API services and backend calls
- `runtime_paths`, `diagnostics_log`, lock mechanics
- All routes and navigation paths
- All behavioral callbacks

## Validation

- **Tests**: 117/117 passed
- **Audit**: Only one occurrence found in code comments (acceptable)
- **Build**: Windows release build successful
- **Build artifact**: `build/windows/x64/runner/Release/deoreonem_desktop.exe`
