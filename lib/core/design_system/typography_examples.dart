import 'package:flutter/material.dart';
import 'enhanced_text.dart';
import 'animated_text.dart';
import 'typography.dart';
import 'spacing.dart';

/// Example page demonstrating the enhanced typography system
class TypographyExamplesPage extends StatefulWidget {
  const TypographyExamplesPage({super.key});

  @override
  State<TypographyExamplesPage> createState() => _TypographyExamplesPageState();
}

class _TypographyExamplesPageState extends State<TypographyExamplesPage> {
  bool _showAnimations = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typography Examples'),
        actions: [
          IconButton(
            icon: Icon(_showAnimations ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _showAnimations = !_showAnimations;
              });
            },
            tooltip: _showAnimations ? 'Pause Animations' : 'Start Animations',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: OmnisonicInsets.allLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Music Metadata Typography',
              _buildMusicMetadataExamples(),
            ),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildSection(
              'Text Truncation & Tooltips',
              _buildTruncationExamples(),
            ),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildSection('Typography Animations', _buildAnimationExamples()),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildSection('Loading States', _buildLoadingExamples()),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildSection('Emphasis Effects', _buildEmphasisExamples()),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildSection('Expandable Text', _buildExpandableExample()),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: OmnisonicTypography.headlineSmall),
        const SizedBox(height: OmnisonicSpacing.md),
        Card(
          child: Padding(padding: OmnisonicInsets.allMd, child: content),
        ),
      ],
    );
  }

  Widget _buildMusicMetadataExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Track title examples
        const TrackTitleText('Bohemian Rhapsody'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const TrackTitleText('Bohemian Rhapsody', isPlaying: true),
        const SizedBox(height: OmnisonicSpacing.xs),
        const TrackTitleText('Bohemian Rhapsody', isSelected: true),

        const SizedBox(height: OmnisonicSpacing.md),

        // Artist name examples
        const ArtistNameText('Queen'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const ArtistNameText('Queen', isSecondary: true),

        const SizedBox(height: OmnisonicSpacing.md),

        // Album title examples
        const AlbumTitleText('A Night at the Opera'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const AlbumTitleText('A Night at the Opera', isSecondary: true),

        const SizedBox(height: OmnisonicSpacing.md),

        // Playlist title examples
        const PlaylistTitleText('My Favorite Rock Songs'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const PlaylistTitleText('My Favorite Rock Songs', isLarge: true),

        const SizedBox(height: OmnisonicSpacing.md),

        // Now playing examples
        const NowPlayingText(title: 'Bohemian Rhapsody', artist: 'Queen'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const NowPlayingText(
          title: 'Bohemian Rhapsody',
          artist: 'Queen',
          isLarge: true,
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        // Duration examples
        const DurationText(Duration(minutes: 5, seconds: 55)),
        const SizedBox(height: OmnisonicSpacing.xs),
        const DurationText(
          Duration(hours: 1, minutes: 23, seconds: 45),
          showHours: true,
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        // Metadata examples
        const MetadataText(label: 'Genre', value: 'Progressive Rock'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const MetadataText(label: 'Year', value: '1975', isVertical: true),
      ],
    );
  }

  Widget _buildTruncationExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Single line truncation with tooltip:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const SizedBox(
          width: 200,
          child: EnhancedText(
            'This is a very long text that will be truncated and show a tooltip when hovered',
            maxLines: 1,
          ),
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Multi-line truncation:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const SizedBox(
          width: 250,
          child: EnhancedText(
            'This is a longer text that demonstrates multi-line truncation. It will show multiple lines before being truncated with an ellipsis.',
            maxLines: 2,
          ),
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Track title with truncation:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const SizedBox(
          width: 180,
          child: TrackTitleText(
            'This is a Very Long Song Title That Will Be Truncated',
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationExamples() {
    if (!_showAnimations) {
      return const Text('Click the play button to see animations');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fade In Animation:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        AnimatedText(
          'Fade In Text',
          animationType: TextAnimationType.fadeIn,
          style: OmnisonicTypography.titleMedium,
          key: ValueKey('fade_$_showAnimations'),
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Slide Up Animation:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        AnimatedText(
          'Slide Up Text',
          animationType: TextAnimationType.slideUp,
          style: OmnisonicTypography.titleMedium,
          key: ValueKey('slide_$_showAnimations'),
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Scale In Animation:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        AnimatedText(
          'Scale In Text',
          animationType: TextAnimationType.scaleIn,
          style: OmnisonicTypography.titleMedium,
          key: ValueKey('scale_$_showAnimations'),
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Bounce Animation:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        AnimatedText(
          'Bounce Text',
          animationType: TextAnimationType.bounce,
          style: OmnisonicTypography.titleMedium,
          key: ValueKey('bounce_$_showAnimations'),
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Typewriter Animation:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        AnimatedText(
          'This text appears character by character',
          animationType: TextAnimationType.typewriter,
          style: OmnisonicTypography.bodyLarge,
          key: ValueKey('typewriter_$_showAnimations'),
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Shimmer Animation:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        Container(
          color: Colors.grey[800],
          padding: OmnisonicInsets.allSm,
          child: AnimatedText(
            'Shimmer Effect Text',
            animationType: TextAnimationType.shimmer,
            style: OmnisonicTypography.titleMedium.copyWith(
              color: Colors.grey[400],
            ),
            key: ValueKey('shimmer_$_showAnimations'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Loading with dots:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const LoadingText(
          'Loading',
          loadingType: LoadingType.dots,
          style: OmnisonicTypography.bodyLarge,
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Loading with wave effect:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const LoadingText(
          'Loading',
          loadingType: LoadingType.wave,
          style: OmnisonicTypography.titleMedium,
        ),

        const SizedBox(height: OmnisonicSpacing.md),

        const Text('Loading with fade effect:'),
        const SizedBox(height: OmnisonicSpacing.xs),
        const LoadingText(
          'Loading content...',
          loadingType: LoadingType.fade,
          style: OmnisonicTypography.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildEmphasisExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tap these texts to see emphasis effects:'),
        const SizedBox(height: OmnisonicSpacing.md),

        EmphasisText(
          'Pulse Effect (Tap me)',
          emphasisType: EmphasisType.pulse,
          style: OmnisonicTypography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
          onTap: () {},
        ),

        const SizedBox(height: OmnisonicSpacing.sm),

        EmphasisText(
          'Bounce Effect (Tap me)',
          emphasisType: EmphasisType.bounce,
          style: OmnisonicTypography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
          onTap: () {},
        ),

        const SizedBox(height: OmnisonicSpacing.sm),

        EmphasisText(
          'Glow Effect (Auto)',
          emphasisType: EmphasisType.glow,
          style: OmnisonicTypography.titleMedium,
          autoStart: true,
        ),

        const SizedBox(height: OmnisonicSpacing.sm),

        EmphasisText(
          'Shake Effect (Tap me)',
          emphasisType: EmphasisType.shake,
          style: OmnisonicTypography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildExpandableExample() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expandable text example:'),
        SizedBox(height: OmnisonicSpacing.xs),
        ExpandableText(
          'This is a long text that demonstrates the expandable text functionality. '
          'When the text is longer than the specified number of lines, it will show '
          'a "Show more" link that allows the user to expand the text to see the full '
          'content. After expanding, a "Show less" link will appear to collapse the '
          'text back to its original state. This is particularly useful for descriptions, '
          'reviews, or any other content that might be lengthy but should be initially '
          'displayed in a condensed format to save space and improve the user experience.',
          maxLines: 3,
        ),
      ],
    );
  }
}
