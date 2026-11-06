<p align="center">
  <img src="logo.png" width="112" alt="Omnisonic logo">
</p>

<h1 align="center">Omnisonic</h1>

<p align="center">
  One music library from all your Subsonic servers.
</p>

<p align="center">
  <a href="https://github.com/zamb0/omnisonic/actions/workflows/build.yml"><img src="https://github.com/zamb0/omnisonic/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="https://github.com/zamb0/omnisonic/releases/latest"><img src="https://img.shields.io/github/v/release/zamb0/omnisonic?include_prereleases&label=release" alt="Latest release"></a>
  <a href="https://zamb0.github.io/omnisonic/"><img src="https://img.shields.io/badge/site-zamb0.github.io%2Fomnisonic-9479FF" alt="Website"></a>
</p>

---

Omnisonic is a Flutter music client for Subsonic-compatible servers
(Navidrome, Gonic, Airsonic, …). Connect as many servers as you like: their
libraries merge into one collection, duplicate tracks are folded together,
and each song streams from the best copy that is online right now.

## Features

- **Many servers, one library.** Albums, artists and playlists from every
  server appear in a single collection.
- **Duplicate detection.** The same track on several servers is matched by
  fuzzy metadata and duration, and shown once.
- **Smart source selection.** Playback picks the copy with the best audio
  quality on a server that is reachable, and falls back when one goes down.
- **Offline downloads.** Save tracks and albums for listening without a
  connection.
- **Lyrics**, including synced lyrics where the server provides them.
- **Playlists, favourites and scrobbling** back to your server.
- **System integration.** Media notifications and lock-screen controls on
  mobile, MPRIS on Linux.
- **Aurora Glass design.** Light and dark themes, keyboard navigation,
  screen-reader labels and reduced-motion support.

## Download

Prebuilt packages are attached to each
[GitHub Release](https://github.com/zamb0/omnisonic/releases/latest):

| Platform | Package | Notes |
|---|---|---|
| Android | `app-release.apk` or the per-ABI APKs | Most phones need `app-arm64-v8a-release.apk`. |
| Linux | `omnisonic-<version>-linux-x64.tar.gz` | Extract, then run `./omnisonic`. Needs GTK 3, GStreamer and libsecret. |
| iOS, macOS, Windows | — | Build from source for now (see below). |

## Build from source

Requirements: Flutter (stable, Dart `^3.9.2`) and the toolchain for your
target platform.

```bash
git clone https://github.com/zamb0/omnisonic.git
cd omnisonic
flutter pub get
flutter run                # add -d macos | ios | android | linux | windows
```

Release builds:

```bash
flutter build apk          # Android
flutter build linux        # Linux
flutter build macos        # macOS
flutter build ios          # iOS (needs signing)
flutter build windows      # Windows
```

The `Makefile` wraps these with packaging targets (`make help`). On Linux,
install the native build dependencies first:

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libsecret-1-dev libjsoncpp-dev
```

Web is not supported: the database, downloads and cache rely on `dart:ffi`
and `dart:io`.

## Development

```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # after DI, drift or JSON model changes
```

Generated files (`*.g.dart`, `injection_container.config.dart`) are
committed; never edit them by hand.

- [`AGENTS.md`](AGENTS.md): architecture, multi-server invariants and repo conventions.
- [`docs/design-system.md`](docs/design-system.md): the Aurora Glass design
  system (in Italian); [`lib/core/design_system/README.md`](lib/core/design_system/README.md)
  is the developer entry point.

## Continuous integration

[`.github/workflows/build.yml`](.github/workflows/build.yml) builds Android
and Linux on pull requests to `dev`. Pushing a `v*` tag on a commit of `main`
publishes a GitHub Release with the packages attached:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Android release signing is used when the repository secrets
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and
`ANDROID_KEY_PASSWORD` are set; otherwise the APKs are signed with the debug
key.

The project website in [`site/`](site/) is deployed to GitHub Pages by
[`.github/workflows/pages.yml`](.github/workflows/pages.yml).

## Contributing

1. Fork the repository and create a branch from `dev`.
2. Make your change, with tests.
3. Run `flutter analyze` and `flutter test`.
4. Open a pull request against `dev`.
