import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final insightsRepositoryProvider = Provider((ref) => InsightsRepository());

class InsightsRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getWeeklyInsights() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final sevenDaysAgo = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 6)));

    final List<dynamic> logs = await _supabase
        .from('food_logs')
        .select('total_calories, portion, log_date, foods(name, protein, carbs, fats)')
        .eq('user_id', user.id)
        .gte('log_date', sevenDaysAgo)
        .order('log_date', ascending: true);

    final Map<String, dynamic> profile = await _supabase
        .from('profiles')
        .select('daily_calorie_target')
        .eq('id', user.id)
        .single();
    final target = profile['daily_calorie_target'] ?? 2000;

    final Map<String, List<dynamic>> byDate = {};
    for (final log in logs) {
      final date = log['log_date'] as String;
      byDate.putIfAbsent(date, () => []).add(log);
    }

    int daysLogged = byDate.length;
    int totalCals = 0;
    double totalP = 0, totalC = 0, totalF = 0;
    Map<String, int> foodFrequency = {};

    for (final dayLogs in byDate.values) {
      for (final log in dayLogs) {
        totalCals += (log['total_calories'] as num).toInt();
        final food = log['foods'] as Map<String, dynamic>?;
        final portion = (log['portion'] as num).toDouble();
        totalP += ((food?['protein'] ?? 0) * portion);
        totalC += ((food?['carbs'] ?? 0) * portion);
        totalF += ((food?['fats'] ?? 0) * portion);
        if (food?['name'] != null) {
          foodFrequency[food!['name']] = (foodFrequency[food['name']] ?? 0) + 1;
        }
      }
    }

    final avgCals = daysLogged > 0 ? totalCals / daysLogged : 0;
    final calorieDiff = target > 0 ? ((avgCals - target) / target * 100).round() : 0;
    final topFood = foodFrequency.entries.isNotEmpty
        ? foodFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : '—';

    return {
      'daysLogged': daysLogged,
      'avgCalories': avgCals.round(),
      'target': target,
      'calorieDiff': calorieDiff,
      'avgProtein': daysLogged > 0 ? (totalP / daysLogged).round() : 0,
      'avgCarbs': daysLogged > 0 ? (totalC / daysLogged).round() : 0,
      'avgFats': daysLogged > 0 ? (totalF / daysLogged).round() : 0,
      'topFood': topFood,
    };
  }
}