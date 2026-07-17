import 'package:equatable/equatable.dart';

enum LyricsSource { lrclib, lyricsOvh }

enum LyricsType { synced, unsynced }

class LyricLine extends Equatable {
  const LyricLine({required this.time, required this.text});

  final Duration time;
  final String text;

  @override
  List<Object?> get props => [time, text];
}

class LyricsData extends Equatable {
  const LyricsData({
    required this.title,
    required this.artist,
    required this.source,
    required this.type,
    required this.raw,
    required this.fetchedAt,
    this.providerId,
    this.offsetMs,
  });

  final String title;
  final String artist;
  final LyricsSource source;
  final LyricsType type;
  final String raw;
  final String? providerId;
  final int? offsetMs;
  final DateTime fetchedAt;

  bool get isSynced => type == LyricsType.synced;

  @override
  List<Object?> get props => [
    title,
    artist,
    source,
    type,
    raw,
    providerId,
    offsetMs,
    fetchedAt,
  ];

  LyricsData copyWith({
    String? title,
    String? artist,
    LyricsSource? source,
    LyricsType? type,
    String? raw,
    String? providerId,
    int? offsetMs,
    DateTime? fetchedAt,
  }) {
    return LyricsData(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      source: source ?? this.source,
      type: type ?? this.type,
      raw: raw ?? this.raw,
      providerId: providerId ?? this.providerId,
      offsetMs: offsetMs ?? this.offsetMs,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class LyricsSearchResult extends Equatable {
  const LyricsSearchResult({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    required this.isSynced,
  });

  final String id;
  final String title;
  final String artist;
  final LyricsSource source;
  final bool isSynced;

  @override
  List<Object?> get props => [id, title, artist, source, isSynced];
}

class LyricsOverride extends Equatable {
  const LyricsOverride({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    required this.isSynced,
  });

  final String id;
  final String title;
  final String artist;
  final LyricsSource source;
  final bool isSynced;

  @override
  List<Object?> get props => [id, title, artist, source, isSynced];
}
