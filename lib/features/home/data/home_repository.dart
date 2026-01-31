import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider agar bisa dipanggil di UI
final homeRepositoryProvider = Provider((ref) => HomeRepository());

// Provider untuk mengambil data Dashboard secara real-time (Future)
final dashboardDataProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getDashboardData();
});

class HomeRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getDashboardData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // 1. Ambil Data Profile (Target Kalori & Streak)
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    // 2. Ambil Log Makanan HARI INI
    final today = DateTime.now().toIso8601String().split(
      'T',
    )[0]; // Format YYYY-MM-DD
    final logs = await _supabase
        .from('food_logs')
        .select(
          '*, foods(*)',
        ) // Join dengan tabel foods biar dapet nama makanan
        .eq('user_id', user.id)
        .eq('log_date', today);

    // 3. Hitung Total Kalori yang sudah dimakan
    int totalConsumed = 0;
    for (var log in logs) {
      totalConsumed += (log['total_calories'] as num).toInt();
    }

    return {'profile': profile, 'logs': logs, 'totalConsumed': totalConsumed};
  }
}
