import '../entities/player_analysis.dart';
import '../entities/player_badge.dart';
import '../entities/player_profile.dart';
import '../entities/steam_profile.dart';

abstract class PlayerRepository {
  /// Статистика героев и последние матчи игрока.
  Future<PlayerProfile> getProfile(int accountId);

  /// Линии, кривая показателей и распределение метрик.
  Future<PlayerAnalysis> getAnalysis(int accountId);

  /// Поиск игроков по нику Steam.
  Future<List<SteamProfile>> searchSteam(String query);

  /// Бейджи рангов для списка игроков (батч-запрос).
  Future<Map<int, PlayerBadge>> getRanks(List<int> accountIds);
}
