# Omnisonic Design System

A comprehensive design system for the Omnisonic music streaming client, providing consistent colors, typography, spacing, and components across all platforms.

## Overview

The Omnisonic Design System implements a modern, accessible, and responsive design language that enhances the music listening experience. It follows Material Design 3 principles while adding custom elements specific to music applications.

## Features

- **🎨 Comprehensive Color Palette**: Light and dark themes with music-specific colors
- **📝 Typography System**: Inter and Poppins fonts with responsive scaling
- **📏 8px Grid System**: Consistent spacing and layout across all screen sizes
- **🎵 Music-Specific Components**: Specialized UI elements for music applications
- **♿ Accessibility Compliant**: WCAG 2.1 AA standards with proper touch targets
- **📱 Responsive Design**: Adaptive layouts for mobile, tablet, and desktop
- **🎭 Theme Management**: Seamless switching between light, dark, and system themes

## Quick Start

### Import the Design System

```dart
import 'package:omnisonic/core/design_system/design_system.dart';
```

### Apply Themes

```dart
MaterialApp(
  theme: OmnisonicTheme.lightTheme,
  darkTheme: OmnisonicTheme.darkTheme,
  themeMode: ThemeMode.system,
  // ... rest of your app
)
```

### Use Colors

```dart
// Access theme colors
Container(
  color: context.colorScheme.primary,
  child: Text(
    'Hello World',
    style: TextStyle(color: context.colorScheme.onPrimary),
  ),
)

// Use custom music colors
Icon(
  Icons.play_arrow,
  color: context.playingIndicatorColor,
)

// Apply gradients
Container(
  decoration: BoxDecoration(
    gradient: context.primaryGradient,
  ),
)
```

### Typography

```dart
// Use predefined text styles
Text('Album Title', style: context.textTheme.trackTitle)
Text('Artist Name', style: context.textTheme.artistName)
Text('Duration', style: context.textTheme.duration)

// Use Material Design text styles
Text('Heading', style: context.textTheme.headlineMedium)
Text('Body text', style: context.textTheme.bodyLarge)
```

### Spacing and Layout

```dart
// Use consistent spacing
Padding(
  padding: OmnisonicInsets.allMd, // 16px all sides
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: OmnisonicSpacing.sm), // 8px
      Text('Subtitle'),
    ],
  ),
)

// Responsive spacing
Padding(
  padding: OmnisonicSpacing.screenPaddingFor(context),
  child: content,
)
```

### Icons and Assets

```dart
// Use consistent icons
OmnisonicIconWidget.play()
OmnisonicIconWidget.favorite(filled: true)
OmnisonicIconWidget(OmnisonicIcons.shuffle)

// Display album artwork with fallback
context.albumArtwork(
  imageUrl: album.artworkUrl,
  width: 120,
  height: 120,
)
```

## Color System

### Primary Colors
- **Primary Purple**: `#6366F1` - Main brand color
- **Primary Blue**: `#3B82F6` - Secondary brand color  
- **Primary Teal**: `#06B6D4` - Accent color

### Semantic Colors
- **Success**: `#10B981` - Success states
- **Warning**: `#F59E0B` - Warning states
- **Error**: `#EF4444` - Error states
- **Info**: `#3B82F6` - Information states

### Music-Specific Colors
- **Playing Indicator**: `#1DB954` - Currently playing tracks
- **Paused Indicator**: `#F59E0B` - Paused tracks
- **Queue Indicator**: `#8B5CF6` - Queued tracks
- **Favorite Indicator**: `#EC4899` - Favorited items

### Gradients
- **Primary Gradient**: Purple to Blue
- **Accent Gradient**: Blue to Teal
- **Hero Gradient**: Purple to Violet to Pink
- **Subtle Gradient**: Light surface variations

## Typography

### Font Families
- **Inter**: Primary font for body text, labels, and UI elements
- **Poppins**: Display font for headings and titles
- **Fallback**: Roboto (Android), San Francisco (iOS), System default (Desktop)

### Text Styles
- **Display Large**: 57px, Bold, Poppins - Hero headings
- **Headline Medium**: 28px, SemiBold, Poppins - Section headings
- **Title Large**: 22px, Medium, Inter - Card titles
- **Body Large**: 16px, Regular, Inter - Main body text
- **Label Medium**: 12px, Medium, Inter - Labels and captions

### Music-Specific Styles
- **Track Title**: 16px, Medium, Inter - Song titles
- **Artist Name**: 14px, Regular, Inter - Artist names
- **Album Title**: 14px, Medium, Inter - Album names
- **Duration**: 12px, Regular, Inter - Time displays

## Spacing System

Based on an 8px grid system for consistent spacing:

- **XS**: 4px - Minimal spacing
- **SM**: 8px - Small spacing
- **MD**: 16px - Medium spacing (most common)
- **LG**: 24px - Large spacing
- **XL**: 32px - Extra large spacing

### Component Spacing
- **Card Padding**: 16px
- **List Item Padding**: 16px
- **Button Padding**: 16px horizontal, 16px vertical
- **Screen Padding**: 16px (responsive)

## Responsive Design

### Breakpoints
- **Mobile**: < 600px (4 columns)
- **Tablet**: 600px - 1200px (8 columns)
- **Desktop**: > 1200px (12 columns)

### Grid System
- **Mobile Margin**: 16px
- **Tablet Margin**: 24px
- **Desktop Margin**: 32px

## Accessibility

### Touch Targets
- **Minimum**: 44px - WCAG compliance
- **Comfortable**: 48px - Recommended size
- **Large**: 56px - Primary actions

### Color Contrast
- All color combinations meet WCAG 2.1 AA standards
- Minimum contrast ratio of 4.5:1 for normal text
- Minimum contrast ratio of 3:1 for large text

## Theme Management

```dart
// Create theme manager
final themeManager = OmnisonicThemeManager();

// Switch themes
themeManager.setLightTheme();
themeManager.setDarkTheme();
themeManager.setSystemTheme();
themeManager.toggleTheme();

// Check current theme
bool isDark = themeManager.isDark(context);
String themeName = themeManager.themeModeName;
```

## Asset Management

### Placeholder Images
```dart
// Album artwork placeholder
OmnisonicAssetManager.albumPlaceholder(width: 120, height: 120)

// Artist image placeholder
OmnisonicAssetManager.artistPlaceholder(width: 120, height: 120)

// Playlist image placeholder
OmnisonicAssetManager.playlistPlaceholder(width: 120, height: 120)
```

### Network Images with Fallbacks
```dart
// Automatic fallback to placeholder
context.albumArtwork(
  imageUrl: 'https://example.com/album.jpg',
  width: 120,
  height: 120,
)
```

## Installation

### 1. Add Font Files (Optional)
Download and add font files to `assets/fonts/`:
- Inter: Regular, Medium, SemiBold, Bold
- Poppins: Regular, Medium, SemiBold, Bold

### 2. Update pubspec.yaml
Uncomment the font and asset sections in `pubspec.yaml` after adding font files.

### 3. Import and Use
```dart
import 'package:omnisonic/core/design_system/design_system.dart';
```

## Examples

See `example_integration.dart` for a comprehensive example showing all design system components in action.

## Testing

Run the design system tests:
```bash
flutter test test/core/design_system/design_system_test.dart
```

## Contributing

When adding new components or modifying existing ones:

1. Follow the established naming conventions
2. Maintain consistency with the 8px grid system
3. Ensure accessibility compliance
4. Add appropriate tests
5. Update documentation

## File Structure

```
lib/core/design_system/
├── colors.dart           # Color palette and schemes
├── typography.dart       # Text styles and fonts
├── spacing.dart          # Spacing, grid, and layout
├── icons.dart           # Icon system and sizes
├── theme.dart           # Theme configuration
├── theme_manager.dart   # Theme switching logic
├── asset_manager.dart   # Asset and image management
├── design_system.dart   # Main export file
├── example_integration.dart # Usage examples
└── README.md           # This documentation
```

## License

This design system is part of the Omnisonic project and follows the same license terms.