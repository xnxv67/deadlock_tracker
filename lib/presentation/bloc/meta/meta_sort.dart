import '../../../domain/entities/hero_meta.dart';

enum MetaSortField { winRate, pickRate, matches, name }

List<HeroMeta> sortHeroes(
  List<HeroMeta> heroes,
  MetaSortField field,
  bool ascending,
) {
  final result = [...heroes];
  result.sort((first, second) {
    var compare = switch (field) {
      MetaSortField.name => first.hero.name.toLowerCase().compareTo(
        second.hero.name.toLowerCase(),
      ),
      MetaSortField.matches => first.matches.compareTo(second.matches),
      MetaSortField.pickRate => first.pickRate.compareTo(second.pickRate),
      MetaSortField.winRate => first.winRate.compareTo(second.winRate),
    };
    if (compare == 0) {
      compare = first.matches.compareTo(second.matches);
    }
    return ascending ? compare : -compare;
  });
  return result;
}
