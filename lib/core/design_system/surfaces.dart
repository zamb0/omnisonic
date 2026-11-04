import 'package:flutter/material.dart';

/// The fills and lines that live *inside* the glass, which [ColorScheme] has
/// no names for.
///
/// Stat tiles, server rows, the library health card, inputs and chips each
/// picked their own wash — `glassFill`, `onSurface` at 5%, 9%, or
/// `surfaceContainerHighest` (which, before the scheme spelled its container
/// ladder out, was the canvas itself). One recessed fill, one hover step and
/// one hairline replace them. Read with `OmnisonicSurfaces.of(context)`.
@immutable
class OmnisonicSurfaces extends ThemeExtension<OmnisonicSurfaces> {
  const OmnisonicSurfaces({
    required this.well,
    required this.wellHover,
    required this.hairline,
    required this.placeholder,
    required this.placeholderEnd,
    required this.ink,
    required this.onInk,
  });

  /// A recessed fill inside a glass pane: inputs, stat tiles, server rows,
  /// chips, tonal buttons.
  final Color well;

  /// [well] under the pointer or selected.
  final Color wellHover;

  /// Dividers and the 1px edge of wells and overlays.
  final Color hairline;

  /// Behind artwork that has not loaded or does not exist (gradient start).
  final Color placeholder;

  /// Gradient end of the artwork placeholder.
  final Color placeholderEnd;

  /// Artwork placeholder: a diagonal gradient whose hue follows [seed]
  /// (typically the album id), so covers without art are distinguishable.
  LinearGradient placeholderGradient([String? seed]) {
    final tint = seed == null ? null : _seedHue(seed);
    Color mix(Color c) => tint == null ? c : Color.lerp(c, tint, 0.18)!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [mix(placeholder), mix(placeholderEnd)],
    );
  }

  static Color _seedHue(String seed) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.7, 0.55).toColor();
  }

  /// The primary action and the "you are here" marker: the filled button,
  /// the selected nav pill. Same as `onSurface`, named for its role.
  final Color ink;

  /// Text and icons on [ink].
  final Color onInk;

  static const OmnisonicSurfaces dark = OmnisonicSurfaces(
    well: Color(0x0FFFFFFF), // white 6%
    wellHover: Color(0x1AFFFFFF), // white 10%
    hairline: Color(0x1AFFFFFF),
    placeholder: Color(0xFF1C1A29),
    placeholderEnd: Color(0xFF262338),
    ink: Color(0xFFF3F1F8),
    onInk: Color(0xFF0B0A12),
  );

  static const OmnisonicSurfaces light = OmnisonicSurfaces(
    well: Color(0x0D2A1F5C), // #2A1F5C 5%
    wellHover: Color(0x172A1F5C), // #2A1F5C 9%
    hairline: Color(0x1A2A1F5C), // #2A1F5C 10%
    placeholder: Color(0xFFE9E5F1),
    placeholderEnd: Color(0xFFDED8EA),
    ink: Color(0xFF17141F),
    onInk: Color(0xFFF6F4FA),
  );

  static OmnisonicSurfaces of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<OmnisonicSurfaces>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  OmnisonicSurfaces copyWith({
    Color? well,
    Color? wellHover,
    Color? hairline,
    Color? placeholder,
    Color? placeholderEnd,
    Color? ink,
    Color? onInk,
  }) => OmnisonicSurfaces(
    well: well ?? this.well,
    wellHover: wellHover ?? this.wellHover,
    hairline: hairline ?? this.hairline,
    placeholder: placeholder ?? this.placeholder,
    placeholderEnd: placeholderEnd ?? this.placeholderEnd,
    ink: ink ?? this.ink,
    onInk: onInk ?? this.onInk,
  );

  @override
  OmnisonicSurfaces lerp(ThemeExtension<OmnisonicSurfaces>? other, double t) {
    if (other is! OmnisonicSurfaces) return this;
    return OmnisonicSurfaces(
      well: Color.lerp(well, other.well, t)!,
      wellHover: Color.lerp(wellHover, other.wellHover, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
      placeholderEnd: Color.lerp(placeholderEnd, other.placeholderEnd, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
    );
  }
}
