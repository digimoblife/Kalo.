import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kalo_app/core/constants/app_strings.dart';

final recapRepositoryProvider = Provider((ref) => RecapRepository());

final monthlyRecapProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, DateTime>((ref, monthDate) async {
  final repo = ref.watch(recapRepositoryProvider);
  return repo.getMonthlyRecap(monthDate.year, monthDate.month);
});

class RecapRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getMonthlyRecap(int year, int month) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception(AppStrings.notLoggedIn);

    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final startDateStr = DateFormat('yyyy-MM-dd').format(firstDay);
    final endDateStr = DateFormat('yyyy-MM-dd').format(lastDay);

    // Fetch food logs for the month
    final List<dynamic> foodLogs = await _supabase
        .from('food_logs')
        .select('total_calories, portion, meal_type, log_date, foods(name, protein, carbs, fats)')
        .eq('user_id', user.id)
        .gte('log_date', startDateStr)
        .lte('log_date', endDateStr)
        .order('log_date', ascending: true);

    // Fetch water logs for the month
    final List<dynamic> waterLogs = await _supabase
        .from('water_logs')
        .select('amount_ml, log_date')
        .eq('user_id', user.id)
        .gte('log_date', startDateStr)
        .lte('log_date', endDateStr);

    // Fetch profile
    final Map<String, dynamic> profile = await _supabase
        .from('profiles')
        .select('current_streak, daily_calorie_target, water_target_ml')
        .eq('id', user.id)
        .single();

    final Set<String> loggedDates = {};
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    final Map<String, int> foodFrequency = {};

    for (final log in foodLogs) {
      final date = log['log_date'].toString().split('T')[0];
      loggedDates.add(date);

      final cals = (log['total_calories'] as num).toInt();
      totalCalories += cals;

      final food = log['foods'] as Map<String, dynamic>?;
      final portion = (log['portion'] as num).toDouble();

      if (food != null) {
        totalProtein += ((food['protein'] ?? 0) * portion);
        totalCarbs += ((food['carbs'] ?? 0) * portion);
        totalFat += ((food['fats'] ?? 0) * portion);

        final name = food['name'] as String?;
        if (name != null && name.isNotEmpty) {
          foodFrequency[name] = (foodFrequency[name] ?? 0) + 1;
        }
      }
    }

    int totalWaterMl = 0;
    for (final log in waterLogs) {
      totalWaterMl += (log['amount_ml'] as num).toInt();
    }

    final int daysLogged = loggedDates.length;
    final int avgCalories = daysLogged > 0 ? (totalCalories / daysLogged).round() : 0;
    final double avgWaterLiters = daysLogged > 0 ? (totalWaterMl / 1000.0 / daysLogged) : 0.0;

    final String topFood = foodFrequency.entries.isNotEmpty
        ? foodFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : '—';

    // Calculate best streak in the month
    final sortedDates = loggedDates.map((d) => DateTime.parse(d)).toList()..sort();
    int bestStreak = 0;
    int tempStreak = 0;
    DateTime? prevDate;

    for (final date in sortedDates) {
      if (prevDate == null) {
        tempStreak = 1;
      } else if (date.difference(prevDate).inDays == 1) {
        tempStreak++;
      } else {
        tempStreak = 1;
      }
      if (tempStreak > bestStreak) {
        bestStreak = tempStreak;
      }
      prevDate = date;
    }

    final currentStreak = profile['current_streak'] ?? 0;
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    final monthName = DateFormat('MMMM yyyy').format(firstDay);

    return {
      'monthName': monthName,
      'daysLogged': daysLogged,
      'daysInMonth': lastDay.day,
      'totalMeals': foodLogs.length,
      'avgCalories': avgCalories,
      'avgWaterLiters': avgWaterLiters,
      'topFood': topFood,
      'bestStreak': bestStreak,
      'totalProtein': totalProtein.round(),
      'totalCarbs': totalCarbs.round(),
      'totalFat': totalFat.round(),
      'targetCalories': profile['daily_calorie_target'] ?? 2000,
    };
  }
}
