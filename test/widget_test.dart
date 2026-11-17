import 'package:deadlock_tracker/data/dto/hero_build_dto.dart';
import 'package:deadlock_tracker/data/dto/hero_counter_dto.dart';
import 'package:deadlock_tracker/data/dto/hero_dto.dart';
import 'package:deadlock_tracker/data/dto/hero_stats_dto.dart';
import 'package:deadlock_tracker/data/dto/leaderboard_entry_dto.dart';
import 'package:deadlock_tracker/data/dto/match_history_dto.dart';
import 'package:deadlock_tracker/domain/entities/player_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hero stats dto computes win rate defensively', () {
    final dto = HeroStatsDto.fromJson(const {
      'hero_id': 1,
      'wins': '546',
      'losses': 435,
      'matches': null,
    });

    expect(dto.heroId, 1);
    expect(dto.matches, 981);
    expect(dto.winRate, closeTo(546 / 981, 0.0001));
  });

  test('counter dto parses flat pair rows', () {
    final dto = HeroCounterDto.fromJson(const {
      'hero_id': 2,
      'enemy_hero_id': 1,
      'wins': 87085,
      'matches_played': 158831,
    });

    expect(dto.heroId, 2);
    expect(dto.enemyHeroId, 1);
    expect(dto.winRate, closeTo(87085 / 158831, 0.0001));
  });

  test('hero dto reads nested role and image urls', () {
    final dto = HeroDto.fromJson(const {
      'id': 1,
      'name': 'Infernus',
      'description': {'role': 'Lights up enemies'},
      'images': {
        'icon_image_small': 'https://example.com/sm.png',
        'icon_hero_card': 'https://example.com/card.png',
      },
      'player_selectable': true,
      'disabled': false,
    });

    final hero = dto.toEntity();
    expect(hero.id, 1);
    expect(hero.name, 'Infernus');
    expect(hero.role, 'Lights up enemies');
    expect(hero.imageUrl, 'https://example.com/sm.png');
    expect(hero.cardUrl, 'https://example.com/card.png');
  });

  test('match history derives win from winning team', () {
    final win = MatchHistoryDto.fromJson(const {
      'match_id': 1,
      'hero_id': 1,
      'start_time': 1794712779,
      'player_team': 0,
      'match_result': 0,
      'player_kills': 10,
      'player_deaths': 4,
      'player_assists': 10,
      'match_duration_s': 1664,
    });
    final loss = MatchHistoryDto.fromJson(const {
      'match_id': 2,
      'hero_id': 1,
      'start_time': 1794712780,
      'player_team': 1,
      'match_result': 0,
      'player_kills': 3,
      'player_deaths': 8,
      'player_assists': 2,
      'match_duration_s': 1200,
    });

    expect(win.isWin, isTrue);
    expect(loss.isWin, isFalse);

    final restored = MatchHistoryDto.fromCompactJson(win.toCompactJson());
    expect(restored.isWin, isTrue);
    expect(restored.kills, 10);
    expect(restored.durationSeconds, 1664);
  });

  test('player badge decodes tier and subrank', () {
    final badge = PlayerBadge.fromBadge(95, const [
      RankTier(tier: 9, name: 'Phantom', colorHex: '#7C7C7C'),
    ]);

    expect(badge, isNotNull);
    expect(badge!.tier, 9);
    expect(badge.subrank, 5);
    expect(badge.label, 'Phantom 5');
    expect(PlayerBadge.fromBadge(0, const []), isNull);
  });

  test('leaderboard entry falls back to list position', () {
    final dto = LeaderboardEntryDto.fromJson(const {
      'account_name': 'MikaelS',
      'possible_account_ids': [1, 2],
      'top_hero_ids': [10, 17],
    }, fallbackPosition: 7);

    expect(dto.position, 7);
    expect(dto.name, 'MikaelS');
    expect(dto.possibleAccountIds, [1, 2]);
    expect(dto.topHeroIds, [10, 17]);
  });

  test('hero build dto extracts unique item ids', () {
    final dto = HeroBuildDto.fromJson(const {
      'hero_build': {
        'hero_build_id': 256053,
        'hero_id': 1,
        'name': 'SN|P3R : Molten Fury',
        'author_account_id': 29715818,
        'details': {
          'mod_categories': [
            {
              'mods': [
                {'ability_id': 668299740},
                {'ability_id': 668299740},
                {'ability_id': 7409189},
              ],
            },
          ],
        },
      },
    });

    expect(dto.buildId, 256053);
    expect(dto.name, 'SN|P3R : Molten Fury');
    expect(dto.itemIds, [668299740, 7409189]);
  });
}
