import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_strings.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/auth/presentation/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://raygnspffroqtgcxcuma.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJheWduc3BmZnJvcXRnY3hjdW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4MzU3NTksImV4cCI6MjA4NTQxMTc1OX0._LTUsTayw3LNFAuB1v937NWiOrtqZ7IuVynqQUNhFck',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        fontFamily: 'GoogleFonts.poppins',
      ),
      home: const AuthGate(),
    );
  }
}

// Widget Penjaga Pintu (Auth Gate)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder mendengarkan status login Supabase secara live
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // KONDISI 1: Belum Login -> Tampilkan Login Page
        if (session == null) {
          return const LoginPage();
        }

        // KONDISI 2: Sudah Login -> Cek apakah User Baru? (Cek data 'height')
        return FutureBuilder(
          future: Supabase.instance.client
              .from('profiles')
              .select('height') // Kita cek kolom height
              .eq('id', session.user.id)
              .single(),
          builder: (context, profileSnapshot) {
            // Tampilkan loading saat mengecek database
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              );
            }

            // Handle jika terjadi error koneksi saat ambil profil
            if (profileSnapshot.hasError) {
              // Opsional: Bisa return Text("Error: ${profileSnapshot.error}") untuk debug
              // Tapi untuk user, kita anggap saja belum onbarding atau tetap ke Home
              // Disini kita asumsi ke Onboarding dulu biar aman
              return const OnboardingPage();
            }

            final data = profileSnapshot.data;

            // Logika: Jika 'height' kosong/null, berarti user belum isi Onboarding
            if (data == null || data['height'] == null) {
              return const OnboardingPage();
            }

            // KONDISI 3: Login Sukses & Data Lengkap -> Masuk Dashboard
            return const HomePage();
          },
        );
      },
    );
  }
}
