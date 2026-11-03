import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/features/servers/presentation/widgets/server_form_dialog.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/view_model_fakes.dart';
import '../../helpers/widget_harness.dart';

/// #58: one form for adding and editing a server.
void main() {
  Future<_RecordingServers> pumpForm(
    WidgetTester tester, {
    MusicServer? server,
  }) async {
    final servers = _RecordingServers();
    await pumpPage(
      tester,
      Scaffold(body: ServerFormDialog(server: server)),
      viewModels: TestViewModels(servers: servers),
      settle: false,
    );
    await tester.pump();
    return servers;
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  testWidgets('credential fields declare autofill hints in one group', (
    tester,
  ) async {
    await pumpForm(tester);

    List<String>? hintsOf(String label) =>
        tester.widget<TextField>(field(label)).autofillHints?.toList();

    expect(hintsOf('Server URL'), [AutofillHints.url]);
    expect(hintsOf('Username'), [AutofillHints.username]);
    expect(hintsOf('Password'), [AutofillHints.password]);
    expect(find.byType(AutofillGroup), findsOneWidget);
  });

  testWidgets('a bare host is accepted and normalised on submit', (
    tester,
  ) async {
    final servers = await pumpForm(tester);

    await tester.enterText(field('Server URL'), 'music.example.com/rest/');
    await tester.enterText(field('Username'), 'ada');
    await tester.enterText(field('Password'), 'secret');
    await tester.pump();
    expect(find.text('Enter the server URL'), findsNothing);

    // Enter on the password field submits.
    await tester.showKeyboard(field('Password'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(servers.added.single.url, 'https://music.example.com');
    expect(servers.added.single.username, 'ada');
  });

  testWidgets('validates as the user types, not only on submit', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.enterText(field('Username'), 'x');
    await tester.enterText(field('Username'), '');
    await tester.pump();
    expect(find.text('Enter your username'), findsOneWidget);
  });

  testWidgets('typing in one field flags no other field (#71)', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.enterText(field('Username'), 'ada');
    await tester.enterText(field('Username'), '');
    await tester.pump();

    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter the server URL'), findsNothing);
    expect(find.text('Enter your password'), findsNothing);
  });

  testWidgets('submitting still flags every empty field (#71)', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.showKeyboard(field('Password'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Enter the server URL'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('editing offers a password change and keeps it optional', (
    tester,
  ) async {
    final servers = await pumpForm(tester, server: testServer(name: 'Attic'));

    expect(field('New password'), findsOneWidget);
    expect(
      find.text('Leave empty to keep the current password'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(servers.updated.single.$2, isNull);
  });
}

class _RecordingServers extends FakeServerManagementViewModel {
  final added = <({String url, String username})>[];
  final updated = <(MusicServer, String?)>[];

  @override
  Future<bool> addServer({
    required String name,
    required String url,
    required String username,
    required String password,
  }) async {
    added.add((url: url, username: username));
    return true;
  }

  @override
  Future<bool> updateServer(MusicServer server, {String? newPassword}) async {
    updated.add((server, newPassword));
    return true;
  }
}
