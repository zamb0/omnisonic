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

  /// Behind artwork that has not loaded or does not exist.
  final Color placeholder;

  /// The primary action and the "you are here" marker: the filled button,
  /// the selected nav pill. Same as `onSurface`, named for its role.
  final Color ink;

  /// Text and icons on [ink].
  final Color onInk;

  static const OmnisonicSurfaces dark = OmnisonicSurfaces(
    well: Color(0x0FFFFFFF), // white 6%
    wellHover: Color(0x1AFFFFFF), // white 10%
    hairline: Color(0x1AFFFFFF),
    placeholder: Color(0xFF1D1E22),
    ink: Color(0xFFF4F2EF),
    onInk: Color(0xFF0D0E10),
  );

  static const OmnisonicSurfaces light = OmnisonicSurfaces(
    well: Color(0x8CFFFFFF), // white 55%
    wellHover: Color(0xC7FFFFFF), // white 78%
    hairline: Color(0x14000000), // black 8%
    placeholder: Color(0xFFDEDAD4),
    ink: Color(0xFF141414),
    onInk: Color(0xFFEFEDEA),
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
    Color? ink,
    Color? onInk,
  }) => OmnisonicSurfaces(
    well: well ?? this.well,
    wellHover: wellHover ?? this.wellHover,
    hairline: hairline ?? this.hairline,
    placeholder: placeholder ?? this.placeholder,
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
      ink: Color.lerp(ink, other.ink, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
    );
  }
}
