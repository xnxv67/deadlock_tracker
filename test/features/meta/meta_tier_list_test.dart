import 'package:deadlock_tracker/domain/entities/hero.dart';
import 'package:deadlock_tracker/domain/entities/hero_meta.dart';
import 'package:deadlock_tracker/domain/repositories/hero_repository.dart';
import 'package:deadlock_tracker/presentation/screens/meta_screen.dart';
import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _meta = [
  HeroMeta(
    hero: Hero(id: 1, name: 'S-Tier', role: 'Carry', imageUrl: '', cardUrl: ''),
    matches: 100,
    wins: 60,
    pickRate: 0.12,
  ),
  HeroMeta(
    hero: Hero(id: 2, name: 'A-Tier', role: 'Tank', imageUrl: '', cardUrl: ''),
    matches: 100,
    wins: 53,
    pickRate: 0.09,
  ),
  HeroMeta(
    hero: Hero(
      id: 3,
      name: 'B-Tier',
      role: 'Support',
      imageUrl: '',
      cardUrl: '',
    ),
    matches: 100,
    wins: 51,
    pickRate: 0.07,
  ),
  HeroMeta(
    hero: Hero(
      id: 4,
      name: 'C-Tier',
      role: 'Initiator',
      imageUrl: '',
      cardUrl: '',
    ),
    matches: 100,
    wins: 49,
    pickRate: 0.05,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('мета отображается тирлистом с метриками и сортировкой', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepositoryProvider<HeroRepository>.value(
        value: _FakeHeroRepository(),
        child: const MaterialApp(home: MetaScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (final tier in ['S', 'A', 'B', 'C']) {
      expect(find.text('TIER $tier'), findsOneWidget);
    }
    expect(find.text('S-Tier'), findsOneWidget);
    expect(find.text('60.0%'), findsWidgets);
    expect(find.text('12.0%'), findsOneWidget);
    expect(find.text('100'), findsWidgets);
    expect(find.text('Винрейт выше 54%'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Пикрейт'));
    await tester.pumpAndSettle();
    expect(find.text('12.0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeHeroRepository implements HeroRepository {
  @override
  Future<List<HeroMeta>> getMeta() async => _meta;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
