import 'package:equatable/equatable.dart';

import '../../../domain/entities/hero_meta.dart';

abstract class HeroEvent extends Equatable {
  const HeroEvent();

  @override
  List<Object?> get props => [];
}

class HeroRequested extends HeroEvent {
  const HeroRequested(this.meta);

  final HeroMeta meta;

  @override
  List<Object?> get props => [meta];
}

class HeroRefreshRequested extends HeroEvent {
  const HeroRefreshRequested();
}
