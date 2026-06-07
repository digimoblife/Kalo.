import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kalo_app/core/constants/app_strings.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('${AppStrings.loginFailed}${e.toString()}');
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
        },
      );
    } catch (e) {
      throw Exception('${AppStrings.registerFailed}${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
