import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/servers/presentation/widgets/server_add_dialog.dart';

import '../../helpers/widget_harness.dart';

/// Without hints the system password manager ignores the one form in the app
/// that asks for a URL, a username and a password.
void main() {
  testWidgets('credential fields declare autofill hints in one group', (
    tester,
  ) async {
    await pumpPage(tester, const ServerAddDialog(), settle: false);
    await tester.pump();

    List<String>? hintsOf(String label) => tester
        .widget<TextField>(find.widgetWithText(TextField, label))
        .autofillHints
        ?.toList();

    expect(hintsOf('Server URL *'), [AutofillHints.url]);
    expect(hintsOf('Username *'), [AutofillHints.username]);
    expect(hintsOf('Password *'), [AutofillHints.password]);
    expect(find.byType(AutofillGroup), findsOneWidget);
  });
}
