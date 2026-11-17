/// Модель героя для слоя данных.
///
/// В проекте уже есть доменная сущность [Hero] (`lib/domain/entities/hero.dart`)
/// на базе `equatable`. Чтобы не плодить два несовместимых класса с одним
/// именем (это сломало бы `List<Hero>` между слоями), файл-модель реэкспортирует
/// её. Импорт `package:deadlock_tracker/data/models/hero.dart` даёт тот же
/// `Hero`, который используют репозитории, BLoC и экраны.
library;

export '../../domain/entities/hero.dart';
