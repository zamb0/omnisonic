# omnisonic

A new Flutter project.

## Getting Started

# Omnisonic

A cross-platform music streaming client that provides a unified music collection experience across multiple Subsonic-compatible servers.

## Features

- **Multi-Server Support**: Connect to multiple Subsonic-compatible servers
- **Unified Collection**: Aggregate music from all connected servers into one library
- **Intelligent Deduplication**: Automatically detect and manage duplicate tracks
- **Cross-Platform**: Available on iOS, Android, macOS, Windows, and Linux
- **Modern UI**: Spotify-like interface with smooth animations
- **Offline Support**: Cache music for offline listening
- **Smart Collections**: Recently played, most played, and recently added playlists

## Architecture

This project follows Clean Architecture principles with clear separation between:

- **Presentation Layer**: Flutter UI widgets and state management
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: Repository implementations and data sources

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Platform-specific development tools for target platforms

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate code:
   ```bash
   dart run build_runner build
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Building for Different Platforms

- **Android**: `flutter build apk` or `flutter build appbundle`
- **iOS**: `flutter build ios`
- **macOS**: `flutter build macos`
- **Windows**: `flutter build windows`
- **Linux**: `flutter build linux`

## Project Structure

```
lib/
├── core/                 # Core functionality
│   ├── constants/        # App constants
│   ├── di/              # Dependency injection
│   ├── errors/          # Error handling
│   ├── routing/         # Navigation
│   ├── usecases/        # Base use case classes
│   └── utils/           # Utilities
├── features/            # Feature modules
│   ├── music/           # Music collection management
│   ├── servers/         # Server connection management
│   ├── playback/        # Audio playback
│   ├── sync/            # Synchronization
│   └── ui/              # User interface
└── main.dart            # App entry point
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
