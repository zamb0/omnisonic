import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/utils/formatters.dart';

void main() {
  group('formatDuration', () {
    test('minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 3, seconds: 7)), '3:07');
      expect(formatDuration(Duration.zero), '0:00');
    });

    test('carries hours instead of reading 75:00', () {
      expect(formatDuration(const Duration(minutes: 75)), '1:15:00');
      expect(
        formatDuration(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '2:03:04',
      );
    });

    test('unknown for null or negative', () {
      expect(formatDuration(null), '--:--');
      expect(formatDuration(const Duration(seconds: -1)), '--:--');
    });
  });

  test('formatTotalDuration', () {
    expect(formatTotalDuration(const Duration(minutes: 42)), '42 min');
    expect(formatTotalDuration(const Duration(minutes: 72)), '1 h 12 min');
    expect(formatTotalDuration(const Duration(hours: 2)), '2 h');
  });

  test('formatRelativeTime', () {
    final now = DateTime(2026, 5, 20, 12);
    expect(formatRelativeTime(now, now: now), 'Just now');
    expect(
      formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now),
      '5m ago',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 2)), now: now),
      '2d ago',
    );
    expect(formatRelativeTime(DateTime(2026, 1, 3), now: now), '3/1/2026');
  });

  test('pluralize', () {
    expect(pluralize(1, 'playlist'), '1 playlist');
    expect(pluralize(3, 'playlist'), '3 playlists');
    expect(pluralize(0, 'entry', plural: 'entries'), '0 entries');
  });
}
