import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/di/injection_container.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/features/music/presentation/bloc/search_bloc.dart';
import 'package:omnisonic/features/ui/presentation/pages/search_page.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/bloc_fakes.dart';
import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

const _titles = [
  'Paranoid Android',
  'Life on Mars',
  'Blue Monday',
  'Teardrop',
  'Motion Picture Soundtrack',
  'Windowlicker',
  'Cliffs of Dover',
  'Hyperballad',
  'Idioteque',
  'Weightless',
  'Everything in Its Right Place',
  'Nightcall',
];

/// Counts how often the page asks the dedup engine to do real work.
///
/// The merge passes are memoized on the identity of the list they came from,
/// which is the only thing keeping a chip tap or a "See All" from re-running
/// an O(n log n) dedup over the whole result set. Nothing tested that, and
/// the sliver rewrite moved every line around it.
class CountingDeduplicationEngine extends DeduplicationEngine {
  int detectCalls = 0;

  @override
  Map<String, List<Track>> detectDuplicates(List<Track> tracks) {
    detectCalls++;
    return super.detectDuplicates(tracks);
  }
}

void main() {
  late CountingDeduplicationEngine engine;
  FakeSearchBloc? bloc;

  setUp(() {
    engine = CountingDeduplicationEngine();
    if (getIt.isRegistered<DeduplicationEngine>()) {
      getIt.unregister<DeduplicationEngine>();
    }
    getIt.registerSingleton<DeduplicationEngine>(engine);
  });

  tearDown(() {
    bloc?.close();
    bloc = null;
    getIt.unregister<DeduplicationEngine>();
  });

  Future<void> pumpSearch(
    WidgetTester tester, {
    required SearchState state,
    List<MusicServer> servers = const [],
    Size size = TestSizes.phone,
  }) async {
    await bloc?.close();
    final searchBloc = FakeSearchBloc(state);
    bloc = searchBloc;

    final models = TestViewModels();
    models.servers.emitServers(servers);

    await pumpPage(
      tester,
      BlocProvider<SearchBloc>.value(
        value: searchBloc,
        child: const SearchPage(),
      ),
      viewModels: models,
      size: size,
    );
  }

  final twoServers = [testServer(), testServer(id: 'server2', name: 'Backup')];

  /// Tracks that the dedup engine will keep apart.
  ///
  /// `testTracks` deliberately varies only the title suffix, which is close
  /// enough that DeduplicationEngine — 0.85 similarity, 10s duration
  /// tolerance — merges the lot into one row. That is the engine behaving
  /// correctly on synthetic data; a test about result *counts* needs inputs
  /// that are genuinely distinct.
  List<Track> distinctTracks(int count, {String serverId = 'server1'}) => [
    for (var i = 0; i < count; i++)
      testTrack(
        id: '${serverId}_d$i',
        title: _titles[i % _titles.length] + (i >= _titles.length ? ' $i' : ''),
        artist: 'Artist ${i % 7}',
        album: 'Album ${i % 5}',
        serverId: serverId,
        duration: Duration(seconds: 90 + i * 37),
      ),
  ];

  group('result caps', () {
    final manyResults = SearchStates.success(
      tracks: distinctTracks(30),
      albums: testAlbums(25),
      artists: testArtists(25),
    );

    testWidgets('tracks are capped at a preview until expanded', (
      tester,
    ) async {
      await pumpSearch(tester, state: manyResults);

      expect(find.byType(TrackRow), findsNWidgets(5));

      await tester.tap(find.text('See all').first);
      await tester.pump();

      // Expanded, but still lazy: a SliverList only builds what fits, so the
      // count goes up without becoming thirty.
      final expanded = find.byType(TrackRow).evaluate().length;
      expect(expanded, greaterThan(5));
      expect(expanded, lessThan(30));
    });

    testWidgets('collapsing returns to the preview count', (tester) async {
      await pumpSearch(tester, state: manyResults);

      await tester.tap(find.text('See all').first);
      await tester.pump();
      await tester.tap(find.text('Show less').first);
      await tester.pump();

      expect(find.byType(TrackRow), findsNWidgets(5));
    });
  });

  group('the query listener', () {
    testWidgets('moving the cursor keeps an expanded section open', (
      tester,
    ) async {
      await pumpSearch(
        tester,
        state: SearchStates.success(tracks: distinctTracks(30)),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      field.controller!.value = const TextEditingValue(
        text: 'blue',
        selection: TextSelection.collapsed(offset: 4),
      );
      await tester.pump();

      await tester.tap(find.text('See all').first);
      await tester.pump();
      expect(find.text('Show less'), findsOneWidget);

      // Tapping into the field to fix a typo moves the cursor and nothing
      // else. The controller notifies for that too, and the page used to
      // treat it as a new query.
      field.controller!.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      expect(find.text('Show less'), findsOneWidget);
    });
  });

  group('memoization', () {
    testWidgets('expanding a section does not re-run the dedup engine', (
      tester,
    ) async {
      await pumpSearch(
        tester,
        state: SearchStates.success(tracks: distinctTracks(30)),
      );
      expect(engine.detectCalls, 1);

      await tester.tap(find.text('See all').first);
      await tester.pump();

      expect(engine.detectCalls, 1);
    });

    testWidgets('changing the server filter re-runs it exactly once', (
      tester,
    ) async {
      await pumpSearch(
        tester,
        state: SearchStates.success(
          tracks: [
            ...distinctTracks(6),
            ...distinctTracks(6, serverId: 'server2'),
          ],
        ),
        servers: twoServers,
        // Wide enough that all three chips are laid out; at phone width the
        // last one sits off the end of the horizontal row and cannot be
        // tapped.
        size: TestSizes.tablet,
      );
      final baseline = engine.detectCalls;

      // A different filter is a genuinely different list, so one more pass is
      // correct — what would be wrong is a pass per rebuild.
      // Targeting the chip rather than the text: 'Backup' also appears in
      // the results below, and find.text would resolve to whichever came
      // first in the tree.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Backup'));
      await tester.pump();
      expect(engine.detectCalls, baseline + 1);

      // Re-selecting the same filter produces the same filtered list, so the
      // memo holds and nothing recomputes.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Backup'));
      await tester.pump();
      expect(engine.detectCalls, baseline + 1);
    });
  });

  group('the pinned header', () {
    testWidgets('the search field survives scrolling the results', (
      tester,
    ) async {
      await pumpSearch(
        tester,
        state: SearchStates.success(tracks: distinctTracks(40)),
      );
      expect(find.byType(TextField), findsOneWidget);

      await tester.drag(find.byType(TrackRow).first, const Offset(0, -400));
      await tester.pump();

      // A field that scrolls away is the one thing a search page cannot do.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('one server means no filter chips', (tester) async {
      await pumpSearch(
        tester,
        state: SearchStates.initial,
        servers: [testServer()],
      );

      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('two servers bring the filter chips in', (tester) async {
      await pumpSearch(
        tester,
        state: SearchStates.initial,
        servers: twoServers,
      );

      expect(find.widgetWithText(ChoiceChip, 'All servers'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Backup'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('idle with no history explains what search does', (
      tester,
    ) async {
      await pumpSearch(tester, state: SearchStates.initial);

      expect(find.text('Search your music'), findsOneWidget);
    });

    testWidgets('idle with history offers the recent queries', (tester) async {
      // SearchBloc has carried searchHistory and its events from the start
      // and no widget ever dispatched or rendered them; the idle state showed
      // six hardcoded genre chips instead.
      await pumpSearch(
        tester,
        state: const SearchState.initial().copyWith(
          searchHistory: ['radiohead', 'bowie'],
        ),
      );

      expect(find.text('Recent searches'), findsOneWidget);
      expect(find.text('radiohead'), findsOneWidget);
      expect(find.text('bowie'), findsOneWidget);
    });

    testWidgets('tapping a recent query re-runs and re-records it', (
      tester,
    ) async {
      await pumpSearch(
        tester,
        state: const SearchState.initial().copyWith(
          searchHistory: ['radiohead'],
        ),
      );

      await tester.tap(find.text('radiohead'));
      await tester.pump();

      expect(
        bloc!.dispatched.whereType<SearchHistoryAdded>().single.query,
        'radiohead',
      );
    });

    testWidgets('loading shows a skeleton', (tester) async {
      await pumpSearch(tester, state: SearchStates.loading('x'));

      expect(find.byType(SkeletonTile), findsWidgets);
    });

    testWidgets('a failure offers a retry', (tester) async {
      await pumpSearch(tester, state: SearchStates.failure('Server said no'));

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Server said no'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('no matches explains why', (tester) async {
      await pumpSearch(tester, state: SearchStates.success());

      expect(find.text('No results found'), findsOneWidget);
    });
  });
}
