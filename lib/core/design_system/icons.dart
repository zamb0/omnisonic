import 'package:flutter/material.dart';

/// Icon system for Omnisonic UI Enhancement
/// Provides consistent icon usage across the application
class OmnisonicIcons {
  // Music playback icons
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData stop = Icons.stop_rounded;
  static const IconData skipNext = Icons.skip_next_rounded;
  static const IconData skipPrevious = Icons.skip_previous_rounded;
  static const IconData fastForward = Icons.fast_forward_rounded;
  static const IconData fastRewind = Icons.fast_rewind_rounded;
  static const IconData replay = Icons.replay_rounded;
  static const IconData shuffle = Icons.shuffle_rounded;
  static const IconData repeat = Icons.repeat_rounded;
  static const IconData repeatOne = Icons.repeat_one_rounded;

  // Volume and audio icons
  static const IconData volumeUp = Icons.volume_up_rounded;
  static const IconData volumeDown = Icons.volume_down_rounded;
  static const IconData volumeMute = Icons.volume_mute_rounded;
  static const IconData volumeOff = Icons.volume_off_rounded;
  static const IconData equalizer = Icons.equalizer_rounded;
  static const IconData audiotrack = Icons.audiotrack_rounded;

  // Navigation icons
  static const IconData home = Icons.home_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData library = Icons.library_music_rounded;
  static const IconData playlist = Icons.playlist_play_rounded;
  static const IconData album = Icons.album_rounded;
  static const IconData artist = Icons.person_rounded;
  static const IconData folder = Icons.folder_rounded;
  static const IconData settings = Icons.settings_rounded;

  // Action icons
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteOutline = Icons.favorite_outline_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData upload = Icons.upload_rounded;

  // UI control icons
  static const IconData menu = Icons.menu_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData forward = Icons.arrow_forward_rounded;
  static const IconData expand = Icons.expand_more_rounded;
  static const IconData collapse = Icons.expand_less_rounded;
  static const IconData fullscreen = Icons.fullscreen_rounded;
  static const IconData fullscreenExit = Icons.fullscreen_exit_rounded;

  // Status icons
  static const IconData online = Icons.cloud_done_rounded;
  static const IconData offline = Icons.cloud_off_rounded;
  static const IconData sync = Icons.sync_rounded;
  static const IconData syncProblem = Icons.sync_problem_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData success = Icons.check_circle_rounded;

  // Theme and display icons
  static const IconData lightMode = Icons.light_mode_rounded;
  static const IconData darkMode = Icons.dark_mode_rounded;
  static const IconData autoMode = Icons.brightness_auto_rounded;
  static const IconData visibility = Icons.visibility_rounded;
  static const IconData visibilityOff = Icons.visibility_off_rounded;

  // Server and connection icons
  static const IconData server = Icons.dns_rounded;
  static const IconData wifi = Icons.wifi_rounded;
  static const IconData wifiOff = Icons.wifi_off_rounded;
  static const IconData signal = Icons.signal_cellular_4_bar_rounded;
  static const IconData signalOff = Icons.signal_cellular_off_rounded;

  // Queue and playlist icons
  static const IconData queue = Icons.queue_music_rounded;
  static const IconData queueAdd = Icons.queue_rounded;
  static const IconData playlistAdd = Icons.playlist_add_rounded;
  static const IconData playlistRemove = Icons.playlist_remove_rounded;
  static const IconData reorder = Icons.reorder_rounded;

  // Filter and sort icons
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData sortAsc = Icons.sort_by_alpha_rounded;
  static const IconData sortDesc = Icons.sort_rounded;
  static const IconData clear = Icons.clear_rounded;

  // View mode icons
  static const IconData gridView = Icons.grid_view_rounded;
  static const IconData listView = Icons.view_list_rounded;
  static const IconData cardView = Icons.view_module_rounded;

  // More icons
  static const IconData more = Icons.more_vert_rounded;
  static const IconData moreHoriz = Icons.more_horiz_rounded;
  static const IconData options = Icons.tune_rounded;

  // Gesture icons
  static const IconData swipeUp = Icons.swipe_up_rounded;
  static const IconData swipeDown = Icons.swipe_down_rounded;
  static const IconData swipeLeft = Icons.swipe_left_rounded;
  static const IconData swipeRight = Icons.swipe_right_rounded;
  static const IconData tap = Icons.touch_app_rounded;

  // Time and duration icons
  static const IconData schedule = Icons.schedule_rounded;
  static const IconData timer = Icons.timer_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData recent = Icons.access_time_rounded;
}

/// Icon sizes for consistent sizing across the app
class OmnisonicIconSizes {
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 40.0;
  static const double xxl = 48.0;
  static const double xxxl = 56.0;

  // Semantic sizes
  static const double tiny = xs;
  static const double small = sm;
  static const double medium = md;
  static const double large = lg;
  static const double extraLarge = xl;
  static const double huge = xxl;
  static const double massive = xxxl;

  // Component-specific sizes
  static const double appBar = md;
  static const double button = sm;
  static const double fab = lg;
  static const double listItem = md;
  static const double card = md;
  static const double playButton = xl;
  static const double nowPlaying = lg;
  static const double navigation = md;
  static const double status = sm;
}

/// Asset paths for custom icons and images
class OmnisonicAssets {
  // Base paths
  static const String _iconsPath = 'assets/icons';
  static const String _imagesPath = 'assets/images';
  static const String _fontsPath = 'assets/fonts';

  // Custom icons (if any)
  static const String logoIcon = '$_iconsPath/omnisonic_logo.svg';
  static const String logoIconPng = '$_iconsPath/omnisonic_logo.png';
  static const String musicNote = '$_iconsPath/music_note.svg';
  static const String waveform = '$_iconsPath/waveform.svg';

  // Placeholder images
  static const String albumPlaceholder = '$_imagesPath/album_placeholder.png';
  static const String artistPlaceholder = '$_imagesPath/artist_placeholder.png';
  static const String playlistPlaceholder =
      '$_imagesPath/playlist_placeholder.png';

  // Background images
  static const String gradientBackground = '$_imagesPath/gradient_bg.png';
  static const String musicBackground = '$_imagesPath/music_bg.png';

  // Font files
  static const String interRegular = '$_fontsPath/Inter-Regular.ttf';
  static const String interMedium = '$_fontsPath/Inter-Medium.ttf';
  static const String interSemiBold = '$_fontsPath/Inter-SemiBold.ttf';
  static const String interBold = '$_fontsPath/Inter-Bold.ttf';

  static const String poppinsRegular = '$_fontsPath/Poppins-Regular.ttf';
  static const String poppinsMedium = '$_fontsPath/Poppins-Medium.ttf';
  static const String poppinsSemiBold = '$_fontsPath/Poppins-SemiBold.ttf';
  static const String poppinsBold = '$_fontsPath/Poppins-Bold.ttf';
}

/// Utility class for creating consistent icon widgets
class OmnisonicIconWidget extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;

  const OmnisonicIconWidget(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size ?? OmnisonicIconSizes.medium,
      color: color ?? Theme.of(context).iconTheme.color,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }

  // Factory constructors for common icon types
  factory OmnisonicIconWidget.play({
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    return OmnisonicIconWidget(
      OmnisonicIcons.play,
      size: size ?? OmnisonicIconSizes.playButton,
      color: color,
      semanticLabel: semanticLabel ?? 'Play',
    );
  }

  factory OmnisonicIconWidget.pause({
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    return OmnisonicIconWidget(
      OmnisonicIcons.pause,
      size: size ?? OmnisonicIconSizes.playButton,
      color: color,
      semanticLabel: semanticLabel ?? 'Pause',
    );
  }

  factory OmnisonicIconWidget.favorite({
    bool filled = false,
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    return OmnisonicIconWidget(
      filled ? OmnisonicIcons.favorite : OmnisonicIcons.favoriteOutline,
      size: size ?? OmnisonicIconSizes.medium,
      color: color,
      semanticLabel:
          semanticLabel ??
          (filled ? 'Remove from favorites' : 'Add to favorites'),
    );
  }

  factory OmnisonicIconWidget.navigation({
    required IconData icon,
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    return OmnisonicIconWidget(
      icon,
      size: size ?? OmnisonicIconSizes.navigation,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}

/// Extension for easy icon access from context
extension OmnisonicIconTheme on ThemeData {
  IconThemeData get omnisonicIconTheme =>
      iconTheme.copyWith(size: OmnisonicIconSizes.medium);

  IconThemeData get playbackIconTheme =>
      iconTheme.copyWith(size: OmnisonicIconSizes.playButton);

  IconThemeData get navigationIconTheme =>
      iconTheme.copyWith(size: OmnisonicIconSizes.navigation);

  IconThemeData get statusIconTheme =>
      iconTheme.copyWith(size: OmnisonicIconSizes.status);
}
