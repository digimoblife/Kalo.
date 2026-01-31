import 'dart:convert';
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
      print("API Error: $e");
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
    // Rumus: (Kalori Makanan / Serving Size Reference) * Porsi Input
    // Asumsi sederhana MVP: Porsi input adalah Multiplier dari Serving Size
    // Misal: Database 100g (100kkal). User makan 1.5 porsi (150g) -> 150kkal.
    final baseCalories = foodData['calories'] as num;
    final totalCalories = (baseCalories * portion).round();

    // STEP C: Simpan ke 'food_logs'
    await _supabase.from('food_logs').insert({
      'user_id': user.id,
      'food_id': foodId,
      'log_date': DateTime.now().toIso8601String(),
      'meal_type': mealType,
      'portion': portion,
      'total_calories': totalCalories,
    });
  }
}
