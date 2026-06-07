import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalo_app/core/providers/profile_provider.dart';
import 'package:kalo_app/features/water/data/water_repository.dart';

final waterDataProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(waterRepositoryProvider);

  final results = await Future.wait([
    repo.getTodayWater(),
    ref.watch(profileProvider.future).then((p) => p['water_target_ml'] as int? ?? 2000),
  ]);

  return {'current': results[0], 'target': results[1]};
});

final waterTargetProvider = FutureProvider.autoDispose<int>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  return profile['water_target_ml'] as int? ?? 2000;
});