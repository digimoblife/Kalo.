import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:kalo_app/core/constants/app_strings.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository());

final historyDateProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, dateString) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getHistoryByDateString(dateString);
});

class HistoryRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getHistoryByDate(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return getHistoryByDateString(dateString);
  }

  Future<Map<String, dynamic>> getHistoryByDateString(String dateString) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception(AppStrings.notLoggedIn);

    final logs = await _supabase
        .from('food_logs')
        .select('id, total_calories, portion, meal_type, created_at, foods(name, protein, carbs, fats)')
        .eq('user_id', user.id)
        .eq('log_date', dateString)
        .order('created_at', ascending: true);

    int totalCals = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var log in logs) {
      final food = log['foods'] as Map<String, dynamic>?;
      final portion = (log['portion'] as num).toDouble();

      totalCals += (log['total_calories'] as num).toInt();

      totalProtein += ((food?['protein'] ?? 0) * portion);
      totalCarbs += ((food?['carbs'] ?? 0) * portion);
      totalFat += ((food?['fats'] ?? 0) * portion);
    }

    return {
      'logs': logs,
      'summary': {
        'calories': totalCals,
        'protein': totalProtein.round(),
        'carbs': totalCarbs.round(),
        'fat': totalFat.round(),
      },
    };
  }
}

