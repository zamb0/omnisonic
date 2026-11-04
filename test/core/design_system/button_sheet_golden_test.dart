import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

void _noop() {}

Widget _row(String name, List<Widget> children) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 86,
        child: Text(name, style: const TextStyle(fontSize: 10)),
      ),
      for (final c in children) ...[c, const SizedBox(width: 10)],
    ],
  ),
);

Widget _sheet(ThemeData theme) => Theme(
  data: theme,
  child: Builder(
    builder: (context) => ColoredBox(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: TextStyle(color: theme.colorScheme.onSurface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Aurora', [
                AuroraButton(
                  label: 'Play',
                  icon: OmnisonicIcons.playArrow,
                  onPressed: _noop,
                  size: OmnisonicButtonSize.sm,
                ),
                AuroraButton(
                  label: 'Play',
                  icon: OmnisonicIcons.playArrow,
                  onPressed: _noop,
                ),
                AuroraButton(
                  label: 'Play',
                  icon: OmnisonicIcons.playArrow,
                  onPressed: _noop,
                  size: OmnisonicButtonSize.lg,
                ),
              ]),
              _row('Aurora st.', [
                const AuroraButton(label: 'Play', onPressed: null),
                AuroraButton(
                  label: 'Play',
                  icon: OmnisonicIcons.playArrow,
                  onPressed: _noop,
                  loading: true,
                ),
              ]),
              _row('Primary', [
                OmnisonicButton(label: 'Save', onPressed: _noop),
                const OmnisonicButton(label: 'Save', onPressed: null),
                OmnisonicButton(label: 'Save', onPressed: _noop, loading: true),
              ]),
              _row('Tonal', [
                OmnisonicButton(
                  label: 'Shuffle',
                  icon: OmnisonicIcons.shuffle,
                  variant: OmnisonicButtonVariant.tonal,
                  onPressed: _noop,
                ),
                const OmnisonicButton(
                  label: 'Shuffle',
                  variant: OmnisonicButtonVariant.tonal,
                  onPressed: null,
                ),
                OmnisonicButton(
                  label: 'Shuffle',
                  variant: OmnisonicButtonVariant.tonal,
                  onPressed: _noop,
                  loading: true,
                ),
              ]),
              _row('Destructive', [
                OmnisonicButton(
                  label: 'Delete',
                  variant: OmnisonicButtonVariant.destructive,
                  onPressed: _noop,
                ),
                const OmnisonicButton(
                  label: 'Delete',
                  variant: OmnisonicButtonVariant.destructive,
                  onPressed: null,
                ),
              ]),
              _row('Outlined/Text', [
                OutlinedButton(onPressed: _noop, child: const Text('Cancel')),
                TextButton(onPressed: _noop, child: const Text('See all')),
              ]),
              _row('PlayDisc', [
                for (final s in PlayDiscSize.values)
                  PlayDisc(onPressed: _noop, size: s),
                PlayDisc(onPressed: _noop, playing: true),
                const PlayDisc(onPressed: null),
              ]),
              _row('IconButton', [
                for (final v in OmnisonicIconButtonVariant.values)
                  OmnisonicIconButton(
                    icon: OmnisonicIcons.playlistAdd,
                    tooltip: v.name,
                    variant: v,
                    onPressed: _noop,
                  ),
                const OmnisonicIconButton(
                  icon: OmnisonicIcons.playlistAdd,
                  tooltip: 'off',
                  onPressed: null,
                ),
              ]),
              _row('Toggle', [
                OmnisonicIconButton(
                  icon: OmnisonicIcons.favoriteOutline,
                  tooltip: 'off',
                  variant: OmnisonicIconButtonVariant.toggle,
                  onPressed: _noop,
                ),
                OmnisonicIconButton(
                  icon: OmnisonicIcons.favoriteOutline,
                  selectedIcon: OmnisonicIcons.favorite,
                  selectedColor: OmnisonicBrand.of(context).heat,
                  tooltip: 'on',
                  variant: OmnisonicIconButtonVariant.toggle,
                  selected: true,
                  onPressed: _noop,
                ),
                OmnisonicIconButton(
                  icon: OmnisonicIcons.shuffle,
                  tooltip: 'on',
                  variant: OmnisonicIconButtonVariant.toggle,
                  selected: true,
                  onPressed: _noop,
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('button sheet, dark and light', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: OmnisonicTheme.lightTheme,
        home: Material(
          child: Row(
            children: [
              Expanded(child: _sheet(OmnisonicTheme.darkTheme)),
              Expanded(child: _sheet(OmnisonicTheme.lightTheme)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Row).first,
      matchesGoldenFile('goldens/button_sheet.png'),
    );
  });
}
