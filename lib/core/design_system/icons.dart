import 'package:flutter/material.dart';

/// Every icon the app draws, named once.
///
/// Call sites used to reach for `Icons.*` directly — 386 of them across 31
/// files, mixing the filled, outlined, sharp and rounded families for the
/// same concept, so a refresh glyph had square corners in one screen and
/// round ones in the next.
///
/// The rounded family is the app's: it pairs with `OmnisonicRadius.full`
/// and `.pill`, which the glass chrome is built from. Where a concept has an
/// inactive state as well, the `*Outline` member is that state — Material
/// has no rounded outline variants, so those stay in the outlined family,
/// which is the same pairing Material's own navigation components use.
class OmnisonicIcons {
  const OmnisonicIcons._();

  // --------------------------------------------------------------------
  // Playback transport
  //
  // Rounded throughout: these sit next to the pill-shaped
  // controls and full-radius buttons the redesign is built on.
  // --------------------------------------------------------------------

  static const IconData playArrow = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData skipNext = Icons.skip_next_rounded;
  static const IconData skipPrevious = Icons.skip_previous_rounded;
  static const IconData shuffle = Icons.shuffle_rounded;
  static const IconData repeat = Icons.repeat_rounded;
  static const IconData repeatOne = Icons.repeat_one_rounded;
  static const IconData repeatOn = Icons.repeat_on_rounded;
  static const IconData repeatOneOn = Icons.repeat_one_on_rounded;
  static const IconData shuffleOn = Icons.shuffle_on_rounded;
  static const IconData volumeUp = Icons.volume_up_rounded;
  static const IconData volumeDown = Icons.volume_down_rounded;
  static const IconData volumeOff = Icons.volume_off_rounded;
  static const IconData graphicEq = Icons.graphic_eq_rounded;
  static const IconData accessTime = Icons.access_time_rounded;
  static const IconData speedOutline = Icons.speed_outlined;
  static const IconData touchApp = Icons.touch_app_rounded;
  static const IconData monitorHeart = Icons.monitor_heart_rounded;

  // --------------------------------------------------------------------
  // Library and content
  // --------------------------------------------------------------------

  static const IconData musicNote = Icons.music_note_rounded;
  static const IconData musicNoteOutline = Icons.music_note_outlined;
  static const IconData album = Icons.album_rounded;
  static const IconData albumOutline = Icons.album_outlined;
  static const IconData person = Icons.person_rounded;
  static const IconData personOutline = Icons.person_outline;
  static const IconData libraryMusic = Icons.library_music_rounded;
  static const IconData libraryMusicOutline = Icons.library_music_outlined;
  static const IconData queueMusic = Icons.queue_music_rounded;
  static const IconData lyrics = Icons.lyrics_rounded;
  static const IconData queueMusicOutline = Icons.queue_music_outlined;
  static const IconData playlistPlay = Icons.playlist_play_rounded;
  static const IconData playlistAdd = Icons.playlist_add_rounded;
  static const IconData playNext = Icons.queue_play_next_rounded;
  static const IconData addToQueue = Icons.add_to_queue_rounded;
  static const IconData playlistRemove = Icons.playlist_remove_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutline = Icons.star_outline;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteOutline = Icons.favorite_border;
  static const IconData textSnippetOutline = Icons.text_snippet_outlined;
  static const IconData calendarToday = Icons.calendar_today_rounded;

  // --------------------------------------------------------------------
  // Navigation and structure
  //
  // The `*Outline` members are the inactive halves of nav pairs; the solid
  // member of each pair marks the current destination.
  // --------------------------------------------------------------------

  static const IconData home = Icons.home_rounded;
  static const IconData homeOutline = Icons.home_outlined;
  static const IconData search = Icons.search_rounded;
  static const IconData searchOutline = Icons.search_outlined;
  static const IconData searchOff = Icons.search_off_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData settingsOutline = Icons.settings_outlined;
  static const IconData dns = Icons.dns_rounded;
  static const IconData dnsOutline = Icons.dns_outlined;
  static const IconData lan = Icons.lan_rounded;
  static const IconData arrowBack = Icons.arrow_back_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData keyboardArrowDown = Icons.keyboard_arrow_down_rounded;
  static const IconData moreVert = Icons.more_vert_rounded;
  static const IconData openInFull = Icons.open_in_full_rounded;
  static const IconData exploreOff = Icons.explore_off_rounded;

  // --------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------

  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData clear = Icons.clear_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData copy = Icons.copy_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData downloadOutline = Icons.download_outlined;
  static const IconData downloadDone = Icons.download_done_rounded;
  static const IconData downloading = Icons.downloading_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData sync = Icons.sync_rounded;
  static const IconData syncOutline = Icons.sync_outlined;
  static const IconData syncAlt = Icons.sync_alt_rounded;
  static const IconData reorder = Icons.reorder_rounded;
  static const IconData image = Icons.image_outlined;
  static const IconData description = Icons.description_outlined;
  static const IconData arrowUpward = Icons.arrow_upward_rounded;
  static const IconData arrowDownward = Icons.arrow_downward_rounded;
  static const IconData dragHandle = Icons.drag_handle_rounded;
  static const IconData filterList = Icons.filter_list_rounded;
  static const IconData filterAltOff = Icons.filter_alt_off_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData sortByAlpha = Icons.sort_by_alpha_rounded;
  static const IconData visibility = Icons.visibility_rounded;
  static const IconData visibilityOff = Icons.visibility_off_rounded;
  static const IconData lock = Icons.lock_rounded;
  static const IconData fingerprint = Icons.fingerprint_rounded;
  static const IconData public = Icons.public_rounded;

  // --------------------------------------------------------------------
  // Status and feedback
  // --------------------------------------------------------------------

  static const IconData error = Icons.error_rounded;
  static const IconData errorOutline = Icons.error_outline;
  static const IconData warning = Icons.warning_rounded;
  static const IconData warningAmber = Icons.warning_amber_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData infoOutline = Icons.info_outline;
  static const IconData history = Icons.history_rounded;
  static const IconData circleOutline = Icons.circle_outlined;
  static const IconData offlinePin = Icons.offline_pin_rounded;
  static const IconData cloudDone = Icons.cloud_done_rounded;
  static const IconData cloudOff = Icons.cloud_off_rounded;
  static const IconData healthAndSafetyOutline =
      Icons.health_and_safety_outlined;
  static const IconData analytics = Icons.analytics_rounded;
  static const IconData lightbulbOutline = Icons.lightbulb_outline;
  static const IconData darkMode = Icons.dark_mode_rounded;
  static const IconData lightMode = Icons.light_mode_rounded;
  static const IconData brightnessAuto = Icons.brightness_auto_rounded;

  // --------------------------------------------------------------------
  // Connectivity
  // --------------------------------------------------------------------

  static const IconData wifi = Icons.wifi_rounded;
  static const IconData wifiProtectedSetup = Icons.wifi_protected_setup_rounded;
  static const IconData networkCell = Icons.network_cell_rounded;
  static const IconData networkWifi1Bar = Icons.network_wifi_1_bar_rounded;
  static const IconData networkWifi2Bar = Icons.network_wifi_2_bar_rounded;
  static const IconData signalCellular4Bar =
      Icons.signal_cellular_4_bar_rounded;
  static const IconData signalCellularOff = Icons.signal_cellular_off_rounded;
}

/// Icon sizes, as a ladder rather than as literals at the call site.
///
/// Feature code carried around sixty bare `size:` numbers — 10, 12, 14, 15,
/// 16, 18, 20, 22, 24, 36, 72, 80 — which is not a scale, it is a scatter.
/// The in-between rungs ([inline], [smd]) exist because real UI needed them,
/// not for symmetry.
class OmnisonicIconSizes {
  const OmnisonicIconSizes._();

  /// Status dots and source markers, where the glyph reads as a bullet.
  static const double nano = 8.0;

  /// Dense metadata: quality badges, server chips.
  static const double xs = 12.0;

  /// Beside caption-sized text, where [sm] would out-weigh the words.
  static const double inline = 14.0;

  /// Inline with body text; the brand mark in the collapsed rail.
  static const double sm = 16.0;

  /// Secondary controls that must not compete with the primary one beside
  /// them; the icon inside a search field.
  static const double smd = 20.0;

  /// The default. App bars, list items, nav, card actions.
  static const double md = 24.0;

  /// Emphasised affordances inside a panel.
  static const double lg = 32.0;

  /// The player's primary transport control.
  static const double xl = 40.0;

  /// Empty-state and placeholder glyphs.
  static const double xxl = 48.0;

  /// The largest an icon gets: full-page empty states and cover-art
  /// placeholders.
  static const double xxxl = 64.0;
}
