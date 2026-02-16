import '../../../core/entities/entities.dart';

final _timeExp = RegExp(r'\[(\d{2,}):(\d{2})(?:\.(\d{2,3}))?\]');

List<LyricLine> parseLrc(String input) {
  final lines = <LyricLine>[];
  final rawLines = input.split('\n');

  for (final rawLine in rawLines) {
    final matches = _timeExp.allMatches(rawLine).toList();
    if (matches.isEmpty) {
      continue;
    }

    final text = rawLine.replaceAll(_timeExp, '').trim();
    if (text.isEmpty) {
      continue;
    }

    for (final match in matches) {
      final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
      final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
      final millisRaw = match.group(3);
      final millis = millisRaw == null
          ? 0
          : millisRaw.length == 3
              ? int.tryParse(millisRaw) ?? 0
              : (int.tryParse(millisRaw) ?? 0) * 10;

      final totalMs = (minutes * 60 + seconds) * 1000 + millis;
      lines.add(LyricLine(time: Duration(milliseconds: totalMs), text: text));
    }
  }

  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}
