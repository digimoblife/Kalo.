import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository());

// Provider ini menerima parameter Tanggal (Family Provider)
final historyDateProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
      final repo = ref.watch(historyRepositoryProvider);
      return repo.getHistoryByDate(date);
    });

class HistoryRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getHistoryByDate(DateTime date) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Format DateTime ke String 'YYYY-MM-DD' untuk query database
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    // 1. Ambil Log Makanan pada tanggal tersebut
    final logs = await _supabase
        .from('food_logs')
        .select('*, foods(*)') // Join tabel foods
        .eq('user_id', user.id)
        .eq('log_date', dateString)
        .order('created_at', ascending: true); // Urutkan dari pagi ke malam

    // 2. Hitung Total Nutrisi (Looping manual)
    int totalCals = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var log in logs) {
      final food = log['foods'];
      final portion = (log['portion'] as num).toDouble();

      // Kalori sudah dihitung saat insert, jadi tinggal jumlah
      totalCals += (log['total_calories'] as num).toInt();

      // Makro harus dihitung: (Kandungan per 100g * Porsi)
      // Gunakan operator ?? 0 agar tidak error jika data kosong
      totalProtein += ((food['protein'] ?? 0) * portion);
      totalCarbs += ((food['carbs'] ?? 0) * portion);
      totalFat += ((food['fats'] ?? 0) * portion);
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
