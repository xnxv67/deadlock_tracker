import 'package:deadlock_tracker/core/theme/app_theme.dart';
import 'package:deadlock_tracker/domain/entities/hero.dart';
import 'package:deadlock_tracker/domain/entities/hero_build.dart';
import 'package:deadlock_tracker/domain/entities/hero_counter.dart';
import 'package:deadlock_tracker/domain/entities/hero_detailed_stats.dart';
import 'package:deadlock_tracker/domain/entities/hero_trend.dart';
import 'package:deadlock_tracker/domain/entities/item.dart';
import 'package:deadlock_tracker/domain/repositories/hero_repository.dart';
import 'package:deadlock_tracker/features/heroes/screens/hero_detail_screen.dart';
import 'package:deadlock_tracker/presentation/widgets/remote_image.dart';
import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _inferno = Hero(
  id: 1,
  name: 'Infernus',
  role: 'Carry',
  imageUrl: '',
  cardUrl: '',
  backgroundUrl: 'https://assets.example.com/infernus_bg.png',
);

const _abrams = Hero(
  id: 6,
  name: 'Abrams',
  role: 'Tank',
  imageUrl: '',
  cardUrl: '',
);

const _items = [
  Item(
    id: 1,
    name: 'Basic Magazine',
    imageUrl: '',
    tier: 1,
    cost: 500,
    slotType: 'weapon',
  ),
  Item(
    id: 2,
    name: 'Extra Stamina',
    imageUrl: '',
    tier: 1,
    cost: 500,
    slotType: 'vitality',
  ),
  Item(
    id: 3,
    name: 'Mystic Shot',
    imageUrl: '',
    tier: 3,
    cost: 3000,
    slotType: 'spirit',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('баннер ограничен по высоте и вкладки переключаются', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_inferno, const _FullRepository()));
    await tester.pumpAndSettle();

    expect(find.text('ОБЗОР'), findsOneWidget);
    expect(find.text('СБОРКИ'), findsOneWidget);
    expect(find.text('МАТЧАПЫ'), findsOneWidget);
    expect(find.text('54.0%'), findsOneWidget);
    expect(find.text('4.78'), findsOneWidget);

    final banner = tester.getSize(find.byType(RemoteImage).first);
    expect(banner.height, lessThanOrEqualTo(230.0));

    await tester.tap(find.text('СБОРКИ'));
    await tester.pumpAndSettle();
    expect(find.text('РАННЯЯ ИГРА'), findsOneWidget);
    expect(find.text('СРЕДНЯЯ ИГРА'), findsOneWidget);
    expect(find.text('ПОЗДНЯЯ ИГРА'), findsOneWidget);

    await tester.tap(find.text('МАТЧАПЫ'));
    await tester.pumpAndSettle();
    expect(find.text('ХУДШИЕ ПРОТИВНИКИ'), findsOneWidget);
    expect(find.text('ЛУЧШИЕ ПРОТИВНИКИ'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('пустые сборки и матчапы показывают заглушки, а не ошибку', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_inferno, const _EmptyRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('СБОРКИ'));
    await tester.pumpAndSettle();
    expect(find.text('Нет данных по сборкам'), findsOneWidget);

    await tester.tap(find.text('МАТЧАПЫ'));
    await tester.pumpAndSettle();
    expect(find.text('Нет данных по матчапам'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('10 кликов по KDA открывают Labs только у Inferno', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_abrams, const _FullRepository()));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('KDA'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Лабораторные работы'), findsNothing);

    await tester.pumpWidget(_app(_inferno, const _FullRepository()));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('KDA'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Лабораторные работы'), findsWidgets);
  });
}

Widget _app(Hero hero, HeroRepository repository) {
  return RepositoryProvider<HeroRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: buildAppTheme(),
      home: HeroDetailScreen(hero: hero),
    ),
  );
}

const _stats = HeroDetailedStats(
  matches: 100,
  wins: 54,
  kills: 8.5,
  deaths: 3.2,
  assists: 6.8,
  netWorth: 42000,
  playerDamage: 54000,
  playerDamageTaken: 31000,
  lastHits: 210,
  denies: 12,
);

final _trend = HeroTrend(
  points: [
    HeroTrendPoint(date: DateTime(2026, 1, 1), winRate: 0.52, matches: 100),
    HeroTrendPoint(date: DateTime(2026, 1, 2), winRate: 0.54, matches: 120),
  ],
  weekDelta: 0.02,
);

const _counters = [
  HeroCounter(
    enemy: Hero(
      id: 3,
      name: 'Vindicta',
      role: 'Carry',
      imageUrl: '',
      cardUrl: '',
    ),
    matches: 120,
    wins: 40,
  ),
  HeroCounter(
    enemy: Hero(id: 4, name: 'Seven', role: 'Carry', imageUrl: '', cardUrl: ''),
    matches: 80,
    wins: 60,
  ),
  HeroCounter(
    enemy: Hero(id: 5, name: 'Haze', role: 'Carry', imageUrl: '', cardUrl: ''),
    matches: 70,
    wins: 50,
  ),
  HeroCounter(
    enemy: Hero(id: 6, name: 'Abrams', role: 'Tank', imageUrl: '', cardUrl: ''),
    matches: 65,
    wins: 45,
  ),
  HeroCounter(
    enemy: Hero(
      id: 7,
      name: 'Wraith',
      role: 'Carry',
      imageUrl: '',
      cardUrl: '',
    ),
    matches: 60,
    wins: 40,
  ),
  HeroCounter(
    enemy: Hero(
      id: 8,
      name: 'McGinnis',
      role: 'Support',
      imageUrl: '',
      cardUrl: '',
    ),
    matches: 55,
    wins: 35,
  ),
  HeroCounter(
    enemy: Hero(
      id: 9,
      name: 'Lash',
      role: 'Initiator',
      imageUrl: '',
      cardUrl: '',
    ),
    matches: 50,
    wins: 30,
  ),
];

const _builds = [
  HeroBuild(
    buildId: 1,
    name: 'Spirit burst',
    items: _items,
    matches: 50,
    wins: 30,
    buyTimes: {1: 300, 2: 900, 3: 2400},
  ),
];

class _FullRepository implements HeroRepository {
  const _FullRepository();

  @override
  Future<HeroDetailedStats?> getHeroDetailedStats(int heroId) async => _stats;

  @override
  Future<List<HeroCounter>> getCounters(int heroId) async => _counters;

  @override
  Future<List<HeroBuild>> getBuilds(int heroId) async => _builds;

  @override
  Future<HeroTrend?> getHeroTrend(int heroId) async => _trend;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyRepository implements HeroRepository {
  const _EmptyRepository();

  @override
  Future<HeroDetailedStats?> getHeroDetailedStats(int heroId) async => _stats;

  @override
  Future<List<HeroCounter>> getCounters(int heroId) async => const [];

  @override
  Future<List<HeroBuild>> getBuilds(int heroId) async => const [];

  @override
  Future<HeroTrend?> getHeroTrend(int heroId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
