import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';
import 'gesture_feedback.dart';

/// Error state components for the Omnisonic design system.
/// Provides user-friendly error presentations with clear recovery actions.
class OmnisonicErrorStates {
  OmnisonicErrorStates._();

  /// Creates a generic error widget with recovery actions
  static Widget errorWidget({
    required String title,
    required String message,
    IconData? icon,
    List<ErrorAction>? actions,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return _ErrorWidget(
      title: title,
      message: message,
      icon: icon ?? Icons.error_outline,
      actions: actions ?? [],
      backgroundColor: backgroundColor,
      iconColor: iconColor,
    );
  }

  /// Creates a network error widget
  static Widget networkError({
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    return errorWidget(
      title: 'Connection Problem',
      message: customMessage ?? 'Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      actions: onRetry != null ? [
        ErrorAction(
          label: 'Retry',
          onPressed: onRetry,
          isPrimary: true,
        ),
      ] : [],
    );
  }

  /// Creates a server error widget
  static Widget serverError({
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onContactSupport,
  }) {
    return errorWidget(
      title: 'Server Error',
      message: customMessage ?? 'Something went wrong on our end. Please try again later.',
      icon: Icons.cloud_off,
      actions: [
        if (onRetry != null)
          ErrorAction(
            label: 'Try Again',
            onPressed: onRetry,
            isPrimary: true,
          ),
        if (onContactSupport != null)
          ErrorAction(
            label: 'Contact Support',
            onPressed: onContactSupport,
            isPrimary: false,
          ),
      ],
    );
  }

  /// Creates a not found error widget
  static Widget notFound({
    String? title,
    String? message,
    VoidCallback? onGoBack,
    VoidCallback? onGoHome,
  }) {
    return errorWidget(
      title: title ?? 'Not Found',
      message: message ?? 'The content you\'re looking for doesn\'t exist or has been moved.',
      icon: Icons.search_off,
      actions: [
        if (onGoBack != null)
          ErrorAction(
            label: 'Go Back',
            onPressed: onGoBack,
            isPrimary: false,
          ),
        if (onGoHome != null)
          ErrorAction(
            label: 'Go Home',
            onPressed: onGoHome,
            isPrimary: true,
          ),
      ],
    );
  }

  /// Creates a permission denied error widget
  static Widget permissionDenied({
    String? customMessage,
    VoidCallback? onRequestPermission,
    VoidCallback? onOpenSettings,
  }) {
    return errorWidget(
      title: 'Permission Required',
      message: customMessage ?? 'This feature requires additional permissions to work properly.',
      icon: Icons.lock_outline,
      actions: [
        if (onRequestPermission != null)
          ErrorAction(
            label: 'Grant Permission',
            onPressed: onRequestPermission,
            isPrimary: true,
          ),
        if (onOpenSettings != null)
          ErrorAction(
            label: 'Open Settings',
            onPressed: onOpenSettings,
            isPrimary: false,
          ),
      ],
    );
  }

  /// Creates a playback error widget
  static Widget playbackError({
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onSkip,
  }) {
    return errorWidget(
      title: 'Playback Error',
      message: customMessage ?? 'Unable to play this track. It may be unavailable or corrupted.',
      icon: Icons.music_off,
      actions: [
        if (onRetry != null)
          ErrorAction(
            label: 'Retry',
            onPressed: onRetry,
            isPrimary: true,
          ),
        if (onSkip != null)
          ErrorAction(
            label: 'Skip Track',
            onPressed: onSkip,
            isPrimary: false,
          ),
      ],
    );
  }

  /// Creates an empty state widget (not technically an error, but similar pattern)
  static Widget emptyState({
    required String title,
    required String message,
    IconData? icon,
    List<ErrorAction>? actions,
  }) {
    return _EmptyStateWidget(
      title: title,
      message: message,
      icon: icon ?? Icons.inbox_outlined,
      actions: actions ?? [],
    );
  }

  /// Creates an empty library widget
  static Widget emptyLibrary({
    VoidCallback? onBrowseMusic,
    VoidCallback? onImportMusic,
  }) {
    return emptyState(
      title: 'Your Library is Empty',
      message: 'Start building your music collection by browsing or importing your favorite tracks.',
      icon: Icons.library_music_outlined,
      actions: [
        if (onBrowseMusic != null)
          ErrorAction(
            label: 'Browse Music',
            onPressed: onBrowseMusic,
            isPrimary: true,
          ),
        if (onImportMusic != null)
          ErrorAction(
            label: 'Import Music',
            onPressed: onImportMusic,
            isPrimary: false,
          ),
      ],
    );
  }

  /// Creates an empty search results widget
  static Widget emptySearchResults({
    required String query,
    VoidCallback? onClearSearch,
    VoidCallback? onBrowsePopular,
  }) {
    return emptyState(
      title: 'No Results Found',
      message: 'We couldn\'t find anything matching "$query". Try a different search term.',
      icon: Icons.search_off,
      actions: [
        if (onClearSearch != null)
          ErrorAction(
            label: 'Clear Search',
            onPressed: onClearSearch,
            isPrimary: false,
          ),
        if (onBrowsePopular != null)
          ErrorAction(
            label: 'Browse Popular',
            onPressed: onBrowsePopular,
            isPrimary: true,
          ),
      ],
    );
  }

  /// Creates an inline error message for form fields
  static Widget inlineError({
    required String message,
    IconData? icon,
    Color? color,
  }) {
    return _InlineErrorWidget(
      message: message,
      icon: icon ?? Icons.error_outline,
      color: color,
    );
  }

  /// Creates a snackbar error message
  static SnackBar snackbarError({
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
    Duration duration = const Duration(seconds: 4),
  }) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: OmnisonicSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: OmnisonicColors.error,
      duration: duration,
      action: onAction != null && actionLabel != null
        ? SnackBarAction(
            label: actionLabel,
            textColor: Colors.white,
            onPressed: onAction,
          )
        : null,
    );
  }
}

/// Represents an action that can be taken from an error state
class ErrorAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;

  const ErrorAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.icon,
  });
}

/// Internal error widget implementation
class _ErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final List<ErrorAction> actions;
  final Color? backgroundColor;
  final Color? iconColor;

  const _ErrorWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.actions,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: OmnisonicInsets.allXl,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: iconColor ?? colorScheme.error,
          ),
          SizedBox(height: OmnisonicSpacing.lg),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: OmnisonicSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (actions.isNotEmpty) ...[
            SizedBox(height: OmnisonicSpacing.xl),
            Wrap(
              spacing: OmnisonicSpacing.md,
              runSpacing: OmnisonicSpacing.sm,
              alignment: WrapAlignment.center,
              children: actions.map((action) => _buildActionButton(
                context,
                action,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ErrorAction action) {
    final theme = Theme.of(context);
    
    if (action.isPrimary) {
      return OmnisonicGestureFeedback.pressableScale(
        onPressed: action.onPressed,
        child: ElevatedButton.icon(
          onPressed: action.onPressed,
          icon: action.icon != null ? Icon(action.icon) : null,
          label: Text(action.label),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.lg,
              vertical: OmnisonicSpacing.md,
            ),
          ),
        ),
      );
    } else {
      return OmnisonicGestureFeedback.pressableScale(
        onPressed: action.onPressed,
        child: OutlinedButton.icon(
          onPressed: action.onPressed,
          icon: action.icon != null ? Icon(action.icon) : null,
          label: Text(action.label),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.lg,
              vertical: OmnisonicSpacing.md,
            ),
          ),
        ),
      );
    }
  }
}

/// Internal empty state widget implementation
class _EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final List<ErrorAction> actions;

  const _EmptyStateWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: OmnisonicInsets.allXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 80,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: OmnisonicSpacing.xl),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: OmnisonicSpacing.md),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (actions.isNotEmpty) ...[
            SizedBox(height: OmnisonicSpacing.xl),
            Wrap(
              spacing: OmnisonicSpacing.md,
              runSpacing: OmnisonicSpacing.sm,
              alignment: WrapAlignment.center,
              children: actions.map((action) => _buildActionButton(
                context,
                action,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ErrorAction action) {
    if (action.isPrimary) {
      return OmnisonicGestureFeedback.pressableScale(
        onPressed: action.onPressed,
        child: ElevatedButton.icon(
          onPressed: action.onPressed,
          icon: action.icon != null ? Icon(action.icon) : null,
          label: Text(action.label),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.lg,
              vertical: OmnisonicSpacing.md,
            ),
          ),
        ),
      );
    } else {
      return OmnisonicGestureFeedback.pressableScale(
        onPressed: action.onPressed,
        child: OutlinedButton.icon(
          onPressed: action.onPressed,
          icon: action.icon != null ? Icon(action.icon) : null,
          label: Text(action.label),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.lg,
              vertical: OmnisonicSpacing.md,
            ),
          ),
        ),
      );
    }
  }
}

/// Internal inline error widget implementation
class _InlineErrorWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const _InlineErrorWidget({
    required this.message,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = color ?? theme.colorScheme.error;
    
    return Padding(
      padding: EdgeInsets.only(top: OmnisonicSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: errorColor,
          ),
          SizedBox(width: OmnisonicSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}