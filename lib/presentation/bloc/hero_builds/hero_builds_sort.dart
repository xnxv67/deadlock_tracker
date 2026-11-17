enum HeroBuildsSort { popularity, winRate }

extension HeroBuildsSortLabel on HeroBuildsSort {
  String get label => switch (this) {
    HeroBuildsSort.popularity => 'Популярные',
    HeroBuildsSort.winRate => 'По винрейту',
  };
}
