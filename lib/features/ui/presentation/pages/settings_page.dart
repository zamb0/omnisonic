import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/theme_mode_controller.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/download_preferences_service.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import '../../../offline/presentation/viewmodels/offline_mode_view_model.dart';
import '../../../playback/data/datasources/adaptive_streaming_service.dart';
import '../widgets/widgets.dart';

/// Settings screen. Every row here is backed by a real, already-persisted
/// setting or a real piece of app state — nothing is a decorative stub.
/// Where the mockup implied a setting that doesn't actually exist (audio
/// quality preference, cache size limit), it's shown as read-only info
/// instead of a fake interactive control.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeaderAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeModeCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Playback'),
          _buildPlaybackCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Library & Cache'),
          _buildLibraryCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Account'),
          _buildAccountCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'About'),
          _buildAboutCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: OmnisonicTypography.overline.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildThemeModeCard(BuildContext context) {
    final current = context.watch<ThemeModeController>().themeMode;
    const options = {
      ThemeMode.system: (OmnisonicIcons.brightnessAuto, 'System'),
      ThemeMode.light: (OmnisonicIcons.lightMode, 'Light'),
      ThemeMode.dark: (OmnisonicIcons.darkMode, 'Dark'),
    };

    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      padding: EdgeInsets.zero,
      child: RadioGroup<ThemeMode>(
        groupValue: current,
        onChanged: (mode) {
          if (mode != null) {
            ThemeModeController.instance.setThemeMode(mode);
          }
        },
        child: Column(
          children: [
            for (final entry in options.entries)
              RadioListTile<ThemeMode>(
                value: entry.key,
                secondary: Icon(entry.value.$1),
                title: Text(entry.value.$2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackCard(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Consumer<PlaybackViewModel>(
            builder: (context, vm, child) {
              final streaming = getIt.isRegistered<AdaptiveStreamingService>()
                  ? getIt<AdaptiveStreamingService>()
                  : null;
              final cap = streaming?.qualityCap;
              return ListTile(
                leading: const Icon(OmnisonicIcons.graphicEq),
                title: const Text('Streaming quality'),
                subtitle: Text(
                  cap == null
                      ? 'Automatic — adapts to your connection. Now: '
                            '${vm.currentQuality.displayName}'
                      : 'Up to ${cap.displayName}, lower when the '
                            'connection struggles',
                ),
                trailing: const Icon(OmnisonicIcons.chevronRight),
                onTap: streaming == null
                    ? null
                    : () => _chooseQuality(context, streaming, cap),
              );
            },
          ),
          const Divider(height: 1),
          AnimatedBuilder(
            animation: Haptics.instance,
            builder: (context, child) {
              return SwitchListTile(
                secondary: const Icon(OmnisonicIcons.touchApp),
                title: const Text('Haptic feedback'),
                subtitle: const Text(
                  'A short tap when playback or the queue changes',
                ),
                value: Haptics.instance.enabled,
                onChanged: Haptics.instance.setEnabled,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: DownloadPreferencesService.instance,
            builder: (context, child) {
              return SwitchListTile(
                secondary: const Icon(OmnisonicIcons.wifi),
                title: const Text('Wi-Fi only downloads'),
                subtitle: const Text('Only download new content on Wi-Fi'),
                value: DownloadPreferencesService.instance.wifiOnlyEnabled,
                onChanged: (value) => DownloadPreferencesService.instance
                    .setWifiOnlyEnabled(value),
              );
            },
          ),
          if (_hasProvider<OfflineModeViewModel>(context))
            const Divider(height: 1),
          if (_hasProvider<OfflineModeViewModel>(context))
            Consumer<OfflineModeViewModel>(
              builder: (context, offline, child) => SwitchListTile(
                secondary: const Icon(OmnisonicIcons.cloudOff),
                title: const Text('Offline mode'),
                subtitle: const Text(
                  'Use only what is downloaded, even with a connection',
                ),
                value: offline.isForcedOffline,
                onChanged: offline.setOfflineMode,
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(OmnisonicIcons.image),
            title: const Text('Clear artwork cache'),
            subtitle: const Text(
              'Frees space; covers download again as you browse',
            ),
            onTap: () => _clearArtworkCache(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(OmnisonicIcons.downloadOutline),
            title: const Text('Downloads'),
            subtitle: const Text('Manage offline content'),
            trailing: const Icon(OmnisonicIcons.chevronRight),
            onTap: () => context.push(AppRouter.downloads),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Consumer<ServerManagementViewModel>(
      builder: (context, viewModel, child) {
        final count = viewModel.serverCount;
        return GlassSurface(
          borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(OmnisonicIcons.dnsOutline),
            title: const Text('Servers'),
            subtitle: Text(
              count == 0
                  ? 'No servers connected'
                  : '$count server${count == 1 ? '' : 's'} connected',
            ),
            trailing: const Icon(OmnisonicIcons.chevronRight),
            onTap: () => context.push(AppRouter.servers),
          ),
        );
      },
    );
  }

  Future<void> _chooseQuality(
    BuildContext context,
    AdaptiveStreamingService service,
    AudioQuality? current,
  ) {
    const options = <(AudioQuality?, String, String)>[
      (null, 'Automatic', 'The best your connection can carry'),
      (AudioQuality.ultra, 'Original', 'As stored on the server'),
      (AudioQuality.high, 'High', 'MP3, the highest bitrate'),
      (AudioQuality.medium, 'Standard', 'Saves data'),
      (AudioQuality.low, 'Low', 'Least data'),
    ];
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<AudioQuality?>(
          groupValue: current,
          onChanged: (value) {
            service.setQualityCap(value);
            Navigator.pop(sheetContext);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (value, title, subtitle) in options)
                RadioListTile<AudioQuality?>(
                  value: value,
                  title: Text(title),
                  subtitle: Text(subtitle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearArtworkCache(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear artwork cache?',
      message: 'Covers are downloaded again as you browse.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) return;
    await OmnisonicImageCacheManager.instance.emptyCache();
    if (context.mounted) {
      showFeedback(
        context,
        'Artwork cache cleared',
        kind: FeedbackKind.success,
      );
    }
  }

  Widget _buildAboutCard(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(OmnisonicIcons.info),
            title: const Text('About Omnisonic'),
            subtitle: const Text(
              'One library across all your Subsonic servers',
            ),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Omnisonic',
              applicationLegalese:
                  'A client for Subsonic-compatible music servers.',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(OmnisonicIcons.description),
            title: const Text('Open-source licences'),
            trailing: const Icon(OmnisonicIcons.chevronRight),
            onTap: () =>
                showLicensePage(context: context, applicationName: 'Omnisonic'),
          ),
        ],
      ),
    );
  }

  static bool _hasProvider<T>(BuildContext context) {
    try {
      Provider.of<T>(context, listen: false);
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }
}
