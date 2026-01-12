import 'package:flutter/material.dart';
import 'loading_states.dart';
import 'gesture_feedback.dart';
import 'error_states.dart';
import 'spacing.dart';

/// Examples demonstrating loading states and feedback systems
/// for the Omnisonic design system.
class LoadingFeedbackExamples extends StatefulWidget {
  const LoadingFeedbackExamples({Key? key}) : super(key: key);

  @override
  State<LoadingFeedbackExamples> createState() => _LoadingFeedbackExamplesState();
}

class _LoadingFeedbackExamplesState extends State<LoadingFeedbackExamples> {
  bool _isLoading = false;
  bool _showError = false;
  String _selectedExample = 'Loading States';

  final List<String> _examples = [
    'Loading States',
    'Gesture Feedback',
    'Error States',
    'Interactive Examples',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading & Feedback Examples'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Example selector
          Container(
            height: 60,
            padding: OmnisonicInsets.horizontalMd,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _examples.length,
              itemBuilder: (context, index) {
                final example = _examples[index];
                final isSelected = example == _selectedExample;
                
                return Padding(
                  padding: EdgeInsets.only(right: OmnisonicSpacing.sm),
                  child: OmnisonicGestureFeedback.pressableScale(
                    onPressed: () {
                      setState(() {
                        _selectedExample = example;
                      });
                    },
                    child: Container(
                      padding: OmnisonicInsets.horizontalMd,
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          example,
                          style: TextStyle(
                            color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: OmnisonicInsets.allMd,
              child: _buildExampleContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleContent() {
    switch (_selectedExample) {
      case 'Loading States':
        return _buildLoadingStatesExample();
      case 'Gesture Feedback':
        return _buildGestureFeedbackExample();
      case 'Error States':
        return _buildErrorStatesExample();
      case 'Interactive Examples':
        return _buildInteractiveExample();
      default:
        return Container();
    }
  }

  Widget _buildLoadingStatesExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Skeleton Loading'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Track list skeleton
        Card(
          child: Column(
            children: List.generate(3, (index) => 
              OmnisonicLoadingStates.trackListItemSkeleton()
            ),
          ),
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Album Cards Skeleton'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Album cards skeleton
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(right: OmnisonicSpacing.md),
              child: OmnisonicLoadingStates.albumCardSkeleton(),
            ),
          ),
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Artist Cards Skeleton'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Artist cards skeleton
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(right: OmnisonicSpacing.md),
              child: OmnisonicLoadingStates.artistCardSkeleton(),
            ),
          ),
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Progress Indicators'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Progress indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                OmnisonicLoadingStates.progressIndicator(),
                SizedBox(height: OmnisonicSpacing.sm),
                const Text('Circular'),
              ],
            ),
            Column(
              children: [
                OmnisonicLoadingStates.pulsingDots(),
                SizedBox(height: OmnisonicSpacing.sm),
                const Text('Pulsing Dots'),
              ],
            ),
            Column(
              children: [
                OmnisonicLoadingStates.waveIndicator(),
                SizedBox(height: OmnisonicSpacing.sm),
                const Text('Wave'),
              ],
            ),
          ],
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Linear Progress'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Linear progress examples
        Column(
          children: [
            OmnisonicLoadingStates.linearProgress(value: 0.3),
            SizedBox(height: OmnisonicSpacing.md),
            OmnisonicLoadingStates.linearProgress(value: 0.7),
            SizedBox(height: OmnisonicSpacing.md),
            OmnisonicLoadingStates.linearProgress(), // Indeterminate
          ],
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Contextual Loading Animations'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Contextual loading examples
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                OmnisonicLoadingStates.musicLoading(message: 'Loading music...'),
                SizedBox(height: OmnisonicSpacing.sm),
                const Text('Music Loading'),
              ],
            ),
            Column(
              children: [
                OmnisonicLoadingStates.searchLoading(message: 'Searching...'),
                SizedBox(height: OmnisonicSpacing.sm),
                const Text('Search Loading'),
              ],
            ),
          ],
        ),
        
        SizedBox(height: OmnisonicSpacing.lg),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                OmnisonicLoadingStates.syncLoading(message: 'Syncing library...'),
                SizedBox(height: OmnisonicSpacing.sm),
                const Text('Sync Loading'),
              ],
            ),
            Column(
              children: [
                OmnisonicLoadingStates.downloadLoading(
                  message: 'Downloading...',
                  progress: 0.6,
                ),
                SizedBox(height: OmnisonicSpacing.sm),
                const Text('Download Loading'),
              ],
            ),
          ],
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Adaptive Loading'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Adaptive loading examples
        Column(
          children: [
            OmnisonicLoadingStates.adaptiveLoading(
              contentType: 'playlist',
              message: 'Loading your playlist...',
              estimatedDuration: const Duration(seconds: 2),
            ),
            SizedBox(height: OmnisonicSpacing.lg),
            OmnisonicLoadingStates.adaptiveLoading(
              contentType: 'artist',
              message: 'Loading artist information...',
              estimatedDuration: const Duration(seconds: 3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGestureFeedbackExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tap Feedback'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Ripple effect
        Card(
          child: OmnisonicGestureFeedback.rippleEffect(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ripple effect tapped!')),
              );
            },
            child: Container(
              padding: OmnisonicInsets.allLg,
              child: const Row(
                children: [
                  Icon(Icons.touch_app),
                  SizedBox(width: 16),
                  Text('Tap for ripple effect'),
                ],
              ),
            ),
          ),
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Scale Feedback'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Scale feedback
        Row(
          children: [
            Expanded(
              child: OmnisonicGestureFeedback.pressableScale(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scale button pressed!')),
                  );
                },
                child: Container(
                  padding: OmnisonicInsets.allLg,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Press me'),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Long Press Feedback'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Long press feedback
        Row(
          children: [
            Expanded(
              child: OmnisonicGestureFeedback.longPressable(
                onLongPress: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Long press detected!')),
                  );
                },
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Short tap detected!')),
                  );
                },
                child: Container(
                  padding: OmnisonicInsets.allLg,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Tap or hold me'),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Swipe Feedback'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // Swipe feedback
        Card(
          child: OmnisonicGestureFeedback.swipeable(
            onSwipeLeft: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Swiped left!')),
              );
            },
            onSwipeRight: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Swiped right!')),
              );
            },
            child: Container(
              padding: OmnisonicInsets.allXl,
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.swipe, size: 32),
                    SizedBox(height: 8),
                    Text('Swipe left or right'),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('State Change Animations'),
        SizedBox(height: OmnisonicSpacing.md),
        
        // State change examples
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OmnisonicGestureFeedback.animatedState(
                    state: ComponentState.selected,
                    child: Container(
                      padding: OmnisonicInsets.allMd,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('Selected State')),
                    ),
                  ),
                ),
                SizedBox(width: OmnisonicSpacing.md),
                Expanded(
                  child: OmnisonicGestureFeedback.animatedState(
                    state: ComponentState.disabled,
                    child: Container(
                      padding: OmnisonicInsets.allMd,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('Disabled State')),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: OmnisonicSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OmnisonicGestureFeedback.animatedState(
                    state: ComponentState.loading,
                    child: Container(
                      padding: OmnisonicInsets.allMd,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('Loading State')),
                    ),
                  ),
                ),
                SizedBox(width: OmnisonicSpacing.md),
                Expanded(
                  child: OmnisonicGestureFeedback.animatedState(
                    state: ComponentState.error,
                    child: Container(
                      padding: OmnisonicInsets.allMd,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('Error State')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorStatesExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Network Error'),
        SizedBox(height: OmnisonicSpacing.md),
        
        OmnisonicErrorStates.networkError(
          onRetry: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Retrying...')),
            );
          },
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Server Error'),
        SizedBox(height: OmnisonicSpacing.md),
        
        OmnisonicErrorStates.serverError(
          onRetry: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trying again...')),
            );
          },
          onContactSupport: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening support...')),
            );
          },
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Empty Library'),
        SizedBox(height: OmnisonicSpacing.md),
        
        OmnisonicErrorStates.emptyLibrary(
          onBrowseMusic: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening music browser...')),
            );
          },
          onImportMusic: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening import dialog...')),
            );
          },
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Inline Error'),
        SizedBox(height: OmnisonicSpacing.md),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            OmnisonicErrorStates.inlineError(
              message: 'Please enter a valid email address',
            ),
          ],
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Snackbar Error'),
        SizedBox(height: OmnisonicSpacing.md),
        
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              OmnisonicErrorStates.snackbarError(
                message: 'Something went wrong!',
                actionLabel: 'Retry',
                onAction: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Retrying...')),
                  );
                },
              ),
            );
          },
          child: const Text('Show Error Snackbar'),
        ),
      ],
    );
  }

  Widget _buildInteractiveExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Loading Overlay'),
        SizedBox(height: OmnisonicSpacing.md),
        
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                
                // Simulate loading
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
              child: const Text('Start Loading'),
            ),
            SizedBox(width: OmnisonicSpacing.md),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showError = !_showError;
                });
              },
              child: Text(_showError ? 'Hide Error' : 'Show Error'),
            ),
          ],
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        
        // Interactive content area
        OmnisonicLoadingStates.screenOverlay(
          isLoading: _isLoading,
          message: 'Loading your music...',
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _showError
              ? Center(
                  child: OmnisonicErrorStates.playbackError(
                    onRetry: () {
                      setState(() {
                        _showError = false;
                      });
                    },
                    onSkip: () {
                      setState(() {
                        _showError = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Skipped track')),
                      );
                    },
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_note, size: 64),
                      SizedBox(height: 16),
                      Text('Your music content would appear here'),
                    ],
                  ),
                ),
          ),
        ),
        
        SizedBox(height: OmnisonicSpacing.xl),
        _buildSectionTitle('Drag and Drop'),
        SizedBox(height: OmnisonicSpacing.md),
        
        Row(
          children: [
            // Draggable item
            Expanded(
              child: OmnisonicGestureFeedback.draggable<String>(
                data: 'Song Title',
                onDragStarted: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Started dragging song')),
                  );
                },
                child: Container(
                  padding: OmnisonicInsets.allMd,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.music_note),
                      SizedBox(width: 8),
                      Text('Drag me to playlist'),
                    ],
                  ),
                ),
              ),
            ),
            
            SizedBox(width: OmnisonicSpacing.lg),
            
            // Drop target
            Expanded(
              child: OmnisonicGestureFeedback.dropTarget<String>(
                onWillAccept: (data) => data == 'Song Title',
                onAccept: (data) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "$data" to playlist')),
                  );
                },
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.playlist_add),
                        Text('Drop here'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}