import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/utils/server_validator.dart';
import '../../../ui/presentation/widgets/chips.dart';
import '../../../ui/presentation/widgets/dialogs.dart';
import '../../../ui/presentation/widgets/feedback.dart';
import '../viewmodels/server_management_view_model.dart';

/// Adds a server, or edits [server] when given.
///
/// Replaces `ServerAddDialog` and `ServerEditDialog`, which duplicated the
/// fields, validators and banners and drifted apart:
///
/// - Editing can change the password (leave it empty to keep the current
///   one), and a changed URL, username or password is tested before saving.
/// - The URL is normalised: `music.example.com/rest/` becomes
///   `https://music.example.com`.
/// - Enter on the password field submits; each field validates once the
///   user has typed in it (or on submit); autofill hints are set in both
///   modes.
/// - A test result is cleared as soon as a field changes, so "Connection
///   successful" never describes values that are no longer there. Testing
///   does not need the name.
/// - Failures are shown in the dialog, not in a snackbar behind its barrier.
Future<void> showServerFormDialog(BuildContext context, {MusicServer? server}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ServerFormDialog(server: server),
  );
}

class ServerFormDialog extends StatefulWidget {
  const ServerFormDialog({super.key, this.server});

  /// The server to edit, or null to add one.
  final MusicServer? server;

  @override
  State<ServerFormDialog> createState() => _ServerFormDialogState();
}

class _ServerFormDialogState extends State<ServerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlKey = GlobalKey<FormFieldState<String>>();
  final _usernameKey = GlobalKey<FormFieldState<String>>();
  final _passwordKey = GlobalKey<FormFieldState<String>>();

  late final _name = TextEditingController(text: widget.server?.name ?? '');
  late final _url = TextEditingController(text: widget.server?.url ?? '');
  late final _username = TextEditingController(
    text: widget.server?.username ?? '',
  );
  final _password = TextEditingController();

  bool _obscure = true;
  bool _testing = false;
  bool _saving = false;

  /// Outcome of the last test or save, shown as a banner.
  ({bool ok, String message})? _result;

  bool get _editing => widget.server != null;

  /// Whether there is more form below the visible part, which draws a
  /// divider above the actions; without it the cut-off helper text looked
  /// like a glitch.
  bool _moreBelow = false;

  bool _onScrollMetrics(ScrollMetrics metrics) {
    final moreBelow = metrics.extentAfter > 0;
    if (moreBelow != _moreBelow) setState(() => _moreBelow = moreBelow);
    return false;
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_url, _username, _password]) {
      c.addListener(_invalidateResult);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _url, _username, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _invalidateResult() {
    if (_result != null && !_saving && !_testing) {
      setState(() => _result = null);
    }
  }

  String get _normalizedUrl => ServerValidator.normalizeUrl(_url.text);

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter the server URL';
    return ServerValidator.validateUrl(
      ServerValidator.normalizeUrl(value),
    ).fold((failure) => failure.message, (_) => null);
  }

  Future<void> _test() async {
    // Only the fields a connection needs; the name is not one of them.
    final password = _password.text;
    final valid = [
      _urlKey,
      _usernameKey,
      if (!_editing || password.isNotEmpty) _passwordKey,
    ].map((k) => k.currentState?.validate() ?? false).every((v) => v);
    if (!valid) return;
    if (_editing && password.isEmpty) {
      setState(
        () => _result = (
          ok: false,
          message: 'Enter the password to test the connection.',
        ),
      );
      return;
    }

    setState(() {
      _testing = true;
      _result = null;
    });
    final viewModel = context.read<ServerManagementViewModel>();
    final connection = await viewModel.testConnectionWithCredentials(
      url: _normalizedUrl,
      username: _username.text.trim(),
      password: password,
    );
    if (!mounted) return;
    final error = viewModel.actionError;
    viewModel.clearActionError();
    final info = connection?.serverInfo;
    final name = info?.serverName;
    // "0.64.2 (10114574)": the build number in parentheses is noise here.
    final version = info?.version.split(' ').first;
    final hasVersion = version != null && version != 'Unknown';
    setState(() {
      _testing = false;
      _result = connection != null
          ? (
              ok: true,
              message: [
                'Connected',
                ?name,
                if (hasVersion) 'version $version',
              ].join(' · '),
            )
          : (ok: false, message: error ?? "Couldn't connect to the server.");
    });
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    final viewModel = context.read<ServerManagementViewModel>();
    final name = _name.text.trim();
    final url = _normalizedUrl;
    final username = _username.text.trim();
    final password = _password.text;
    _url.text = url;

    setState(() {
      _saving = true;
      _result = null;
    });

    final existing = widget.server;
    final ok = existing != null
        ? await viewModel.updateServer(
            existing.copyWith(
              name: name.isEmpty ? existing.name : name,
              url: url,
              username: username,
            ),
            newPassword: password.isEmpty ? null : password,
          )
        : await viewModel.addServer(
            name: name,
            url: url,
            username: username,
            password: password,
          );
    if (!mounted) return;

    if (ok) {
      // Commits the autofill context: the moment the platform offers to
      // save credentials that just worked.
      TextInput.finishAutofillContext();
      Navigator.of(context).pop();
      showFeedback(
        context,
        existing != null
            ? 'Saved "${name.isEmpty ? existing.name : name}"'
            : 'Added "${name.isEmpty ? ServerManagementViewModel.defaultServerName(url) : name}" '
                  '— syncing your library',
        kind: FeedbackKind.success,
      );
      return;
    }
    final error = viewModel.actionError;
    viewModel.clearActionError();
    setState(() {
      _saving = false;
      _result = (
        ok: false,
        message: error ?? "Couldn't save the server. Try again.",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _testing;
    final result = _result;

    return AlertDialog(
      title: Text(_editing ? 'Edit server' : 'Add server'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: kDialogMaxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (n) => _onScrollMetrics(n.metrics),
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (n) => _onScrollMetrics(n.metrics),
                  child: SingleChildScrollView(child: _buildForm(busy, result)),
                ),
              ),
            ),
            if (_moreBelow) const Divider(height: 1),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_editing ? 'Save' : 'Add server'),
        ),
      ],
    );
  }

  Widget _buildForm(bool busy, ({bool ok, String message})? result) {
    return Form(
      key: _formKey,
      // URL, username and password as one credential, for password
      // managers.
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Per field, not on the Form: form-level validation flagged
            // every empty field as soon as one was typed in.
            TextFormField(
              key: _urlKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: _url,
              autofocus: !_editing,
              enabled: !busy,
              keyboardType: TextInputType.url,
              autocorrect: false,
              autofillHints: const [AutofillHints.url],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'music.example.com',
                helperText: 'https:// is added if you leave it out',
              ),
              validator: _validateUrl,
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            TextFormField(
              key: _usernameKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: _username,
              enabled: !busy,
              autocorrect: false,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Enter your username'
                  : null,
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            TextFormField(
              key: _passwordKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: _password,
              enabled: !busy,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: [
                _editing ? AutofillHints.newPassword : AutofillHints.password,
              ],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: _editing ? 'New password' : 'Password',
                helperText: _editing
                    ? 'Leave empty to keep the current password'
                    : null,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure
                        ? OmnisonicIcons.visibility
                        : OmnisonicIcons.visibilityOff,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) => !_editing && (value?.isEmpty ?? true)
                  ? 'Enter your password'
                  : null,
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            TextFormField(
              controller: _name,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                hintText: 'Living room',
                helperText: 'Shown next to tracks from this server',
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            OutlinedButton.icon(
              onPressed: busy ? null : _test,
              icon: _testing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(OmnisonicIcons.wifiProtectedSetup),
              label: Text(_testing ? 'Testing…' : 'Test connection'),
            ),
            // Under the button that produced it. At the top of the form
            // it pushed every field down by ~75pt.
            if (result != null) ...[
              const SizedBox(height: OmnisonicSpacing.sm),
              InlineBanner(
                kind: result.ok ? BannerKind.success : BannerKind.error,
                message: result.message,
              ),
            ],
            if (!_editing) ...[
              const SizedBox(height: OmnisonicSpacing.md),
              const InlineBanner(
                title: 'Using Navidrome?',
                message:
                    'Use your Navidrome username and password, and make '
                    'sure the Subsonic API is enabled in its settings.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
