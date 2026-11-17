import 'package:equatable/equatable.dart';

/// Ранг из `/v1/assets/ranks`.
class RankTier extends Equatable {
  const RankTier({
    required this.tier,
    required this.name,
    required this.colorHex,
  });

  final int tier;
  final String name;
  final String colorHex;

  @override
  List<Object?> get props => [tier, name, colorHex];
}

/// Бейдж игрока: tier + subrank.
class PlayerBadge extends Equatable {
  const PlayerBadge({
    required this.badge,
    required this.tier,
    required this.subrank,
    required this.tierName,
    required this.colorHex,
  });

  final int badge;
  final int tier;
  final int subrank;
  final String tierName;
  final String colorHex;

  String get label => subrank > 0 ? '$tierName $subrank' : tierName;

  /// Собирает бейдж из числового значения API и списка рангов.
  static PlayerBadge? fromBadge(int badge, List<RankTier> tiers) {
    if (badge <= 0) {
      return null;
    }
    final tier = badge ~/ 10;
    final subrank = badge % 10;
    RankTier? match;
    for (final item in tiers) {
      if (item.tier == tier) {
        match = item;
        break;
      }
    }
    return PlayerBadge(
      badge: badge,
      tier: tier,
      subrank: subrank,
      tierName: match?.name ?? 'Ранг $tier',
      colorHex: match?.colorHex ?? '',
    );
  }

  @override
  List<Object?> get props => [badge, tier, subrank, tierName, colorHex];
}
