import 'package:equatable/equatable.dart';

class Item extends Equatable {
  const Item({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.tier,
    required this.cost,
    required this.slotType,
  });

  final int id;
  final String name;
  final String imageUrl;
  final int tier;
  final int cost;
  final String slotType;

  bool get hasImage => imageUrl.isNotEmpty;

  @override
  List<Object?> get props => [id, name, imageUrl, tier, cost, slotType];
}
