import 'json_utils.dart';

/// Ответ `/v1/players/rank?account_ids=...`.
class PlayerRankDto {
  const PlayerRankDto({
    required this.accountId,
    required this.badge,
    required this.rank,
    required this.subrank,
  });

  final int accountId;

  /// Полный бейдж: tier * 10 + subrank (например, 95 → Phantom 5).
  final int badge;
  final int rank;
  final int subrank;

  factory PlayerRankDto.fromJson(Map<String, dynamic> json) {
    return PlayerRankDto(
      accountId: jsonInt(json['account_id']),
      badge: jsonInt(json['badge']),
      rank: jsonInt(json['rank']),
      subrank: jsonInt(json['subrank']),
    );
  }
}
