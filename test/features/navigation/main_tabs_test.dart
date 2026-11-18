import 'package:deadlock_tracker/domain/entities/hero.dart';
import 'package:deadlock_tracker/domain/entities/hero_meta.dart';
import 'package:deadlock_tracker/domain/entities/leaderboard_player.dart';
import 'package:deadlock_tracker/domain/entities/player_badge.dart';
import 'package:deadlock_tracker/domain/entities/player_profile.dart';
import 'package:deadlock_tracker/domain/entities/steam_profile.dart';
import 'package:deadlock_tracker/domain/repositories/hero_repository.dart';
import 'package:deadlock_tracker/domain/repositories/leaderboard_repository.dart';
import 'package:deadlock_tracker/domain/repositories/player_repository.dart';
import 'package:deadlock_tracker/features/heroes/screens/main_screen.dart';
import 'package:deadlock_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _heroMeta = [
  HeroMeta(
    hero: Hero(
      id: 1,
      name: 'Infernus',
      role: 'Carry',
      imageUrl: '',
      cardUrl: '',
    ),
    matches: 100,
    wins: 60,
    pickRate: 0.12,
  ),
  HeroMeta(
    hero: Hero(
      id: 6,
      name: 'Abrams',
      role: 'Tank',
      imageUrl: '',
      cardUrl: '',
    ),
    matches: 100,
    wins: 45,
    pickRate: 0.09,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('вкладки лидеров и поиска открываются без ошибок', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Infernus'), findsOneWidget);
    expect(find.text('Abrams'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Infer');
    await tester.pumpAndSettle();
    expect(find.text('Infernus'), findsOneWidget);
    expect(find.text('Abrams'), findsNothing);

    await tester.tap(find.byIcon(Icons.emoji_events_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.textContaining('42'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_search_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Найди игрока'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

Widget _testApp() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<HeroRepository>.value(value: _FakeHeroRepository()),
      RepositoryProvider<PlayerRepository>.value(value: _FakePlayerRepository()),
      RepositoryProvider<LeaderboardRepository>.value(
        value: _FakeLeaderboardRepository(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainScreen(),
    ),
  );
}

class _FakeHeroRepository implements HeroRepository {
  @override
  Future<List<HeroMeta>> getMeta() async => _heroMeta;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlayerRepository implements PlayerRepository {
  @override
  Future<List<SteamProfile>> searchSteam(String query) async => const [];

  @override
  Future<Map<int, PlayerBadge>> getRanks(List<int> accountIds) async =>
      const {};

  @override
  Future<PlayerProfile> getProfile(int accountId) async => PlayerProfile(
    accountId: accountId,
    heroes: const [],
    matches: const [],
    badge: null,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<List<LeaderboardPlayer>> getLeaderboard({
    LeaderboardRegion region = LeaderboardRegion.europe,
  }) async => const [
    LeaderboardPlayer(
      position: 1,
      name: 'Alpha',
      badge: null,
      topHeroes: [],
      accountId: 1,
      wins: 42,
    ),
    LeaderboardPlayer(
      position: 2,
      name: 'Beta',
      badge: null,
      topHeroes: [],
      accountId: 2,
      wins: 30,
    ),
    LeaderboardPlayer(
      position: 3,
      name: 'Gamma',
      badge: null,
      topHeroes: [],
      accountId: 3,
      wins: 20,
    ),
    LeaderboardPlayer(
      position: 4,
      name: 'Delta',
      badge: null,
      topHeroes: [],
      accountId: 4,
      wins: 10,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
