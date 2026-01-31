import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Provider ini agar AuthRepository bisa dipanggil dari mana saja
final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // Cek apakah user sudah login sebelumnya
  User? get currentUser => _supabase.auth.currentUser;

  // Fungsi Login
  Future<void> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Gagal Login: ${e.toString()}');
    }
  }

  // Fungsi Register
  Future<void> register(String email, String password, String name) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
        }, // Data ini akan masuk ke tabel profiles otomatis (via Trigger SQL)
      );
    } catch (e) {
      throw Exception('Gagal Register: ${e.toString()}');
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
