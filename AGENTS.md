# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

Omnisonic — a Flutter client that aggregates **multiple Subsonic-compatible servers** into one unified music collection (iOS, Android, macOS, Windows, Linux, web). The web build streams only; see *Web* below. The multi-server aspect drives most of the non-obvious design: IDs, deduplication, source selection, and credential storage all exist because the same track can live on several servers.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # required after DI/drift/json changes
flutter run                                                # add -d macos|ios|linux|windows
flutter analyze                                            # lints: package:flutter_lints
flutter test                                               # all tests
flutter test test/core/services/deduplication_engine_test.dart          # one file
flutter test test/core/services/deduplication_engine_test.dart --plain-name "detects duplicates"  # one test
flutter test --coverage
```

Builds: `flutter build apk|appbundle|ios|macos|windows|linux`.

### Code generation

Generated files are committed and must never be hand-edited: `*.g.dart` and `lib/core/di/injection_container.config.dart`. Re-run build_runner after:

- adding/changing `@injectable` / `@lazySingleton` annotations or anything in `lib/core/di/app_module.dart`
- editing `lib/core/database/tables.dart`, `app_database.dart`, or a DAO
- editing `@JsonSerializable` models (`lib/core/services/subsonic_models.dart`)
- adding `@GenerateMocks` to a test (produces `*_test.mocks.dart`)

`build.yaml` scopes drift generation to `lib/core/database/**` and explicitly excludes `data_sources/**` — putting drift annotations outside that scope produces no output.

## Architecture

Clean Architecture, `core/` + `features/`. Feature folders follow `data/` (repository impls, datasources) and `presentation/` (viewmodels, blocs, pages, widgets); the domain contracts live centrally in `lib/core/`, **not** per feature:

- `lib/core/entities/` — domain entities (`Track`, `Album`, `Artist`, `MusicServer`, `Playlist`, …)
- `lib/core/repositories/` — abstract repository interfaces; implementations live under `lib/features/*/data/repositories/`
- `lib/core/usecases/` — cross-feature use cases (sync, search, play, playlists)
- `lib/core/services/` — the multi-server logic (see below)
- `lib/core/database/` — drift schema, DAOs, and `data_sources/` wrappers that return `Result`
- `lib/core/design_system/` — theming, responsive/accessibility helpers; import via the `design_system.dart` barrel
- `lib/features/ui/` — the actual app screens (home, library, search, favorites, now playing, album/artist detail, `main_shell`); `features/music|servers|playback|lyrics|offline` own their own pages plus state

### Multi-server invariants

- **IDs**: every entity ID is `"{serverId}_{subsonicId}"`, built by `IdGenerator` (`lib/core/utils/id_generator.dart`). Never pass a unique ID to the Subsonic API — call `IdGenerator.extractSubsonicId` first. Subsonic IDs may themselves contain `_`, so only split on the first underscore (the helper does this).
- **Deduplication**: `DeduplicationEngine` groups tracks by fuzzy similarity (threshold `0.85`, duration tolerance 10s). `MusicRepositoryImpl` caches duplicate groups in memory and re-computes them on sync.
- **Playlists**: server playlists are mirrored locally with the same `{serverId}_{subsonicId}` IDs and the server stays the source of truth — `PlaylistRepositoryImpl` writes there first, then reads the playlist back. Local-only playlists have IDs starting with `Playlist.localIdPrefix` (`playlist_`). A server playlist can only hold that server's tracks.
- **Writes go to the item's own server**: star, rating, scrobble, play queue and playlist calls resolve the server from the entity's `serverId`, never "the first online server".
- **Source selection**: `SourceSelectionService` picks which copy of a duplicated track to stream, based on audio quality and live server availability (`ServerStatusMonitor`). Playback should go through this, not straight to a `Track.streamUrl`.

### Error handling

`Result<T> = Either<Failure, T>` (dartz) in `lib/core/errors/result.dart`, with `isSuccess`/`valueOrNull`/`mapValue` extensions and `ResultHelper.success` / `ResultHelper.failure`. Failure types in `failures.dart` (`ServerFailure`, `DatabaseFailure`, `CacheFailure`, `ValidationFailure`, `AuthenticationFailure`). Repositories and data sources return `Result`; they do not throw. The Subsonic client (`subsonic_api_client.dart`) is the exception — it throws typed exceptions from `errors/exceptions.dart`, which the repository converts.

### State management (two systems, deliberately)

- **ChangeNotifier ViewModels + provider** for long-lived UI state: `MusicLibraryViewModel`, `PlaybackViewModel`, `ServerManagementViewModel`, `PlaylistViewModel`, `LyricsViewModel`.
- **flutter_bloc** for event-driven flows: `SyncBloc`, `SearchBloc`, `PlaybackBloc`.

Both are registered in `injection_container` and wired in `main.dart` via `MultiProvider`. Resolve them with `getIt<T>()`, not by constructing them.

### Playback

`PlaybackService` coordinates `AudioPlayerDataSource`, `AudioServiceHandler` (media notifications), `AudioFocusManager`, and `MprisHandler`. Platform split matters:

- `PlatformAudioPlayer` factory returns `audioplayers` on Linux and `just_audio` everywhere else.
- `AudioService.init()` is **skipped on Linux** (MPRIS/dbus is used instead) and is wrapped in a 5s timeout in `main.dart` because it can hang on iOS.

`main.dart` also persists the play queue via `PlaybackTrackingService.savePlayQueue` on `paused`/`inactive`/`detached` lifecycle events.

### Web

Built with `flutter build web --base-href /app/` and deployed under `/app/` of the Pages site by `.github/workflows/pages.yml`.

- **Database**: `lib/core/database/connection/` picks `NativeDatabase` on native and drift's `WasmDatabase` on web. `web/sqlite3.wasm` and `web/drift_worker.js` are downloaded from the `sqlite3` and `drift` GitHub releases matching `pubspec.lock`; update them when those packages change.
- **`dart:io`**: dart2js still compiles code importing it, but every call throws. Platform checks go through `AppPlatform` (`core/utils/platform_info.dart`), never `Platform`. Downloads, the audio cache and the downloads UI are gated on `supportsOfflineDownloads` (`core/utils/web_support.dart`). MPRIS is Linux-only; playback uses `just_audio`.
- **Server limits** (not fixable in code): the server must be `https://`, send CORS headers, and not be on a LAN/loopback address (Private Network Access). `ServerValidator.webUrlWarning` and `describeConnectionTestError` surface these in the add-server form.

### Credentials

`ServerConnectionService` stores passwords with a three-tier strategy: in-memory cache → `flutter_secure_storage` → XOR-encrypted column in the drift `ServersTable` (`PasswordEncryption`). The DB fallback is intentionally weak and documented as such; do not treat `encryptedPassword` as strong protection, and never log passwords (`AppLog` takes a `sensitive: true` flag that suppresses output).

### Routing

go_router in `lib/core/routing/app_router.dart`. A `ShellRoute` wraps the tab pages in `MainShell`; detail routes pass entities through `state.extra` (cast, e.g. `state.extra as Album`), so deep links without `extra` will crash — pass the entity or add a fallback.

## Conventions

- Logging goes through `AppLog` (`debug`/`info`/`warn`/`error`), not `print`. `debug` is stripped in release.
- Import via barrels where they exist: `core/entities/entities.dart`, `core/errors/errors.dart`, `core/usecases/usecases.dart`, `core/design_system/design_system.dart`, `features/ui/presentation/widgets/widgets.dart`.
- Entities use `equatable`; keep `props` in sync when adding fields.
- Drift schema changes require bumping `schemaVersion` in `app_database.dart` and adding an `onUpgrade` branch (currently at version 5).
- Tests use `AppDatabase.forTesting(NativeDatabase.memory())` for DB work and mockito `@GenerateMocks` for repository doubles.

## Repo notes

- `feishin/` is an untracked vendored copy of the GPL-3.0 Feishin client kept as a UI/behaviour reference. It is not part of the build — do not edit it or import from it. (Some widgets, e.g. `feishin_card.dart`, are named after it.)
- `.kiro/specs/` contains the original requirements/design/task specs (`omnisonic-music-client`, `omnisonic-ui-enhancement`) — useful background on intended behaviour.
- `.agents/skills/` holds Dart/Flutter task skills (testing, mocks, routing, responsive layout, static analysis).
- `test_unique_ids.dart` at the repo root is a standalone script, not part of `flutter test`.
