import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/widget_harness.dart';

/// A page that uses the header-collapse pieces the way the detail pages do.
class _Page extends StatefulWidget {
  const _Page({this.horizontal = false});
  final bool horizontal;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with HeaderCollapseMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: onHeaderScroll,
        child: CustomScrollView(
          scrollDirection: widget.horizontal ? Axis.horizontal : Axis.vertical,
          slivers: [
            if (!widget.horizontal)
              collapsingAppBar(
                context,
                collapsed: headerCollapsed,
                title: 'Kind of Blue',
                leading: const BackButton(),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                width: widget.horizontal ? 5000 : null,
                height: widget.horizontal ? null : 3000,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('collapse', () {
    double titleOpacity(WidgetTester t) => t
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.text('Kind of Blue'),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;
    double glassOpacity(WidgetTester t) => t
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.byType(GlassSurface),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;

    testWidgets(
      'the compact title and the glass come in once the header is gone',
      (t) async {
        await pumpPage(t, const _Page(), settle: false);
        await t.pump();
        expect(titleOpacity(t), 0);
        expect(glassOpacity(t), 0);

        await t.drag(find.byType(CustomScrollView), const Offset(0, -100));
        await t.pump();
        expect(titleOpacity(t), 0, reason: 'still under the threshold');

        await t.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await t.pump();
        expect(titleOpacity(t), 1);
        expect(glassOpacity(t), 1);

        await t.drag(find.byType(CustomScrollView), const Offset(0, 1000));
        await t.pump();
        expect(
          titleOpacity(t),
          0,
          reason: 'back at the top, the bar is bare again',
        );
      },
    );

    testWidgets('the app bar stays transparent: the glass is the backdrop', (
      t,
    ) async {
      await pumpPage(t, const _Page(), settle: false);
      await t.pump();
      final bar = t.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, Colors.transparent);
    });

    testWidgets('a sideways scroll does not collapse it', (t) async {
      await pumpPage(t, const _Page(horizontal: true), settle: false);
      await t.drag(find.byType(CustomScrollView), const Offset(-1000, 0));
      await t.pump();
      expect(find.byType(AppBar), findsNothing);
    });
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets(
      'golden: album and artist headers on a dark and a light cover (${mode.name})',
      (t) async {
        Widget header({
          required String title,
          required Color cover,
          bool artist = false,
          String eyebrow = 'Album · 2024',
        }) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DetailHeader(
            eyebrow: artist ? 'Artist' : eyebrow,
            title: title,
            tint: cover,
            circularArtwork: artist,
            forceNarrow: true,
            artworkSize: 160,
            artwork: ClipRRect(
              borderRadius: BorderRadius.circular(
                artist ? 999 : OmnisonicRadius.artHero,
              ),
              child: ColoredBox(color: cover),
            ),
            chips: const [MetadataChip(icon: Icons.album, label: '12 tracks')],
            actions: [
              AuroraButton(
                label: 'Play',
                icon: Icons.play_arrow,
                onPressed: () {},
              ),
              OmnisonicButton(
                label: 'Shuffle',
                variant: OmnisonicButtonVariant.tonal,
                onPressed: () {},
              ),
            ],
          ),
        );
        await pumpPage(
          t,
          Builder(
            builder: (context) => ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Material(
                type: MaterialType.transparency,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      header(
                        title: 'Kind of Blue',
                        cover: const Color(0xFF1B2A55),
                      ),
                      header(
                        title: 'Cream Soda',
                        cover: const Color(0xFFF2E6C9),
                        eyebrow: 'Album · 1998',
                      ),
                      header(
                        title: 'Miles Davis',
                        cover: const Color(0xFF8A3B2E),
                        artist: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          size: const Size(400, 1100),
          themeMode: mode,
          settle: false,
          disableAnimations: true,
        );
        await t.pump();
        await expectLater(
          find.byType(SingleChildScrollView),
          matchesGoldenFile('goldens/detail_headers_${mode.name}.png'),
        );
      },
    );
  }
}
