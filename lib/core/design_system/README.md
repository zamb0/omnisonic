# Omnisonic Design System

Colors, typography, spacing, icons and responsive layout helpers for the Omnisonic music streaming client, wired into `OmnisonicTheme` and used by `MaterialApp` in `lib/main.dart`.

## Quick Start

### Import

```dart
import 'package:omnisonic/core/design_system/design_system.dart';
```

### Apply the theme

```dart
MaterialApp(
  theme: OmnisonicTheme.lightTheme,
  darkTheme: OmnisonicTheme.darkTheme,
  themeMode: ThemeMode.system,
  // ... rest of your app
)
```

### Colors

```dart
Container(
  decoration: BoxDecoration(gradient: OmnisonicColors.primaryGradient),
  child: Text('Hello', style: TextStyle(color: OmnisonicColors.favoriteIndicator)),
)
```

### Typography

```dart
Text('Album Title', style: OmnisonicTypography.trackTitle)
Text('Artist Name', style: OmnisonicTypography.artistName)
```

### Spacing

```dart
Padding(
  padding: const EdgeInsets.all(OmnisonicSpacing.md), // 16px
  child: Column(
    children: [
      Text('Title'),
      const SizedBox(height: OmnisonicSpacing.sm), // 8px
      Text('Subtitle'),
    ],
  ),
)
```

### Icons

```dart
Icon(OmnisonicIcons.shuffle, size: OmnisonicIconSizes.md)
```

### Responsive layout

```dart
ResponsiveLayout(
  mobile: MobileView(),
  tablet: TabletView(),
  desktop: DesktopView(),
)
```

## Color System

### Primary Colors
- **Primary Purple**: `#6366F1` — main brand color
- **Primary Blue**: `#3B82F6` — secondary brand color
- **Primary Teal**: `#06B6D4` — accent color

### Semantic Colors
- **Success**: `#10B981`
- **Warning**: `#F59E0B`
- **Error**: `#EF4444`
- **Info**: `#3B82F6`

### Music-Specific Colors
- **Playing Indicator**: `#1DB954`
- **Paused Indicator**: `#F59E0B`
- **Queue Indicator**: `#8B5CF6`
- **Favorite Indicator**: `#EC4899`

The light color scheme uses darkened `*Light` variants of the brand colors (`primaryLight`, `secondaryLight`, `tertiaryLight`) so white foreground text on them clears WCAG AA — see `color_contrast_test.dart`.

## Typography

- **Inter**: primary font — body text, labels, UI elements
- **Poppins**: display font — headings and titles

Both are loaded via `google_fonts` (no bundled font assets required).

### Music-Specific Styles
- **Track Title**: 16px, Medium, Inter
- **Artist Name**: 14px, Regular, Inter
- **Album Title**: 14px, Medium, Inter

## Spacing System

8px grid, via `OmnisonicSpacing`:

- **XS**: 4px, **SM**: 8px, **MD**: 16px (most common), **LG**: 24px, **XL**: 32px

## Responsive Design

Breakpoints live in `ResponsiveBreakpoints` (`responsive_layout.dart`):

- **Mobile**: < 768px
- **Tablet**: 768px – 1024px
- **Desktop**: > 1024px

The app shell (`MainShell`) and the now-playing bar both switch on the same 768px threshold, so the compact mobile UI and the sidebar shell always appear together.

## Accessibility

### Touch Targets (`OmnisonicTouchTargets`)
- **Minimum**: 44px — WCAG compliance
- **Comfortable**: 48px
- **Large**: 56px

### Color Contrast
- All color combinations meet WCAG 2.1 AA (4.5:1 normal text, 3:1 large text) — enforced by `color_contrast_test.dart`.

## Platform Theme Extensions

`platform_theme_extensions.dart` + `platform_optimizations.dart` + `platform_animations.dart` add per-platform touch target size, border radius, page-transition builder and haptics, applied automatically by `OmnisonicTheme` via `addPlatformExtensions`.

## Testing

```bash
flutter test test/core/design_system/
```

## File Structure

```
lib/core/design_system/
├── colors.dart                     # Color palette and schemes
├── typography.dart                 # Text styles and fonts (google_fonts)
├── spacing.dart                    # Spacing, grid, touch targets
├── icons.dart                      # Icon system and sizes
├── theme.dart                      # ThemeData assembly (light/dark)
├── animation_manager.dart          # Standard durations/curves + ThemeExtension
├── responsive_layout.dart          # Breakpoints, ResponsiveLayout, ScreenSizeDetector
├── platform_theme_extensions.dart  # Per-platform ThemeExtension
├── platform_optimizations.dart     # Per-platform touch/haptics/scroll physics
├── platform_animations.dart        # Per-platform page transitions
├── design_system.dart              # Barrel export
└── README.md                       # This documentation
```

Every file here has a real consumer — anything without one gets deleted rather than kept "for later" (see issue A5 in the UX/UI audit).
