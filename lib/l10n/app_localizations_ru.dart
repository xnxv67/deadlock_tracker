// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Deadlock Tracker';

  @override
  String get heroesTab => 'Герои';

  @override
  String get favoritesTab => 'Избранное';

  @override
  String get addedToFavorites => 'Добавлено в избранное';

  @override
  String get removedFromFavorites => 'Удалено из избранного';

  @override
  String get heroDetails => 'Детали героя';

  @override
  String get noFavorites => 'Пока нет избранных героев';

  @override
  String get heroDescription => 'Описание';

  @override
  String get retry => 'Повторить';
}
