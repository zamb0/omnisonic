# Omnisonic Design System — v2 "Aurora Glass"

Colour, type, spacing, motion and the shared controls of the Omnisonic client,
wired into `OmnisonicTheme` and used by `MaterialApp` in `lib/main.dart`.

The spec is `docs/design-system.md` (Italian); this file is the developer's
entry point. `test/core/design_system/doc_alignment_test.dart` keeps the two
honest. Every component, light and dark side by side, is the debug-only route
**`/dev/gallery`** (`ComponentGalleryPage`).

## Quick Start

```dart
import 'package:omnisonic/core/design_system/design_system.dart';

MaterialApp(
  theme: OmnisonicTheme.lightTheme,   // Pearl
  darkTheme: OmnisonicTheme.darkTheme, // Midnight
  themeMode: ThemeMode.system,
)
```

## Three voices, separate jobs

| Voice | What it is | Where it appears |
|---|---|---|
| **Aurora** | the gradient violet → magenta → coral | the one main Play of a screen, the playing track's progress, the Aurora mesh behind screens with no artwork. **At most one filled Aurora control per screen**, and the text on it is always `onAurora` (never white). |
| **Ink** | `surfaces.ink` / `scheme.onSurface` | static primary actions (Save, Add) and the active segment |
| **Accent** | `scheme.primary`, electric violet | live state: the playing track, focus, selected chips, toggles |

Plus two role colours that are never decorative: **Heat** (coral, favourites)
and **Aqua** (`scheme.tertiary`, info / offline / cache).

```dart
final brand = OmnisonicBrand.of(context);   // aurora, auroraSoft, auroraMesh,
                                            // onAurora, heat, glow
final surfaces = OmnisonicSurfaces.of(context); // well, wellHover, hairline,
                                                // placeholder, ink, onInk
Icon(OmnisonicIcons.favorite, color: brand.heat)
```

Never `Colors.*` or a `Color(0x…)` outside this folder — the guardrail test
fails the build. Status colours used as text on light use the `*Accessible`
variants; a tinted chip's label is darkened with `TintedChip.labelColorFor`.

## Buttons

```dart
AuroraButton(label: 'Play', icon: OmnisonicIcons.playArrow, onPressed: play)   // one per page
PlayDisc(playing: isPlaying, size: PlayDiscSize.s48, onPressed: toggle)
OmnisonicButton(label: 'Save', loading: saving, onPressed: save)               // ink
OmnisonicButton(label: 'Shuffle', variant: OmnisonicButtonVariant.tonal, onPressed: shuffle)
OmnisonicButton(label: 'Delete', variant: OmnisonicButtonVariant.destructive, onPressed: del)
OmnisonicIconButton(icon: i, tooltip: 'Add', variant: OmnisonicIconButtonVariant.tonal, onPressed: add)
OmnisonicIconButton(                                                           // toggle
  icon: OmnisonicIcons.favoriteOutline, selectedIcon: OmnisonicIcons.favorite,
  selectedColor: OmnisonicBrand.of(context).heat, tooltip: 'Favourite',
  variant: OmnisonicIconButtonVariant.toggle, selected: starred, onPressed: star)
```

Loading keeps the button's width (a spinner replaces the icon, or sits over the
label) and the button announces itself as a live region. Every icon button needs
a `tooltip` — it is also the screen-reader label.

## Selection and input

`OmnisonicSegmented<T>` (an ink pill that slides between options),
`FilterChip`/`ChoiceChip` (selected = `primaryContainer` + 1 px accent edge + a
check), `SearchField` (48 px, halo on focus), and the themed `TextField`,
`Switch`, `Checkbox`, `Radio`, `Slider`. For a custom control with its own
`InkWell`, wrap it in `FocusDecoration` to get the keyboard focus ring.

## Progress and playback

`AuroraProgress` is the seek bar (4 → 6 px, 14 px thumb on hover/drag/focus;
drags report live through `onChanged` and commit once through `onSeek`;
arrow keys ±5 s; slider semantics). `AuroraProgressLine` is the 2 px line on
the mini player's bottom edge. `NowPlayingEqualizer` marks the playing track.
`AuroraMesh` is the background blob set; `ArtTintBackground` falls back to it
when there is no cover.

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

Two roles are v2: `heroTitle` (56, `heroTitleCompact` 40) for detail pages, and
`timecode` (mono, tabular figures) for every time and duration.

## Spacing, radii, icons

4 pt grid via `OmnisonicSpacing`; radii via `OmnisonicRadius` (`artHero` 20 for
a hero cover); shadows via `OmnisonicShadows` (`art`, `artGlow(color)`,
`glow`, `focusRing`, `overlay`). Icons come from `OmnisonicIcons` only
(never `Icons.*`), sizes from `OmnisonicIconSizes`.

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

`AnimationManager` holds every duration and curve: `instant` 100 (press),
`fast` 150, `quick` 200, `normal` 300, `emphasis` 450 (Now Playing, Hero),
`tint` 600; curves `standard`, `enter`, `exit` (`exitOf` = 70 % of the enter),
`spring` (mass 1, stiffness 380, damping 30). `PressScale` (0.97) and
`Staggered` (40 ms steps, first 12 only, once per grid via `EntranceScope`) are
the shared motion widgets. Everything goes through
`AnimationUtils.adjustedDuration`; with reduce motion the equalizer, the mesh,
the shimmer and every transition are static.

The guardrail rejects a literal `Duration(milliseconds: …)` in
`lib/features/**/presentation/`.

## Rules

- **No literals outside this folder.** Font sizes, weights, `Colors.*`,
  `Color(0x…)` and animation durations belong here;
  `test/core/design_system/token_guardrail_test.dart` fails on any that appear
  in `lib/` elsewhere. Add a token instead.
- **One Aurora control per page** (`AuroraButton`): the same guardrail counts
  them.
- **Text floor.** Nothing below 11px; informative text (counts, metadata) at
  12px or larger.
- **Never colour alone.** Status is an icon and a label, selection is a check
  or a bar, "playing" is an equalizer and a semantic label.
- **Gutter.** Page edges use `OmnisonicSpacing.gutter(context)` (16/24/32).
- **Glass.** `GlassSurface` gives its child a transparent `Material`; with the
  platform's high-contrast setting it becomes an opaque `surfaceContainer`.

## Components

Shared widgets live in `lib/features/ui/presentation/widgets/` (barrel
`widgets.dart`). Pages compose these rather than rebuilding cards, rows,
artwork or headers by hand.

| Component | Use it for | Notes |
|---|---|---|
| `MediaCard` / `AlbumCard` / `ArtistCard` | Any album / artist / playlist card | Hover: lift 1.03, glow from the cover's colour, 35 % scrim and a rising `PlayDisc` (artists: an Aurora ring). Server badge only for multi-source albums. Long press / right-click → actions. |
| `ResponsiveGridView.media` / `MediaGridPreset` | Every card grid and its skeleton | `staggered: true` fades the first cards in once. |
| `CoverArt` | Every piece of artwork | Placeholder is a gradient whose hue follows `seed`; `artHero` radius from 200 px. |
| `TrackRow` | Every track list | Live (equalizer, accent title), paused, selected, unavailable, hover-play. |
| `DetailHeader` | Album, artist, playlist headers | Cover tint wash, `artGlow`, hero title (2 lines + tooltip). Pair with `HeaderCollapseMixin` + `collapsingAppBar`. |
| `PageHeaderAppBar` / `SectionHeader` | Page and section titles | |
| `StatusChip` / `TintedChip` / `QualityBadge` / `MetadataChip` | Status, quality, facts | Icon + label; mono metadata. |
| `InlineBanner` | Messages that stay in the layout | A well with a 3 px semantic bar and an icon. |
| `showFeedback` | Every snackbar | Icon in the semantic colour that reads on the inverse bar. |
| `showConfirmDialog` / `showTextInputDialog` | Confirmations, one-line input | Max width 440; destructive confirm is `OmnisonicButton`. |
| `EmptyState` / `ErrorStateView` / `Skeleton*` | Empty, error, loading | Aurora halo, 80 px disc with ring; `hero: true` for first run. |
| `ArtTintMixin` | Following a cover's dominant colour | Stale results are dropped. |

Formatting lives in `lib/core/utils/formatters.dart`; readable error text in
`lib/core/errors/user_messages.dart` — never show `$e` or `failure.message`
raw.

## Testing

```bash
flutter test test/core/design_system/   # contrast, guardrail, doc alignment, controls
flutter test test/features/ui/          # component, state and golden tests
flutter test --update-goldens test/features/ui   # after an intended visual change
```

- `contrast_test.dart` — every text / border / dot pair of the doc, both themes.
- `token_guardrail_test.dart` — literals, durations, one Aurora button per page.
- `doc_alignment_test.dart` — `docs/design-system.md` ⇄ code.
- `component_gallery_test.dart` — the gallery and its per-section goldens.

Goldens render with shadows blurless (`debugDisableShadows`), so a glow looks
like a hard offset there; on a device it is soft.

## File Structure

```
lib/core/design_system/
├── colors.dart                 # palette, schemes, server hues
├── brand.dart                  # OmnisonicBrand: Aurora signature
├── surfaces.dart               # OmnisonicSurfaces: wells, ink, placeholder
├── typography.dart             # text styles, bundled font families
├── spacing.dart                # spacing, radii, shadows, touch targets
├── icons.dart                  # OmnisonicIcons and sizes
├── theme.dart                  # ThemeData assembly (light/dark)
├── animation_manager.dart      # durations, curves, SpringCurve, stagger
├── motion.dart                 # PressScale, Staggered, EntranceScope
├── aurora_button.dart          # AuroraButton, PlayDisc
├── omnisonic_button.dart       # OmnisonicButton
├── omnisonic_icon_button.dart  # OmnisonicIconButton
├── omnisonic_segmented.dart    # OmnisonicSegmented
├── focus_decoration.dart       # FocusDecoration
├── slider_thumb.dart           # GrowingThumbShape
├── aurora_progress.dart        # AuroraProgress, AuroraProgressLine
├── aurora_mesh.dart            # AuroraMesh
├── aurora_ring.dart            # AuroraRing
├── glass_surface.dart          # blur/saturate glass, light edge
├── art_tint_background.dart    # cover tint, mesh fallback
├── responsive_layout.dart      # breakpoints, ResponsiveLayout
├── theme_mode_controller.dart  # persisted light/dark/system choice
├── design_system.dart          # barrel export
└── README.md                   # this file
```

Every file here has a real consumer — anything without one gets deleted rather
than kept "for later".
