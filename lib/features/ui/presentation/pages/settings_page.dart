import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/theme_mode_controller.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/device_identity.dart';
import '../../../../core/services/download_preferences_service.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/web_support.dart';
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
      // A column of controls, capped at a readable width: on desktop the
      // rows used to run the full width of the window, with each switch a
      // thousand pixels from its label.
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          OmnisonicSpacing.gutter(context),
          OmnisonicSpacing.sm,
          OmnisonicSpacing.gutter(context),
          OmnisonicLayout.pageBottom,
        ),
        children: [
          ReadableWidth(
            maxWidth: OmnisonicLayout.readableMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Appearance', first: true),
                _buildThemeModeCard(context),
                _buildSectionHeader('Playback'),
                _buildPlaybackCard(context),
                _buildSectionHeader('This device'),
                _buildDeviceCard(context),
                _buildSectionHeader('Library & Cache'),
                _buildLibraryCard(context),
                _buildSectionHeader('Account'),
                _buildAccountCard(context),
                _buildSectionHeader('About'),
                _buildAboutCard(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Eyebrow over each group, in line with the group's rows.
  Widget _buildSectionHeader(String title, {bool first = false}) =>
      SectionHeader(
        title: title,
        size: SectionHeaderSize.small,
        padding: EdgeInsets.fromLTRB(
          OmnisonicSpacing.xs,
          first ? 0 : OmnisonicSpacing.lg,
          OmnisonicSpacing.xs,
          OmnisonicSpacing.sm,
        ),
      );

  /// One glass group of settings rows, with dividers inset to the text so
  /// they separate rows without cutting through the icon column.
  static Widget _group(List<Widget> rows) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
      padding: const EdgeInsets.symmetric(vertical: OmnisonicSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            rows[i],
          ],
        ],
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

    // Three exclusive options side by side: a segmented control, not three
    // radio rows.
    return _group([
      Padding(
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Theme',
              style: OmnisonicTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.ms),
            OmnisonicSegmented<ThemeMode>(
              options: [
                for (final entry in options.entries)
                  SegmentOption(
                    value: entry.key,
                    icon: entry.value.$1,
                    label: entry.value.$2,
                  ),
              ],
              selected: current,
              onChanged: ThemeModeController.instance.setThemeMode,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildPlaybackCard(BuildContext context) {
    return _group([
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
    ]);
  }

  /// How this device appears to the user's other devices, which hand
  /// playback over to each other (see HandoffService).
  Widget _buildDeviceCard(BuildContext context) {
    if (!getIt.isRegistered<DeviceIdentity>()) return const SizedBox.shrink();
    final identity = getIt<DeviceIdentity>();
    return AnimatedBuilder(
      animation: identity,
      builder: (context, child) => _group([
        ListTile(
          leading: const Icon(OmnisonicIcons.devices),
          title: const Text('Device name'),
          subtitle: Text(
            '${identity.name} — shown on your other devices when this one '
            'is playing',
          ),
          trailing: const Icon(OmnisonicIcons.chevronRight),
          onTap: () async {
            final name = await showTextInputDialog(
              context,
              title: 'Device name',
              label: 'Name',
              confirmLabel: 'Save',
              initialValue: identity.name,
              validator: (value) =>
                  value.length > 40 ? 'Use 40 characters or fewer' : null,
            );
            if (name != null) await identity.rename(name);
          },
        ),
      ]),
    );
  }

  Widget _buildLibraryCard(BuildContext context) {
    if (!supportsOfflineDownloads) {
      return _group([
        const ListTile(
          leading: Icon(OmnisonicIcons.downloadOutline),
          title: Text('Downloads unavailable'),
          subtitle: Text(offlineUnavailableOnWebMessage),
        ),
        _clearArtworkTile(context),
      ]);
    }
    return _group([
      AnimatedBuilder(
        animation: DownloadPreferencesService.instance,
        builder: (context, child) {
          return SwitchListTile(
            secondary: const Icon(OmnisonicIcons.wifi),
            title: const Text('Wi-Fi only downloads'),
            subtitle: const Text('Only download new content on Wi-Fi'),
            value: DownloadPreferencesService.instance.wifiOnlyEnabled,
            onChanged: (value) =>
                DownloadPreferencesService.instance.setWifiOnlyEnabled(value),
          );
        },
      ),
      if (_hasProvider<OfflineModeViewModel>(context))
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
      _clearArtworkTile(context),
      ListTile(
        leading: const Icon(OmnisonicIcons.downloadOutline),
        title: const Text('Downloads'),
        subtitle: const Text('Manage offline content'),
        trailing: const Icon(OmnisonicIcons.chevronRight),
        onTap: () => context.push(AppRouter.downloads),
      ),
    ]);
  }

  Widget _clearArtworkTile(BuildContext context) {
    return ListTile(
      leading: const Icon(OmnisonicIcons.image),
      title: const Text('Clear artwork cache'),
      subtitle: const Text('Frees space; covers download again as you browse'),
      onTap: () => _clearArtworkCache(context),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Consumer<ServerManagementViewModel>(
      builder: (context, viewModel, child) {
        final count = viewModel.serverCount;
        return _group([
          ListTile(
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
        ]);
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
      useRootNavigator: true,
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
    return _group([
      ListTile(
        leading: const Icon(OmnisonicIcons.info),
        title: const Text('About Omnisonic'),
        subtitle: const Text('One library across all your Subsonic servers'),
        onTap: () => showAboutDialog(
          context: context,
          applicationName: 'Omnisonic',
          applicationLegalese:
              'A client for Subsonic-compatible music servers.',
        ),
      ),
      ListTile(
        leading: const Icon(OmnisonicIcons.description),
        title: const Text('Open-source licences'),
        trailing: const Icon(OmnisonicIcons.chevronRight),
        onTap: () =>
            showLicensePage(context: context, applicationName: 'Omnisonic'),
      ),
      // The route only exists in debug builds; so does its way in.
      if (kDebugMode)
        ListTile(
          leading: const Icon(OmnisonicIcons.palette),
          title: const Text('Component gallery'),
          subtitle: const Text('Debug builds only'),
          trailing: const Icon(OmnisonicIcons.chevronRight),
          onTap: () => context.push(AppRouter.devGallery),
        ),
    ]);
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
