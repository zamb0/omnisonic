import 'package:flutter/material.dart';
import 'animation_manager.dart';
import 'micro_interactions.dart';
import 'colors.dart';

/// Example implementations demonstrating the animation framework
class AnimationExamples extends StatelessWidget {
  const AnimationExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animation Framework Examples')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InteractiveButtonExample(),
            SizedBox(height: 24),
            _InteractiveCardExample(),
            SizedBox(height: 24),
            _InteractiveListExample(),
            SizedBox(height: 24),
            _HoverEffectExample(),
            SizedBox(height: 24),
            _PulseAnimationExample(),
          ],
        ),
      ),
    );
  }
}

/// Interactive button example
class _InteractiveButtonExample extends StatelessWidget {
  const _InteractiveButtonExample();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interactive Buttons',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            MicroInteractions.interactiveButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Primary button pressed!')),
                );
              },
              backgroundColor: OmnisonicColors.primaryPurple,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Text(
                'Primary Button',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            MicroInteractions.interactiveButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Secondary button pressed!')),
                );
              },
              backgroundColor: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              rippleColor: OmnisonicColors.primaryBlue,
              child: Text(
                'Secondary Button',
                style: TextStyle(
                  color: OmnisonicColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Interactive card example
class _InteractiveCardExample extends StatelessWidget {
  const _InteractiveCardExample();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interactive Cards',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MicroInteractions.interactiveCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Album card tapped!')),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(
                      Icons.album,
                      size: 48,
                      color: OmnisonicColors.primaryPurple,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Album Title',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('Artist Name', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MicroInteractions.interactiveCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist card tapped!')),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(
                      Icons.playlist_play,
                      size: 48,
                      color: OmnisonicColors.primaryTeal,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Playlist',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('24 songs', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Interactive list example
class _InteractiveListExample extends StatelessWidget {
  const _InteractiveListExample();

  @override
  Widget build(BuildContext context) {
    final tracks = [
      'Track 1 - Artist A',
      'Track 2 - Artist B',
      'Track 3 - Artist C',
      'Track 4 - Artist D',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interactive List Items',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: tracks.asMap().entries.map((entry) {
              final index = entry.key;
              final track = entry.value;

              return MicroInteractions.interactiveListItem(
                index: index,
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$track tapped!')));
                },
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            OmnisonicColors.primaryGradient.colors[index % 2],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        track,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.grey),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Hover effect example (desktop only)
class _HoverEffectExample extends StatelessWidget {
  const _HoverEffectExample();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hover Effects (Desktop)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        MicroInteractions.hoverEffect(
          builder: (isHovering) {
            return AnimatedContainer(
              duration: AnimationManager.hoverDuration,
              curve: AnimationManager.hoverCurve,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHovering
                    ? OmnisonicColors.primaryPurple.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHovering
                      ? OmnisonicColors.primaryPurple
                      : Colors.grey.withValues(alpha: 0.3),
                  width: isHovering ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.computer,
                    color: isHovering
                        ? OmnisonicColors.primaryPurple
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Hover over me (desktop only)',
                    style: TextStyle(
                      color: isHovering ? OmnisonicColors.primaryPurple : null,
                      fontWeight: isHovering
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
          child: Container(), // Not used in this example
        ),
      ],
    );
  }
}

/// Pulse animation example
class _PulseAnimationExample extends StatelessWidget {
  const _PulseAnimationExample();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pulse Animation',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Center(
          child: MicroInteractions.pulseAnimation(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: OmnisonicColors.primaryGradient,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: OmnisonicColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Performance monitoring widget
class AnimationPerformanceMonitor extends StatefulWidget {
  const AnimationPerformanceMonitor({super.key});

  @override
  State<AnimationPerformanceMonitor> createState() =>
      _AnimationPerformanceMonitorState();
}

class _AnimationPerformanceMonitorState
    extends State<AnimationPerformanceMonitor> {
  final AnimationManager _animationManager = AnimationManager();

  @override
  void initState() {
    super.initState();
    _animationManager.initialize(enablePerformanceMonitoring: true);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Animation Performance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Active Animations: ${_animationManager.activeAnimationCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Performance Monitoring: ${_animationManager.isPerformanceMonitoringEnabled ? "Enabled" : "Disabled"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
