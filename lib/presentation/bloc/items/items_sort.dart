import '../../../domain/entities/item_meta.dart';

enum ItemSortField { winRate, pickRate, matches, buyTime, name }

List<ItemMeta> sortItems(
  List<ItemMeta> items,
  ItemSortField field,
  bool ascending,
) {
  final result = [...items];
  result.sort((first, second) {
    var compare = switch (field) {
      ItemSortField.name => first.item.name.toLowerCase().compareTo(
        second.item.name.toLowerCase(),
      ),
      ItemSortField.matches => first.matches.compareTo(second.matches),
      ItemSortField.pickRate => first.pickRate.compareTo(second.pickRate),
      ItemSortField.winRate => first.winRate.compareTo(second.winRate),
      ItemSortField.buyTime =>
        first.avgBuyTimeS.compareTo(second.avgBuyTimeS),
    };
    if (compare == 0) {
      compare = first.matches.compareTo(second.matches);
    }
    return ascending ? compare : -compare;
  });
  return result;
}
