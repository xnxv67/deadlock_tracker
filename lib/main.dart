import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/cache/api_cache.dart';
import 'core/constants/api_constants.dart';
import 'data/datasources/deadlock_api.dart';
import 'data/repositories/asset_catalog.dart';
import 'data/repositories/hero_repository_impl.dart';
import 'data/repositories/items_repository_impl.dart';
import 'data/repositories/leaderboard_repository_impl.dart';
import 'data/repositories/player_repository_impl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final cache = ApiCache();
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: const {'Accept': 'application/json'},
      listFormat: ListFormat.multi,
    ),
  );

  final api = DeadlockApi(dio, cache);
  final catalog = AssetCatalog(api);

  runApp(
    DeadlockApp(
      heroRepository: HeroRepositoryImpl(api, catalog),
      playerRepository: PlayerRepositoryImpl(api, catalog),
      itemsRepository: ItemsRepositoryImpl(api, catalog),
      leaderboardRepository: LeaderboardRepositoryImpl(api, catalog),
      api: api,
    ),
  );
}
