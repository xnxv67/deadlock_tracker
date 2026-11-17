import 'json_utils.dart';

/// Одна категория предметов в билде (Early / Mid / Late / Counters ...).
class HeroBuildCategoryDto {
  const HeroBuildCategoryDto({
    required this.name,
    required this.itemIds,
    required this.annotations,
  });

  final String name;
  final List<int> itemIds;

  /// Комментарий автора к предмету (по индексу, если есть).
  final Map<int, String> annotations;

  factory HeroBuildCategoryDto.fromJson(Map<String, dynamic> json) {
    final name = jsonString(json['name']);
    final itemIds = <int>[];
    final annotations = <int, String>{};
    for (final mod in jsonList(json['mods'])) {
      final map = jsonMap(mod);
      final id = jsonInt(map['ability_id']);
      if (id <= 0) {
        continue;
      }
      itemIds.add(id);
      final annotation = jsonString(map['annotation']);
      if (annotation.isNotEmpty) {
        annotations[id] = annotation;
      }
    }
    return HeroBuildCategoryDto(
      name: name,
      itemIds: itemIds,
      annotations: annotations,
    );
  }
}

/// Ответ `/v1/builds/{hero_id}/{build_id}`.
///
/// Имя и предметы лежат в `hero_build`, а статистика приходит из
/// `/v1/analytics/hero-build-stats/{hero_id}`.
class HeroBuildDto {
  const HeroBuildDto({
    required this.buildId,
    required this.heroId,
    required this.name,
    required this.authorAccountId,
    required this.itemIds,
    this.categories = const [],
  });

  final int buildId;
  final int heroId;
  final String name;
  final int authorAccountId;
  final List<int> itemIds;
  final List<HeroBuildCategoryDto> categories;

  factory HeroBuildDto.fromJson(Map<String, dynamic> json) {
    final root = jsonMap(json['hero_build']).isNotEmpty
        ? jsonMap(json['hero_build'])
        : json;

    final details = jsonMap(root['details']);
    final itemIds = <int>[];
    final categories = <HeroBuildCategoryDto>[];
    for (final category in jsonList(details['mod_categories'])) {
      final categoryMap = jsonMap(category);
      final parsed = HeroBuildCategoryDto.fromJson(categoryMap);
      if (parsed.itemIds.isNotEmpty) {
        categories.add(parsed);
      }
      for (final id in parsed.itemIds) {
        if (!itemIds.contains(id)) {
          itemIds.add(id);
        }
      }
    }

    return HeroBuildDto(
      buildId: jsonInt(root['hero_build_id']),
      heroId: jsonInt(root['hero_id']),
      name: jsonString(
        root['name'],
        "Сборка #${jsonInt(root['hero_build_id'])}",
      ),
      authorAccountId: jsonInt(root['author_account_id']),
      itemIds: itemIds,
      categories: categories,
    );
  }
}
