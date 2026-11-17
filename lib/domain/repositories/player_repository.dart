import '../entities/player_profile.dart';
import '../entities/steam_profile.dart';

abstract class PlayerRepository {
  /// Статистика героев и последние матчи игрока.
  Future<PlayerProfile> getProfile(int accountId);

  /// Поиск игроков по нику Steam.
  Future<List<SteamProfile>> searchSteam(String query);
}
