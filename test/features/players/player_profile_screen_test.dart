import 'package:deadlock_tracker/core/theme/app_theme.dart';
import 'package:deadlock_tracker/domain/entities/hero.dart';
import 'package:deadlock_tracker/domain/entities/match_record.dart';
import 'package:deadlock_tracker/domain/entities/player_analysis.dart';
import 'package:deadlock_tracker/domain/entities/player_badge.dart';
import 'package:deadlock_tracker/domain/entities/player_hero_stat.dart';
import 'package:deadlock_tracker/domain/entities/player_profile.dart';
import 'package:deadlock_tracker/domain/entities/steam_profile.dart';
import 'package:deadlock_tracker/domain/repositories/player_repository.dart';
import 'package:deadlock_tracker/features/players/screens/player_profile_screen.dart';
import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _hero = Hero(
  id: 1,
  name: 'Infernus',
  role: 'Carry',
  imageUrl: '',
  cardUrl: '',
);

final _profile = PlayerProfile(
  accountId: 42,
  heroes: const [
    PlayerHeroStat(
      hero: _hero,
      matches: 100,
      wins: 54,
      kills: 850,
      deaths: 320,
      assists: 680,
    ),
  ],
  matches: const [
    MatchRecord(
      matchId: 9001,
      hero: _hero,
      isWin: true,
      kills: 12,
      deaths: 3,
      assists: 9,
      durationSeconds: 1980,
      startTime: 1794712779,
      netWorth: 24500,
      rankedBadge: 55,
      rankedDelta: 350,
    ),
    MatchRecord(
      matchId: 9002,
      hero: _hero,
      isWin: false,
      kills: 4,
      deaths: 8,
      assists: 5,
      durationSeconds: 2400,
      startTime: 1794710000,
      netWorth: 18300,
      rankedBadge: 54,
      rankedDelta: -180,
    ),
  ],
  badge: null,
);

const _analysis = PlayerAnalysis(
  lanes: [
    LanePerformance(laneId: 1, matches: 6, wins: 4, netWorthDiff: 120),
    LanePerformance(laneId: 4, matches: 3, wins: 1, netWorthDiff: -90),
  ],
  soulCurve: [
    LaneSoulPoint(seconds: 300, netWorthDiff: -40),
    LaneSoulPoint(seconds: 600, netWorthDiff: 120),
    LaneSoulPoint(seconds: 900, netWorthDiff: 260),
  ],
  curve: [
    PlayerCurvePoint(
      gameTime: 0,
      netWorth: 600,
      kills: 0,
      deaths: 0,
      assists: 0,
      playerDamage: 0,
      creepKills: 0,
      denies: 0,
    ),
    PlayerCurvePoint(
      gameTime: 50,
      netWorth: 12000,
      kills: 4,
      deaths: 2,
      assists: 5,
      playerDamage: 9000,
      creepKills: 120,
      denies: 6,
    ),
    PlayerCurvePoint(
      gameTime: 100,
      netWorth: 24000,
      kills: 9,
      deaths: 4,
      assists: 11,
      playerDamage: 21000,
      creepKills: 240,
      denies: 12,
    ),
  ],
  metrics: {
    'kda': MetricRange(
      key: 'kda',
      avg: 2.8,
      std: 0.6,
      p25: 2.1,
      p50: 2.8,
      p75: 3.4,
    ),
    'accuracy': MetricRange(
      key: 'accuracy',
      avg: 0.42,
      std: 0.05,
      p25: 0.38,
      p50: 0.42,
      p75: 0.47,
    ),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('профиль показывает историю матчей и детали по клику', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepositoryProvider<PlayerRepository>.value(
        value: const _FakePlayerRepository(),
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const PlayerProfileScreen(accountId: 42, personaName: 'Pavlov'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ПОСЛЕДНИЕ МАТЧИ'), findsOneWidget);
    expect(find.text('ПОБЕДА'), findsOneWidget);
    expect(find.text('ПОРАЖЕНИЕ'), findsOneWidget);
    expect(find.textContaining('12 / 3 / 9'), findsWidgets);

    await tester.ensureVisible(find.text('ПОБЕДА'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ПОБЕДА'));
    await tester.pumpAndSettle();

    expect(find.text('ПРЕДМЕТЫ'), findsOneWidget);
    expect(find.text('Данные о предметах недоступны'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('вкладки профиля переключаются без ошибок', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepositoryProvider<PlayerRepository>.value(
        value: const _FakePlayerRepository(),
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const PlayerProfileScreen(accountId: 42, personaName: 'Pavlov'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('ГЕРОИ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ГЕРОИ'));
    await tester.pumpAndSettle();
    expect(find.text('ГЕРОИ ИГРОКА'), findsOneWidget);

    await tester.ensureVisible(find.text('СТАТИСТИКА'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('СТАТИСТИКА'));
    await tester.pumpAndSettle();
    expect(find.text('КРИВАЯ ФОРМЫ'), findsOneWidget);

    await tester.ensureVisible(find.text('МАТЧИ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('МАТЧИ'));
    await tester.pumpAndSettle();
    expect(find.text('ПОБЕДЫ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('широкий профиль рендерится в две колонки', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepositoryProvider<PlayerRepository>.value(
        value: const _FakePlayerRepository(),
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const PlayerProfileScreen(accountId: 42, personaName: 'Pavlov'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ИНДЕКС ФОРМЫ'), findsOneWidget);
    expect(find.text('НЕДАВНЯЯ АКТИВНОСТЬ'), findsOneWidget);
    expect(find.text('ЛЮБИМЫЕ ГЕРОИ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('вкладки линий, анализа и наград показывают аналитику', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepositoryProvider<PlayerRepository>.value(
        value: const _FakePlayerRepository(),
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const PlayerProfileScreen(accountId: 42, personaName: 'Pavlov'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ЛИНИИ'));
    await tester.pumpAndSettle();
    expect(find.text('ИГРА ПО ЛИНИЯМ'), findsOneWidget);
    expect(find.text('Йорк'), findsOneWidget);
    expect(find.text('РАЗНИЦА ДУШ НА ЛИНИИ'), findsOneWidget);

    await tester.tap(find.text('АНАЛИЗ'));
    await tester.pumpAndSettle();
    expect(find.text('РАНГОВЫЙ ПРОГРЕСС'), findsOneWidget);
    expect(find.text('КРИВАЯ ПОКАЗАТЕЛЕЙ'), findsOneWidget);
    expect(find.text('5.5'), findsWidgets);

    await tester.tap(find.text('НАГРАДЫ'));
    await tester.pumpAndSettle();
    expect(find.text('НАГРАДЫ MVP'), findsOneWidget);
    expect(find.text('ДОСТИЖЕНИЯ'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

class _FakePlayerRepository implements PlayerRepository {
  const _FakePlayerRepository();

  @override
  Future<PlayerProfile> getProfile(int accountId) async => _profile;

  @override
  Future<List<SteamProfile>> searchSteam(String query) async => const [];

  @override
  Future<Map<int, PlayerBadge>> getRanks(List<int> accountIds) async =>
      const {};

  @override
  Future<PlayerAnalysis> getAnalysis(int accountId) async => _analysis;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
