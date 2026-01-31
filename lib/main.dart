import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';
import 'package:kalo_app/features/auth/presentation/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
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
        fontFamily: 'GoogleFonts.poppins', // Default font (opsional)
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
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // 1. Belum Login -> Login Page
        if (session == null) {
          return const LoginPage();
        }

        // 2. Sudah Login -> Cek Database
        return FutureBuilder(
          // KITA UBAH SELECT QUERY-NYA:
          // Kita ambil 'height' untuk memastikan user sudah isi data fisik atau belum
          future: Supabase.instance.client
              .from('profiles')
              .select('height')
              .eq('id', session.user.id)
              .single(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = profileSnapshot.data;

            // LOGIKA BARU:
            // Cek apakah 'height' masih kosong?
            // Jika ya, berarti belum onboarding -> Lempar ke OnboardingPage
            if (data == null || data['height'] == null) {
              return const OnboardingPage();
            }

            // Jika tinggi badan sudah ada -> Masuk Home
            return const HomePage();
          },
        );
      },
    );
  }
}
