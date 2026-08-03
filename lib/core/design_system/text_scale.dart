import 'package:flutter/material.dart';

/// Helpers for laying out against the user's text size.
///
/// The app had no dynamic-type support at all: every size was a fixed
/// logical pixel value and no code read [MediaQuery.textScalerOf], so at
/// large system text the labels grew and the boxes holding them did not.
class OmnisonicTextScale {
  const OmnisonicTextScale._();

  /// Above this, the shell's own chrome stops growing.
  ///
  /// Content scales without limit — that is the point of the setting. But
  /// nav labels and the transport bar are fixed furniture with no room to
  /// reflow into, and at 2x they would take the screen away from the content
  /// the user enlarged the text to read. Capping the frame and not the
  /// contents is the usual compromise.
  static const double chromeMax = 1.3;

  /// A box whose height is partly artwork and partly text.
  ///
  /// [fixed] is the part that does not care about text size — a square
  /// cover, an avatar. [text] is the label block underneath, which does.
  /// Scaling the whole height instead would grow the artwork too and push
  /// the row off screen.
  static double boxExtent(
    BuildContext context, {
    required double fixed,
    required double text,
  }) => fixed + MediaQuery.textScalerOf(context).scale(text);

  /// A height that is entirely text plus padding.
  static double textExtent(BuildContext context, double base, {double? max}) {
    final scaled = MediaQuery.textScalerOf(context).scale(base);
    return max == null ? scaled : scaled.clamp(base, max);
  }

  /// Caps the text scale for [child] at [maxScale].
  ///
  /// For shell chrome only. Wrapping content in this would defeat the
  /// accessibility setting rather than accommodate it.
  static Widget clampChrome(
    BuildContext context,
    Widget child, {
    double maxScale = chromeMax,
  }) {
    final media = MediaQuery.of(context);
    final current = media.textScaler.scale(1);
    if (current <= maxScale) return child;

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(maxScale)),
      child: child,
    );
  }
}
