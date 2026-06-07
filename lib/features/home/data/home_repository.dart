import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kalo_app/core/constants/app_strings.dart';

final homeRepositoryProvider = Provider((ref) => HomeRepository());

final dashboardDataProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getDashboardData();
});

class HomeRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getDashboardData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception(AppStrings.notLoggedIn);

    final today = DateTime.now().toIso8601String().split('T')[0];

    final Map<String, dynamic> profile = await _supabase
        .from('profiles')
        .select('daily_calorie_target, protein_target_gram, carbs_target_gram, fats_target_gram, current_streak')
        .eq('id', user.id)
        .single();

    final List<dynamic> logs = await _supabase
        .from('food_logs')
        .select('total_calories, portion, meal_type, foods(name, protein, carbs, fats)')
        .eq('user_id', user.id)
        .eq('log_date', today);

    int totalConsumed = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (var log in logs) {
      totalConsumed += (log['total_calories'] as num).toInt();
      final food = log['foods'] as Map<String, dynamic>?;
      final portion = (log['portion'] as num).toDouble();
      totalProtein += ((food?['protein'] ?? 0) * portion);
      totalCarbs += ((food?['carbs'] ?? 0) * portion);
      totalFats += ((food?['fats'] ?? 0) * portion);
    }

    return {
      'profile': profile,
      'logs': logs,
      'totalConsumed': totalConsumed,
      'totalProtein': totalProtein.round(),
      'totalCarbs': totalCarbs.round(),
      'totalFats': totalFats.round(),
    };
  }
}
