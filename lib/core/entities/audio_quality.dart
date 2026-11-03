enum AudioQuality {
  low(bitrate: 128, format: 'MP3'),
  medium(bitrate: 192, format: 'MP3'),
  high(bitrate: 320, format: 'MP3'),
  lossless(bitrate: 1411, format: 'FLAC'),
  ultra(bitrate: 2822, format: 'FLAC');

  const AudioQuality({required this.bitrate, required this.format});

  final int bitrate;
  final String format;

  /// Returns true if this quality is better than the other
  bool isBetterThan(AudioQuality other) {
    return bitrate > other.bitrate;
  }

  /// Returns the quality level as a numeric score for comparison
  int get qualityScore {
    switch (this) {
      case AudioQuality.low:
        return 1;
      case AudioQuality.medium:
        return 2;
      case AudioQuality.high:
        return 3;
      case AudioQuality.lossless:
        return 4;
      case AudioQuality.ultra:
        return 5;
    }
  }

  /// A label for the UI. Deliberately without a bitrate: [bitrate] is the
  /// tier's nominal rate, not what the file or stream actually has, and
  /// showing "1411kbps" for every FLAC presented an invented number as fact.
  String get displayName => switch (this) {
    AudioQuality.low => 'MP3 · Low',
    AudioQuality.medium => 'MP3 · Standard',
    AudioQuality.high => 'MP3 · High',
    AudioQuality.lossless => 'FLAC · Lossless',
    AudioQuality.ultra => 'FLAC · Hi-Res',
  };

  @override
  String toString() => '$format ${bitrate}kbps';
}
