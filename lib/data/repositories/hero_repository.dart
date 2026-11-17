/// Контракт репозитория героев для слоя данных.
///
/// Интерфейс живёт в доменном слое (`lib/domain/repositories/hero_repository.dart`),
/// а реализация — в `lib/data/repositories/hero_repository_impl.dart`.
/// Реэкспорт позволяет импортировать контракт по пути слоя данных и при этом
/// не дублировать абстракцию.
library;

export '../../domain/repositories/hero_repository.dart';
