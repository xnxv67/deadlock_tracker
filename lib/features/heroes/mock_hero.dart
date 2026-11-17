/// Временная заглушка героя, пока OpenCode не выложит lib/data/models/hero.dart.
/// После появления реальной модели заменить использование на неё.
class MockHero {
  const MockHero({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.role,
  });

  final int id;
  final String name;
  final String imageUrl;
  final String role;

  /// Временный список для превью карточек.
  static const List<MockHero> samples = [
    MockHero(
      id: 1,
      name: 'Abrams',
      role: 'Tank',
      imageUrl:
          'https://assets-bucket.deadlock-api.com/heroes/abrams_sm.png',
    ),
    MockHero(
      id: 2,
      name: 'Bebop',
      role: 'Support',
      imageUrl:
          'https://assets-bucket.deadlock-api.com/heroes/bebop_sm.png',
    ),
    MockHero(
      id: 3,
      name: 'Dynamo',
      role: 'Support',
      imageUrl:
          'https://assets-bucket.deadlock-api.com/heroes/dynamo_sm.png',
    ),
    MockHero(
      id: 4,
      name: 'Haze',
      role: 'Carry',
      imageUrl:
          'https://assets-bucket.deadlock-api.com/heroes/haze_sm.png',
    ),
    MockHero(
      id: 5,
      name: 'Infernus',
      role: 'Carry',
      imageUrl:
          'https://assets-bucket.deadlock-api.com/heroes/infernus_sm.png',
    ),
    MockHero(
      id: 6,
      name: 'Lady Geist',
      role: 'Mage',
      imageUrl:
          'https://assets-bucket.deadlock-api.com/heroes/lady_geist_sm.png',
    ),
    MockHero(
      id: 7,
      name: 'Lash',
      role: 'Initiator',
      imageUrl:
          'https://assets-bucket.deadlock-api.com/heroes/lash_sm.png',
    ),
    MockHero(
      id: 8,
      name: 'Seven',
      role: 'Carry',
      imageUrl:
          'https://assets-bucket.deadlock-api.com/heroes/seven_sm.png',
    ),
  ];

  static String descriptionFor(MockHero hero) =>
      '${hero.name} — ${hero.role}. Временное описание героя для экрана деталей. '
      'После подключения реальной модели OpenCode данные будут браться из API.';
}
