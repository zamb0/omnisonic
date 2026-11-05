import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../widgets/widgets.dart';

/// Every component of the design system, variant by state, light and dark
/// side by side (docs/design-system.md). The base for review and for the
/// golden suite; reachable at `/dev/gallery` in debug builds only.
///
/// Nothing here talks to a server or a view model: it is built from the
/// widgets with inline sample data, so it renders on a bare install.
class ComponentGalleryPage extends StatelessWidget {
  const ComponentGalleryPage({super.key});

  /// The sections, in order. The golden suite renders each by its id.
  static const List<String> sectionIds = [
    'buttons',
    'inputs',
    'badges',
    'navigation',
    'cards',
    'rows',
    'player',
    'overlays',
    'states',
  ];

  /// The key of the section named [id].
  static Key sectionKey(String id) => Key('gallery-$id');

  @override
  Widget build(BuildContext context) {
    final sections = <String, (String, WidgetBuilder)>{
      'buttons': ('Buttons', (_) => const _Buttons()),
      'inputs': ('Input and selection', (_) => const _Inputs()),
      'badges': ('Chips, badges, banners', (_) => const _Badges()),
      'navigation': ('Navigation', (_) => const _Navigation()),
      'cards': ('Cards', (_) => const _Cards()),
      'rows': ('Track rows', (_) => const _Rows()),
      'player': ('Player', (_) => const _Player()),
      'overlays': ('Overlays', (_) => const _Overlays()),
      'states': ('States', (_) => const _States()),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Component gallery')),
      // Every section is built (a Column, not a lazy list): the golden
      // suite and a long review both want them all, and this is a debug page.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final id in sectionIds)
              // A repaint boundary per section, so a golden can capture one.
              RepaintBoundary(
                key: sectionKey(id),
                child: _Section(
                  title: sections[id]!.$1,
                  builder: sections[id]!.$2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A titled section, shown once per theme, side by side when there is room.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    Widget panel(ThemeData theme) => Theme(
      data: theme,
      child: Builder(
        builder: (context) => DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
          ),
          child: Padding(
            padding: const EdgeInsets.all(OmnisonicSpacing.md),
            // A Material of its own so ink, chips and fields work.
            child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                style: OmnisonicTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    );

    // The page's own canvas behind the title, so the section reads (and
    // captures) the same way wherever it is cropped.
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(bottom: OmnisonicSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: OmnisonicTypography.sectionTitleSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.ms),
            LayoutBuilder(
              builder: (context, constraints) {
                final dark = panel(OmnisonicTheme.darkTheme);
                final light = panel(OmnisonicTheme.lightTheme);
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      dark,
                      const SizedBox(height: OmnisonicSpacing.md),
                      light,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dark),
                    const SizedBox(width: OmnisonicSpacing.md),
                    Expanded(child: light),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled row of samples.
class _Row extends StatelessWidget {
  const _Row(this.label, this.children);

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: OmnisonicSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: OmnisonicTypography.eyebrow.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: OmnisonicSpacing.sm),
          Wrap(
            spacing: OmnisonicSpacing.sm,
            runSpacing: OmnisonicSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ],
      ),
    );
  }
}

void _noop() {}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Aurora · sm md lg', [
          for (final size in OmnisonicButtonSize.values)
            AuroraButton(
              label: 'Play',
              icon: OmnisonicIcons.playArrow,
              onPressed: _noop,
              size: size,
            ),
        ]),
        _Row('Aurora · loading, disabled', [
          AuroraButton(
            label: 'Play all',
            icon: OmnisonicIcons.playArrow,
            onPressed: _noop,
            loading: true,
          ),
          const AuroraButton(label: 'Play all', onPressed: null),
        ]),
        _Row('Primary · default, loading, disabled', [
          const OmnisonicButton(label: 'Save', onPressed: _noop),
          const OmnisonicButton(label: 'Save', onPressed: _noop, loading: true),
          const OmnisonicButton(label: 'Save', onPressed: null),
        ]),
        _Row('Tonal', [
          const OmnisonicButton(
            label: 'Shuffle',
            icon: OmnisonicIcons.shuffle,
            variant: OmnisonicButtonVariant.tonal,
            onPressed: _noop,
          ),
          const OmnisonicButton(
            label: 'Shuffle',
            variant: OmnisonicButtonVariant.tonal,
            onPressed: null,
          ),
        ]),
        _Row('Destructive', [
          const OmnisonicButton(
            label: 'Delete',
            variant: OmnisonicButtonVariant.destructive,
            onPressed: _noop,
          ),
          const OmnisonicButton(
            label: 'Delete',
            variant: OmnisonicButtonVariant.destructive,
            onPressed: null,
          ),
        ]),
        _Row('Outlined, text', [
          OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
          TextButton(onPressed: () {}, child: const Text('See all')),
          const OutlinedButton(onPressed: null, child: Text('Disabled')),
        ]),
        _Row('Play disc · 44 48 56 64, pause, disabled', [
          for (final size in PlayDiscSize.values)
            PlayDisc(onPressed: _noop, size: size),
          const PlayDisc(onPressed: _noop, playing: true),
          const PlayDisc(onPressed: null),
        ]),
        _Row('Icon buttons', [
          for (final variant in OmnisonicIconButtonVariant.values)
            OmnisonicIconButton(
              icon: OmnisonicIcons.playlistAdd,
              tooltip: variant.name,
              variant: variant,
              onPressed: _noop,
            ),
          const OmnisonicIconButton(
            icon: OmnisonicIcons.playlistAdd,
            tooltip: 'disabled',
            onPressed: null,
          ),
        ]),
        _Row('Toggles · off, favourite on, on', [
          const OmnisonicIconButton(
            icon: OmnisonicIcons.favoriteOutline,
            tooltip: 'Favourite',
            variant: OmnisonicIconButtonVariant.toggle,
            onPressed: _noop,
          ),
          OmnisonicIconButton(
            icon: OmnisonicIcons.favoriteOutline,
            selectedIcon: OmnisonicIcons.favorite,
            selectedColor: OmnisonicBrand.of(context).heat,
            tooltip: 'Favourite',
            variant: OmnisonicIconButtonVariant.toggle,
            selected: true,
            onPressed: _noop,
          ),
          const OmnisonicIconButton(
            icon: OmnisonicIcons.shuffle,
            tooltip: 'Shuffle',
            variant: OmnisonicIconButtonVariant.toggle,
            selected: true,
            onPressed: _noop,
          ),
        ]),
      ],
    );
  }
}

class _Inputs extends StatelessWidget {
  const _Inputs();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Search', [
          SizedBox(
            width: 320,
            child: SearchField(
              controller: TextEditingController(text: 'Kind of'),
              hint: 'Search albums',
            ),
          ),
        ]),
        _Row('Text fields · helper, error', [
          const SizedBox(
            width: 320,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Server URL',
                helperText: 'Include the port',
              ),
            ),
          ),
          SizedBox(
            width: 320,
            child: TextFormField(
              autovalidateMode: AutovalidateMode.always,
              validator: (_) => 'Enter a valid URL',
              decoration: const InputDecoration(labelText: 'Username'),
            ),
          ),
        ]),
        _Row('Chips · selected, not, choice', [
          FilterChip(
            label: const Text('Albums'),
            selected: true,
            onSelected: (_) {},
          ),
          FilterChip(
            label: const Text('Artists'),
            selected: false,
            onSelected: (_) {},
          ),
          ChoiceChip(
            label: const Text('All servers'),
            selected: true,
            onSelected: (_) {},
          ),
        ]),
        _Row('Segmented', [
          SizedBox(
            width: 320,
            child: OmnisonicSegmented<int>(
              selected: 1,
              onChanged: (_) {},
              options: const [
                SegmentOption(
                  value: 0,
                  label: 'Light',
                  icon: OmnisonicIcons.lightMode,
                ),
                SegmentOption(
                  value: 1,
                  label: 'Dark',
                  icon: OmnisonicIcons.darkMode,
                ),
                SegmentOption(
                  value: 2,
                  label: 'Auto',
                  icon: OmnisonicIcons.brightnessAuto,
                ),
              ],
            ),
          ),
        ]),
        _Row('Switch, checkbox, radio', [
          Switch(value: true, onChanged: (_) {}),
          Switch(value: false, onChanged: (_) {}),
          Checkbox(value: true, onChanged: (_) {}),
          Checkbox(value: false, onChanged: (_) {}),
          RadioGroup<int>(
            groupValue: 1,
            onChanged: (_) {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Radio<int>(value: 1), Radio<int>(value: 2)],
            ),
          ),
        ]),
        _Row('Slider', [
          SizedBox(width: 320, child: Slider(value: 0.4, onChanged: (_) {})),
        ]),
      ],
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Metadata', const [
          MetadataChip(icon: OmnisonicIcons.album, label: '12 tracks'),
          MetadataChip(icon: OmnisonicIcons.dns, label: '2 servers'),
        ]),
        _Row('Quality', [
          for (final quality in AudioQuality.values)
            QualityBadge(quality: quality),
        ]),
        _Row('Server status', [
          for (final status in ServerStatus.values) StatusChip(status: status),
        ]),
        const _Row('Banners', [
          SizedBox(
            width: 380,
            child: Column(
              children: [
                InlineBanner(
                  kind: BannerKind.info,
                  title: 'Offline copy',
                  message: 'Showing what was cached.',
                ),
                SizedBox(height: OmnisonicSpacing.sm),
                InlineBanner(
                  kind: BannerKind.success,
                  message: 'Connected to Living Room.',
                ),
                SizedBox(height: OmnisonicSpacing.sm),
                InlineBanner(
                  kind: BannerKind.warning,
                  message: 'Backup is slow to answer.',
                ),
                SizedBox(height: OmnisonicSpacing.sm),
                InlineBanner(
                  kind: BannerKind.error,
                  message: 'Could not reach Attic.',
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget item(String label, IconData icon, IconData active, bool selected) {
      return Stack(
        alignment: Alignment.centerLeft,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: navPillColor(context, selected: selected),
              borderRadius: BorderRadius.circular(OmnisonicRadius.pill),
            ),
            child: SizedBox(
              width: 200,
              height: OmnisonicTouchTargets.minimum,
              child: Row(
                children: [
                  const SizedBox(width: OmnisonicSpacing.ms),
                  Icon(
                    selected ? active : icon,
                    size: OmnisonicIconSizes.smd,
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: OmnisonicSpacing.ms),
                  Text(
                    label,
                    style: OmnisonicTypography.navLabel.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AuroraBar(visible: selected),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Sidebar item · selected, not', [
          item('Home', OmnisonicIcons.homeOutline, OmnisonicIcons.home, true),
          item('Search', OmnisonicIcons.search, OmnisonicIcons.search, false),
        ]),
        _Row('Account avatar · healthy, degraded, down', [
          for (final health in [
            ServerHealth.healthy,
            ServerHealth.degraded,
            ServerHealth.down,
            ServerHealth.none,
          ])
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: health.status == null
                    ? null
                    : Border.all(
                        color: ServerStatusVisuals.of(
                          context,
                          health.status!,
                        ).color,
                        width: 2,
                      ),
              ),
              child: Icon(
                OmnisonicIcons.personOutline,
                size: OmnisonicIconSizes.sm,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ]),
      ],
    );
  }
}

final _album = Album(
  id: 'gallery_a1',
  title: 'Kind of Blue',
  artist: 'Miles Davis',
  serverId: 'gallery',
  lastModified: DateTime(2026, 1, 1),
  year: 1959,
  trackCount: 5,
);

final _artist = Artist(
  id: 'gallery_ar1',
  name: 'Miles Davis',
  serverId: 'gallery',
  lastModified: DateTime(2026, 1, 1),
  albumCount: 3,
);

Track _track(int n, {AudioQuality quality = AudioQuality.lossless}) => Track(
  id: 'gallery_t$n',
  title: ['So What', 'Freddie Freeloader', 'Blue in Green', 'All Blues'][n % 4],
  artist: 'Miles Davis',
  album: 'Kind of Blue',
  duration: Duration(minutes: 3 + n, seconds: 20),
  serverId: 'gallery',
  streamUrl: 'https://gallery.test/stream/$n',
  quality: quality,
  lastModified: DateTime(2026, 1, 1),
  albumId: 'gallery_a1',
  trackNumber: n + 1,
);

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OmnisonicSpacing.md,
      runSpacing: OmnisonicSpacing.md,
      children: [
        SizedBox(
          width: 150,
          height: AlbumCard.extentFor(context, 150),
          child: AlbumCard(album: _album, width: 150, showActions: true),
        ),
        SizedBox(
          width: 150,
          height: AlbumCard.extentFor(context, 150),
          child: AlbumCard(
            album: _album,
            width: 150,
            sourceServerIds: const ['a', 'b'],
          ),
        ),
        SizedBox(
          width: 150,
          height: MediaCard.extentFor(
            context,
            150,
            subtitle: false,
            meta: true,
          ),
          child: ArtistCard(artist: _artist, width: 150),
        ),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TrackRow(
          track: _track(0),
          leading: TrackRowLeading.trackNumber,
          qualityLabel: 'FLAC',
          isCurrent: false,
          onTap: _noop,
          onShowActions: _noop,
        ),
        TrackRow(
          track: _track(1),
          leading: TrackRowLeading.trackNumber,
          qualityLabel: 'FLAC',
          isCurrent: true,
          onTap: _noop,
          onShowActions: _noop,
        ),
        TrackRow(
          track: _track(2),
          leading: TrackRowLeading.trackNumber,
          qualityLabel: 'FLAC',
          isCurrent: false,
          selected: true,
          onTap: _noop,
          onShowActions: _noop,
        ),
        TrackRow(
          track: _track(3),
          leading: TrackRowLeading.trackNumber,
          qualityLabel: 'FLAC',
          isCurrent: false,
          unavailable: true,
          onTap: _noop,
          onShowActions: _noop,
        ),
        TrackRow(track: _track(4), isCurrent: false, onTap: _noop),
      ],
    );
  }
}

class _Player extends StatelessWidget {
  const _Player();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Seek bar · 1:00 of 4:00', [
          const SizedBox(
            width: 360,
            child: AuroraProgress(
              position: Duration(minutes: 1),
              duration: Duration(minutes: 4),
              buffered: 0.5,
              onSeek: _ignore,
            ),
          ),
        ]),
        const _Row('Mini player line', [
          SizedBox(width: 360, child: AuroraProgressLine(fraction: 0.35)),
        ]),
        const _Row('Now playing bars · playing, paused', [
          NowPlayingEqualizer(playing: true),
          NowPlayingEqualizer(playing: false),
        ]),
        _Row('Transport', [
          PlayDisc(onPressed: _noop, size: PlayDiscSize.s64),
          const PlayDisc(
            onPressed: _noop,
            playing: true,
            size: PlayDiscSize.s64,
          ),
        ]),
        const _Row('Quality', [
          QualityBadge(quality: AudioQuality.high),
          QualityBadge(quality: AudioQuality.lossless),
        ]),
      ],
    );
  }
}

void _ignore(Duration _) {}

class _Overlays extends StatelessWidget {
  const _Overlays();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row('Dialog', [
          SizedBox(
            width: 380,
            // The real dialog widget, laid out inline.
            child: AlertDialog(
              title: const Text('Remove server?'),
              content: const Text('Its albums leave your collection.'),
              actions: [
                TextButton(onPressed: () {}, child: const Text('Cancel')),
                const OmnisonicButton(
                  label: 'Remove',
                  variant: OmnisonicButtonVariant.destructive,
                  onPressed: _noop,
                ),
              ],
            ),
          ),
        ]),
        _Row('Menu', [
          Material(
            color: scheme.surfaceContainerHigh,
            elevation: 16,
            shadowColor: OmnisonicColors.overlayShadow,
            shape: Theme.of(context).popupMenuTheme.shape,
            child: const SizedBox(
              width: 220,
              child: Column(
                children: [
                  MenuItemButton(
                    leadingIcon: Icon(OmnisonicIcons.playArrow),
                    onPressed: _noop,
                    child: Text('Play next'),
                  ),
                  MenuItemButton(
                    leadingIcon: Icon(OmnisonicIcons.delete),
                    onPressed: _noop,
                    child: Text('Remove'),
                  ),
                ],
              ),
            ),
          ),
        ]),
        _Row('Snackbar', [
          Container(
            width: 320,
            padding: const EdgeInsets.all(OmnisonicSpacing.md),
            decoration: BoxDecoration(
              color: scheme.inverseSurface,
              borderRadius: BorderRadius.circular(OmnisonicRadius.control),
            ),
            child: Row(
              children: [
                Icon(
                  OmnisonicIcons.checkCircle,
                  size: OmnisonicIconSizes.smd,
                  color: scheme.brightness == Brightness.light
                      ? OmnisonicColors.success
                      : OmnisonicColors.successAccessible,
                ),
                const SizedBox(width: OmnisonicSpacing.ms),
                Expanded(
                  child: Text(
                    'Playlist saved',
                    style: OmnisonicTypography.bodyMedium.copyWith(
                      color: scheme.onInverseSurface,
                    ),
                  ),
                ),
                Text(
                  'Undo',
                  style: OmnisonicTypography.button.copyWith(
                    color: scheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 360,
          child: EmptyState(
            icon: OmnisonicIcons.dnsOutline,
            title: 'No music server yet',
            subtitle: 'Add a Subsonic-compatible server to start.',
            action: AuroraButton(
              label: 'Add server',
              icon: OmnisonicIcons.add,
              onPressed: _noop,
            ),
          ),
        ),
        SizedBox(
          height: 360,
          child: ErrorStateView(
            message: 'Could not reach the server.',
            onRetry: _noop,
          ),
        ),
        const Row(
          children: [
            SkeletonCard(width: 110),
            SizedBox(width: OmnisonicSpacing.md),
            SkeletonCard(width: 110),
          ],
        ),
        const SkeletonTile(),
        const SkeletonTile(),
      ],
    );
  }
}
