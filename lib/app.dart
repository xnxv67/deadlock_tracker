import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/deadlock_api.dart';
import 'domain/repositories/hero_repository.dart';
import 'domain/repositories/items_repository.dart';
import 'domain/repositories/leaderboard_repository.dart';
import 'domain/repositories/player_repository.dart';
import 'features/heroes/screens/main_screen.dart';
import 'features/search/bloc/hero_search_bloc.dart';
import 'l10n/app_localizations.dart';
import 'presentation/screens/main_shell.dart';

class DeadlockApp extends StatelessWidget {
  const DeadlockApp({
    super.key,
    required this.heroRepository,
    required this.playerRepository,
    required this.itemsRepository,
    required this.leaderboardRepository,
    required this.api,
  });

  final HeroRepository heroRepository;
  final PlayerRepository playerRepository;
  final ItemsRepository itemsRepository;
  final LeaderboardRepository leaderboardRepository;
  final DeadlockApi api;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HeroRepository>.value(value: heroRepository),
        RepositoryProvider<PlayerRepository>.value(value: playerRepository),
        RepositoryProvider<ItemsRepository>.value(value: itemsRepository),
        RepositoryProvider<LeaderboardRepository>.value(
          value: leaderboardRepository,
        ),
        RepositoryProvider<DeadlockApi>.value(value: api),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HeroSearchBloc>(
            create: (context) =>
                HeroSearchBloc(context.read<HeroRepository>()),
          ),
        ],
        child: MaterialApp(
        title: 'Deadlock Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainScreen(),
        routes: {
            '/tracker': (_) => const MainShell(),
          },
        ),
      ),
    );
  }
}
