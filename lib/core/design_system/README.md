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

Always `OmnisonicIcons`, never `Icons.*` directly — the token file is the
only thing keeping one shape language across the app. Sizes come from the
ladder, not from a literal.

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
- **Primary Purple**: `#7C7CFF` — main brand color
- **Primary Blue**: `#5A67D8` — secondary brand color
- **Primary Teal**: `#4DD0E1` — accent color

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

- **Manrope**: primary font — body text, labels, UI elements
- **Gabarito**: display font — headings, titles, nav and button labels
- **JetBrains Mono**: technical font — durations, bitrates, counts, server ids

All three are bundled as assets under `assets/fonts/` and declared in the
`fonts:` section of `pubspec.yaml`. They are not fetched at runtime: golden
tests need deterministic metrics, and a first launch shouldn't need the
network to draw text. Only the weights the type ramp asks for are shipped;
`typography_system_test.dart` fails if a style requests a weight that isn't
bundled.

### Music-Specific Styles
- **Track Title**: 16px, Medium, Manrope
- **Artist Name**: 14px, Regular, Manrope
- **Album Title**: 14px, Medium, Manrope

## Spacing System

8px grid, via `OmnisonicSpacing`:

- **XS**: 4px, **SM**: 8px, **MD**: 16px (most common), **LG**: 24px, **XL**: 32px

## Responsive Design

Breakpoints live in `ResponsiveBreakpoints` (`responsive_layout.dart`):
`mobile` 480, `tablet` 768, `desktop` 1024, `largeDesktop` 1440.

`MainShell` switches chrome at 768 (bottom bar → 72px rail) and 1024 (rail →
234px sidebar), and publishes the result through `ShellLayout`.

**Pages inside the shell should ask `ShellLayout`, not `MediaQuery`.** The
content column is narrower than the window by the width of the sidebar, so
the two disagree at exactly the widths that matter — that disagreement once
hid the library's tab bar on a 1000px window and left two tabs unreachable.

`ResponsiveLayout` and `ResponsiveGridView` both measure their own
constraints for the same reason.

## Accessibility

### Touch Targets (`OmnisonicTouchTargets`)
- **Minimum**: 44px — WCAG compliance
- **Comfortable**: 48px
- **Large**: 56px

### Color Contrast
- All color combinations meet WCAG 2.1 AA (4.5:1 normal text, 3:1 large text) — enforced by `color_contrast_test.dart`.

### Dynamic Type (`OmnisonicTextScale`)

Content scales without limit. The shell's own chrome — nav labels, the rail,
the transport bar — stops at `chromeMax` (1.3x) via `clampChrome`: it is
fixed furniture with nowhere to reflow, and past that it takes the screen
away from the content the user enlarged the text to read.

Boxes that are part artwork and part text use `boxExtent`, which grows only
the text half; scaling the whole height would enlarge the artwork too and
push the row off screen.

`text_scale_test.dart` pumps every major screen at 1.0 / 1.3 / 2.0 across two
widths and asserts nothing throws.

### Reduced Motion

Durations go through `AnimationUtils.adjustedDuration`, which returns
`Duration.zero` when the platform asks for reduced motion. Looping animations
— the shimmer sweep, the glass sheen, the audio visualizer — park at a static
frame instead of running at zero duration forever.

### State Vocabulary

Loading, empty and error are `state_views.dart`, not per-screen inventions.
`ErrorStateView` takes a **required** `onRetry`, so an error the user cannot
act on is not expressible. `screen_states_test.dart` holds every screen to it.

## Motion

`animation_manager.dart` holds every duration and curve the app uses:
`fast` (150ms) / `quick` (200ms) / `normal` (300ms) / `slow` (500ms) /
`loading` (1500ms), plus a curve per role (`standard`, `fast`, `slow`,
`dialog`, `sheet`, `loading`). These are values only — anything that has to
*decide* (reduced motion, sheet vs dialog presentation) lives in
`core/utils/animation_utils.dart` and reads from here.

There used to be three overlapping sets of these under different names, so
the same transition was 200ms or 300ms depending on which file the author
reached for. A per-platform set also existed and was read by nothing.

## Testing

```bash
flutter test test/core/design_system/
```

## File Structure

```
lib/core/design_system/
├── colors.dart                     # Color palette and schemes
├── typography.dart                 # Text styles and bundled font families
├── spacing.dart                    # Spacing, grid, touch targets
├── icons.dart                      # Icon system and sizes
├── theme.dart                      # ThemeData assembly (light/dark)
├── animation_manager.dart          # Durations and curves
├── responsive_layout.dart          # Breakpoints and ResponsiveLayout
├── glass_surface.dart              # Blur/saturate glass panes
├── art_tint_background.dart        # Cover-art tint wash
├── theme_mode_controller.dart      # Persisted light/dark/system choice
├── design_system.dart              # Barrel export
└── README.md                       # This documentation
```

Every file here has a real consumer — anything without one gets deleted rather than kept "for later" (see issue A5 in the UX/UI audit).
