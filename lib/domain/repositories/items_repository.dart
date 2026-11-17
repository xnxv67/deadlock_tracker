import '../entities/item_meta.dart';

abstract class ItemsRepository {
  /// Предметы с винрейтом, пикрейтом и числом матчей.
  Future<List<ItemMeta>> getItems();
}
