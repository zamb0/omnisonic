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
      appBar: AppBar(title: const Text('Settings')),
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
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Consumer<PlaybackViewModel>(
            builder: (context, vm, child) {
              return ListTile(
                leading: const Icon(OmnisonicIcons.graphicEq),
                title: const Text('Streaming quality'),
                subtitle: const Text(
                  'Automatic — adapts to your network connection',
                ),
                trailing: Text(
                  vm.currentQuality.format,
                  style: OmnisonicTypography.metadata.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
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
}
