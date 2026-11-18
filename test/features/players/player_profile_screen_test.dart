import 'package:deadlock_tracker/core/theme/app_theme.dart';
import 'package:deadlock_tracker/domain/entities/hero.dart';
import 'package:deadlock_tracker/domain/entities/match_record.dart';
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
    ),
  ],
  badge: null,
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
          home: const PlayerProfileScreen(
            accountId: 42,
            personaName: 'Pavlov',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('История матчей'.toUpperCase()), findsOneWidget);
    expect(find.text('ПОБЕДА'), findsOneWidget);
    expect(find.text('ПОРАЖЕНИЕ'), findsOneWidget);
    expect(find.text('12/3/9'), findsOneWidget);

    await tester.tap(find.text('ПОБЕДА'));
    await tester.pumpAndSettle();

    expect(find.text('ПРЕДМЕТЫ'), findsOneWidget);
    expect(find.text('Данные о предметах недоступны'), findsOneWidget);
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
