import 'package:flutter/material.dart';
import 'design_system.dart';

/// Example integration showing how to use the Omnisonic Design System
/// This file demonstrates the proper usage of colors, typography, spacing, and components
class DesignSystemExample extends StatelessWidget {
  const DesignSystemExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Design System Example',
          style: context.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const OmnisonicIconWidget(OmnisonicIcons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: OmnisonicInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colors Section
            _buildSection(context, 'Colors', _buildColorsDemo(context)),

            // Typography Section
            _buildSection(context, 'Typography', _buildTypographyDemo(context)),

            // Spacing Section
            _buildSection(context, 'Spacing', _buildSpacingDemo(context)),

            // Components Section
            _buildSection(context, 'Components', _buildComponentsDemo(context)),

            // Music Components Section
            _buildSection(
              context,
              'Music Components',
              _buildMusicComponentsDemo(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textTheme.headlineSmall),
        const SizedBox(height: OmnisonicSpacing.md),
        content,
        const SizedBox(height: OmnisonicSpacing.xl),
      ],
    );
  }

  Widget _buildColorsDemo(BuildContext context) {
    return Column(
      children: [
        // Primary Colors
        Row(
          children: [
            _buildColorSwatch('Primary', context.colorScheme.primary),
            const SizedBox(width: OmnisonicSpacing.md),
            _buildColorSwatch('Secondary', context.colorScheme.secondary),
            const SizedBox(width: OmnisonicSpacing.md),
            _buildColorSwatch('Tertiary', context.colorScheme.tertiary),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.md),

        // Semantic Colors
        Row(
          children: [
            _buildColorSwatch('Success', OmnisonicColors.success),
            const SizedBox(width: OmnisonicSpacing.md),
            _buildColorSwatch('Warning', OmnisonicColors.warning),
            const SizedBox(width: OmnisonicSpacing.md),
            _buildColorSwatch('Error', context.colorScheme.error),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.md),

        // Gradient Demo
        Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
            borderRadius: BorderRadius.circular(OmnisonicRadius.md),
          ),
          child: const Center(
            child: Text(
              'Primary Gradient',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
            ),
          ),
          const SizedBox(height: OmnisonicSpacing.xs),
          Text(name, style: OmnisonicTypography.labelSmall),
        ],
      ),
    );
  }

  Widget _buildTypographyDemo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large', style: context.textTheme.displayLarge),
        Text('Headline Medium', style: context.textTheme.headlineMedium),
        Text('Title Large', style: context.textTheme.titleLarge),
        Text('Body Large', style: context.textTheme.bodyLarge),
        Text('Label Medium', style: context.textTheme.labelMedium),
        const SizedBox(height: OmnisonicSpacing.md),

        // Music-specific typography
        Text('Track Title', style: context.textTheme.trackTitle),
        Text('Artist Name', style: context.textTheme.artistName),
        Text('Album Title', style: context.textTheme.albumTitle),
      ],
    );
  }

  Widget _buildSpacingDemo(BuildContext context) {
    return Column(
      children: [
        _buildSpacingExample('XS (4px)', OmnisonicSpacing.xs),
        _buildSpacingExample('SM (8px)', OmnisonicSpacing.sm),
        _buildSpacingExample('MD (16px)', OmnisonicSpacing.md),
        _buildSpacingExample('LG (24px)', OmnisonicSpacing.lg),
        _buildSpacingExample('XL (32px)', OmnisonicSpacing.xl),
      ],
    );
  }

  Widget _buildSpacingExample(String name, double spacing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OmnisonicSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(name, style: OmnisonicTypography.labelMedium),
          ),
          Container(
            width: spacing,
            height: 20,
            color: OmnisonicColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsDemo(BuildContext context) {
    return Column(
      children: [
        // Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Elevated'),
              ),
            ),
            const SizedBox(width: OmnisonicSpacing.md),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined'),
              ),
            ),
            const SizedBox(width: OmnisonicSpacing.md),
            Expanded(
              child: TextButton(onPressed: () {}, child: const Text('Text')),
            ),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.md),

        // Cards
        Card(
          child: Padding(
            padding: OmnisonicInsets.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Card Example', style: context.textTheme.titleMedium),
                const SizedBox(height: OmnisonicSpacing.sm),
                Text(
                  'This is an example card using the design system.',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicComponentsDemo(BuildContext context) {
    return Column(
      children: [
        // Album Card Example
        Card(
          child: Padding(
            padding: OmnisonicInsets.card,
            child: Row(
              children: [
                context.albumArtwork(width: 60, height: 60),
                const SizedBox(width: OmnisonicSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Album Title', style: context.textTheme.trackTitle),
                      Text('Artist Name', style: context.textTheme.artistName),
                    ],
                  ),
                ),
                OmnisonicIconWidget.favorite(),
              ],
            ),
          ),
        ),
        const SizedBox(height: OmnisonicSpacing.md),

        // Playback Controls Example
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const OmnisonicIconWidget(OmnisonicIcons.skipPrevious),
              onPressed: () {},
            ),
            const SizedBox(width: OmnisonicSpacing.md),
            Container(
              decoration: BoxDecoration(
                gradient: context.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: OmnisonicIconWidget.play(color: Colors.white),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: OmnisonicSpacing.md),
            IconButton(
              icon: const OmnisonicIconWidget(OmnisonicIcons.skipNext),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
