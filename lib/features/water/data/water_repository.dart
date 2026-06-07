import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final waterRepositoryProvider = Provider((ref) => WaterRepository());

class WaterRepository {
  final _supabase = Supabase.instance.client;

  Future<int> getTodayWater() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final logs = await _supabase
        .from('water_logs')
        .select('amount_ml')
        .eq('user_id', user.id)
        .eq('log_date', today);

    return logs.fold<int>(0, (sum, log) => sum + (log['amount_ml'] as int));
  }

  Future<int> getWaterTarget() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 2000;
    final profile = await _supabase
        .from('profiles')
        .select('water_target_ml')
        .eq('id', user.id)
        .single();
    return profile['water_target_ml'] ?? 2000;
  }

  Future<void> addWater(int amountMl) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];
    await _supabase.from('water_logs').insert({
      'user_id': user.id,
      'log_date': today,
      'amount_ml': amountMl,
    });
  }

  Future<void> setTarget(int targetMl) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase
        .from('profiles')
        .update({'water_target_ml': targetMl})
        .eq('id', user.id);
  }
}