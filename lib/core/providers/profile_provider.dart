import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  final data = await Supabase.instance.client
      .from('profiles')
      .select('daily_calorie_target, protein_target_gram, carbs_target_gram, fats_target_gram, water_target_ml, current_streak, current_weight, height')
      .eq('id', user!.id)
      .single();
  return data;
});
