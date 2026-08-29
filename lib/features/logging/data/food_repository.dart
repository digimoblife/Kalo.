import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final foodRepositoryProvider = Provider((ref) => FoodRepository());

class FoodRepository {
  final _supabase = Supabase.instance.client;

  // Fungsi Mencari Makanan (Local + External)
  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    if (query.isEmpty) return [];

    // 1. Cari di SUPABASE (Database Kita)
    // Menggunakan ilike untuk pencarian teks (case insensitive)
    final List<dynamic> localResults = await _supabase
        .from('foods')
        .select()
        .ilike('name', '%$query%')
        .limit(10); // Batasi 10 hasil lokal

    // 2. Cari di OPENFOODFACTS (API Luar)
    List<Map<String, dynamic>> externalResults = [];
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1&page_size=10',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List;

        // Mapping data API ke format standar kita
        externalResults = products.map((item) {
          return {
            'id': null, // Tandanya ini dari API (belum masuk DB kita)
            'name': item['product_name'] ?? 'Unknown Food',
            'calories': _parseNutrient(item, 'energy-kcal_100g'),
            'protein': _parseNutrient(item, 'proteins_100g'),
            'carbs': _parseNutrient(item, 'carbohydrates_100g'),
            'fats': _parseNutrient(item, 'fat_100g'),
            'serving_size': 100.0, // Default API biasanya per 100g
            'serving_unit': 'gram',
            'barcode': item['code'] ?? '',
            'is_external': true, // Flag khusus untuk UI
          };
        }).toList();
      }
    } catch (e) {
      // Jika internet mati/API error, abaikan saja (tetap return hasil lokal)
      debugPrint("API Error: $e");
    }

    // 3. GABUNGKAN HASIL (Lokal dulu, baru Eksternal)
    // Kita convert localResults ke List<Map> biar seragam
    final formattedLocal = localResults
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return [...formattedLocal, ...externalResults];
  }

  // Helper untuk parsing angka dari API yang kadang null/string
  num _parseNutrient(Map item, String key) {
    if (item['nutriments'] == null) return 0;
    var val = item['nutriments'][key];
    if (val == null) return 0;
    if (val is String) return num.tryParse(val) ?? 0;
    return val; // if int/double
  }

  // Fungsi Simpan Log Makanan
  Future<void> logFood({
    required Map<String, dynamic> foodData,
    required String mealType,
    required double portion,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // STEP A: Jika makanan dari API Eksternal (id == null),
    // Kita harus SIMPAN dulu ke tabel 'foods' kita (Caching/Crowdsource)
    int foodId;

    if (foodData['id'] == null || foodData['is_external'] == true) {
      // Hapus flag 'is_external' dan 'id' sebelum insert
      final newFood = Map<String, dynamic>.from(foodData);
      newFood.remove('id');
      newFood.remove('is_external');
      newFood['created_by'] = user.id; // Credit ke user yang nemu

      // --- PERBAIKAN DI SINI ---
      // API kadang kasih nilai desimal (24.9), tapi Database minta Integer.
      // Kita bulatkan dulu (round) sebelum disimpan.
      if (newFood['calories'] != null) {
        newFood['calories'] = (newFood['calories'] as num).round();
      }

      final inserted = await _supabase
          .from('foods')
          .insert(newFood)
          .select()
          .single();
      foodId = inserted['id'];
    } else {
      foodId = foodData['id'];
    }

    // STEP B: Hitung Total Kalori berdasarkan Porsi
    final baseCalories = foodData['calories'] as num;
    final totalCalories = (baseCalories * portion).round();
    final todayString = DateTime.now().toIso8601String().split('T')[0];

    // STEP C: Simpan ke 'food_logs'
    await _supabase.from('food_logs').insert({
      'user_id': user.id,
      'food_id': foodId,
      'log_date': todayString,
      'meal_type': mealType,
      'portion': portion,
      'total_calories': totalCalories,
    });

    // STEP D: Update Streak
    try {
      final profile = await _supabase
          .from('profiles')
          .select('current_streak, last_log_date')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        final int currentStreak = profile['current_streak'] ?? 0;
        final String? lastLogDateStr = profile['last_log_date']?.toString();

        if (lastLogDateStr != todayString) {
          final today = DateTime.now();
          final yesterday = today.subtract(const Duration(days: 1));
          final yesterdayStr = yesterday.toIso8601String().split('T')[0];

          int newStreak;
          if (lastLogDateStr == yesterdayStr) {
            newStreak = currentStreak + 1;
          } else {
            newStreak = 1;
          }

          await _supabase.from('profiles').update({
            'current_streak': newStreak,
            'last_log_date': todayString,
          }).eq('id', user.id);
        }
      }
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  // Fungsi Hapus Log Makanan
  Future<void> deleteLog(int logId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('food_logs')
        .delete()
        .eq('id', logId)
        .eq('user_id', user.id);
  }
}

