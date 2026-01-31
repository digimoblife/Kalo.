import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

// Import halaman-halaman
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/auth/presentation/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables dari file .env
  await dotenv.load(fileName: ".env");

  // 2. Inisialisasi Supabase (Baca dari .env, bukan hardcode lagi)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalo.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        // Font default aplikasi
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
