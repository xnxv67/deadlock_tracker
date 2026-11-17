// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Deadlock Tracker';

  @override
  String get heroesTab => 'Heroes';

  @override
  String get favoritesTab => 'Favorites';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get heroDetails => 'Hero details';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get heroDescription => 'Description';

  @override
  String get retry => 'Retry';
}
