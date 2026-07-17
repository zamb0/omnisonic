import 'package:flutter/material.dart';
import 'accessibility_preferences.dart';
import 'accessible_button.dart';
import 'accessibility.dart';
import 'spacing.dart';
import 'theme.dart';

/// Accessibility settings screen for managing user preferences
class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  final OmnisonicAccessibilityPreferences _preferences =
      OmnisonicAccessibilityPreferences();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accessibility Settings',
        ).withSemanticLabel('Accessibility Settings'),
        leading: AccessibleButton.icon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
          semanticLabel: 'Go back',
          tooltip: 'Return to previous screen',
        ),
      ),
      body: ListenableBuilder(
        listenable: _preferences,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: OmnisonicInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'Motion & Animation',
                  'Control how animations and motion effects behave',
                ),
                _buildMotionSettings(),

                const SizedBox(height: OmnisonicSpacing.sectionSpacing),

                _buildSectionHeader(
                  'Visual Preferences',
                  'Adjust visual elements for better readability',
                ),
                _buildVisualSettings(),

                const SizedBox(height: OmnisonicSpacing.sectionSpacing),

                _buildSectionHeader(
                  'Interaction & Feedback',
                  'Customize how the app responds to your interactions',
                ),
                _buildInteractionSettings(),

                const SizedBox(height: OmnisonicSpacing.sectionSpacing),

                _buildSectionHeader(
                  'System Integration',
                  'How the app works with your device accessibility settings',
                ),
                _buildSystemIntegrationInfo(),

                const SizedBox(height: OmnisonicSpacing.sectionSpacing),

                _buildResetSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ).asSemanticHeader(label: title),
        const SizedBox(height: OmnisonicSpacing.xs),
        Text(
          description,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: OmnisonicSpacing.md),
      ],
    );
  }

  Widget _buildMotionSettings() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          children: [
            AccessibleSwitchListTile(
              title: 'Reduce Motion',
              subtitle:
                  'Minimize animations and transitions for a calmer experience',
              value: _preferences.reducedMotionEnabled,
              onChanged: _preferences.setReducedMotionEnabled,
              semanticLabel: 'Reduce motion animations',
            ),
            if (_preferences.systemReducedMotionEnabled)
              Padding(
                padding: const EdgeInsets.only(top: OmnisonicSpacing.sm),
                child: Container(
                  padding: OmnisonicInsets.allSm,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: OmnisonicSpacing.sm),
                      Expanded(
                        child: Text(
                          'System reduce motion is enabled. This setting will be automatically applied.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualSettings() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          children: [
            AccessibleSwitchListTile(
              title: 'High Contrast',
              subtitle: 'Increase color contrast for better visibility',
              value: _preferences.highContrastEnabled,
              onChanged: _preferences.setHighContrastEnabled,
              semanticLabel: 'Enable high contrast mode',
            ),
            const Divider(),
            AccessibleSwitchListTile(
              title: 'Large Text',
              subtitle: 'Use larger text sizes throughout the app',
              value: _preferences.largeTextEnabled,
              onChanged: _preferences.setLargeTextEnabled,
              semanticLabel: 'Enable large text',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionSettings() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          children: [
            AccessibleSwitchListTile(
              title: 'Haptic Feedback',
              subtitle:
                  'Feel vibrations when interacting with buttons and controls',
              value: _preferences.hapticFeedbackEnabled,
              onChanged: _preferences.setHapticFeedbackEnabled,
              semanticLabel: 'Enable haptic feedback',
            ),
            const Divider(),
            AccessibleSwitchListTile(
              title: 'Screen Reader Optimizations',
              subtitle: 'Enhanced labels and descriptions for screen readers',
              value: _preferences.screenReaderEnabled,
              onChanged: _preferences.setScreenReaderEnabled,
              semanticLabel: 'Enable screen reader optimizations',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemIntegrationInfo() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_accessibility,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: OmnisonicSpacing.sm),
                Text(
                  'System Accessibility',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            Text(
              'This app automatically respects your device\'s accessibility settings including:',
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            _buildSystemFeatureItem(
              'Reduce Motion',
              _preferences.systemReducedMotionEnabled,
            ),
            _buildSystemFeatureItem('Voice Control', false), // Placeholder
            _buildSystemFeatureItem('Switch Control', false), // Placeholder
            const SizedBox(height: OmnisonicSpacing.sm),
            AccessibleButton.text(
              onPressed: () => _showSystemSettingsDialog(),
              semanticLabel: 'Open device accessibility settings',
              child: const Text('Open Device Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemFeatureItem(String feature, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isEnabled
                ? context.colorScheme.primary
                : context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: OmnisonicSpacing.sm),
          Text(
            feature,
            style: context.textTheme.bodySmall?.copyWith(
              color: isEnabled
                  ? context.colorScheme.onSurface
                  : context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetSection() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Settings',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            Text(
              'Reset all accessibility preferences to their default values.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            AccessibleButton.outlined(
              onPressed: () => _showResetDialog(),
              semanticLabel: 'Reset all accessibility settings to defaults',
              child: const Text('Reset to Defaults'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSystemSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Accessibility Settings'),
        content: const Text(
          'To modify your device\'s accessibility settings, please go to:\n\n'
          'Settings > Accessibility\n\n'
          'Changes made there will automatically apply to this app.',
        ),
        actions: [
          AccessibleButton.text(
            onPressed: () => Navigator.of(context).pop(),
            semanticLabel: 'Close dialog',
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Accessibility Settings'),
        content: const Text(
          'Are you sure you want to reset all accessibility preferences to their default values? This action cannot be undone.',
        ),
        actions: [
          AccessibleButton.text(
            onPressed: () => Navigator.of(context).pop(),
            semanticLabel: 'Cancel reset',
            child: const Text('Cancel'),
          ),
          AccessibleButton.elevated(
            onPressed: () {
              _resetSettings();
              Navigator.of(context).pop();
            },
            semanticLabel: 'Confirm reset settings',
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    _preferences.setReducedMotionEnabled(false);
    _preferences.setHighContrastEnabled(false);
    _preferences.setLargeTextEnabled(false);
    _preferences.setScreenReaderEnabled(false);
    _preferences.setHapticFeedbackEnabled(true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accessibility settings have been reset to defaults'),
      ),
    );
  }
}

/// Accessible switch list tile with proper semantics
class AccessibleSwitchListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  const AccessibleSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? title,
      hint: subtitle,
      toggled: value,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: SwitchListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

/// Widget that provides accessibility settings as an overlay
class AccessibilityQuickSettings extends StatefulWidget {
  final Widget child;

  const AccessibilityQuickSettings({super.key, required this.child});

  @override
  State<AccessibilityQuickSettings> createState() =>
      _AccessibilityQuickSettingsState();
}

class _AccessibilityQuickSettingsState
    extends State<AccessibilityQuickSettings> {
  final OmnisonicAccessibilityPreferences _preferences =
      OmnisonicAccessibilityPreferences();
  bool _showQuickSettings = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showQuickSettings)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: _buildQuickSettingsPanel(),
          ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: AccessibleFloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                _showQuickSettings = !_showQuickSettings;
              });
            },
            semanticLabel: _showQuickSettings
                ? 'Close accessibility quick settings'
                : 'Open accessibility quick settings',
            tooltip: 'Accessibility Quick Settings',
            child: Icon(_showQuickSettings ? Icons.close : Icons.accessibility),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSettingsPanel() {
    return Card(
      elevation: 8,
      child: Container(
        width: 280,
        padding: OmnisonicInsets.card,
        child: ListenableBuilder(
          listenable: _preferences,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Settings',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).asSemanticHeader(),
                const SizedBox(height: OmnisonicSpacing.md),

                AccessibleSwitchListTile(
                  title: 'Reduce Motion',
                  value: _preferences.reducedMotionEnabled,
                  onChanged: _preferences.setReducedMotionEnabled,
                  semanticLabel: 'Toggle reduce motion',
                ),

                AccessibleSwitchListTile(
                  title: 'High Contrast',
                  value: _preferences.highContrastEnabled,
                  onChanged: _preferences.setHighContrastEnabled,
                  semanticLabel: 'Toggle high contrast',
                ),

                AccessibleSwitchListTile(
                  title: 'Haptic Feedback',
                  value: _preferences.hapticFeedbackEnabled,
                  onChanged: _preferences.setHapticFeedbackEnabled,
                  semanticLabel: 'Toggle haptic feedback',
                ),

                const SizedBox(height: OmnisonicSpacing.md),

                AccessibleButton.text(
                  onPressed: () {
                    setState(() {
                      _showQuickSettings = false;
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const AccessibilitySettingsScreen(),
                      ),
                    );
                  },
                  semanticLabel: 'Open full accessibility settings',
                  child: const Text('More Settings'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
