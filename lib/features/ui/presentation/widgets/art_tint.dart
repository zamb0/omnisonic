import 'package:flutter/widgets.dart';

import '../../../../core/services/cover_palette_service.dart';

/// The dominant colour of a cover, extracted off the build path.
///
/// The same follow-the-current-cover logic was written out in the shell's
/// background, the now-playing bar and the full-screen player. Call
/// [updateArtTint] with the cover to follow (from `build` is fine — it is a
/// no-op for the same URL and applies the result in a later frame); read
/// [artTint], null until extraction finishes or when it fails.
mixin ArtTintMixin<T extends StatefulWidget> on State<T> {
  Color? _artTint;
  String? _artTintUrl;

  Color? get artTint => _artTint;

  /// The cover [artTint] follows (or is being extracted from).
  String? get artTintUrl => _artTintUrl;

  void updateArtTint(String? coverArtUrl) {
    if (coverArtUrl == _artTintUrl) return;
    _artTintUrl = coverArtUrl;
    CoverPaletteService.instance.extractColor(coverArtUrl).then((color) {
      // A newer cover may have been asked for while this one was decoding.
      if (mounted && _artTintUrl == coverArtUrl && color != _artTint) {
        setState(() => _artTint = color);
      }
    });
  }
}
