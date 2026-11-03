import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/errors/errors.dart';

void main() {
  test('never shows the technical message for server failures', () {
    final text = describeFailure(
      const ServerFailure('SocketException: Connection refused (errno 111)'),
      action: 'delete the playlist',
    );
    expect(text, startsWith("Couldn't delete the playlist"));
    expect(text, isNot(contains('SocketException')));
  });

  test('passes validation messages through', () {
    expect(
      describeFailure(
        const ValidationFailure('Name is required'),
        action: 'save',
      ),
      "Couldn't save: Name is required",
    );
  });
}
