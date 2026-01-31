import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/features/auth/data/auth_repository.dart';
import 'package:kalo_app/features/home/presentation/home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Hanya muncul saat Register

  bool _isRegistering = false; // Toggle antara Login/Register
  bool _isLoading = false;

  // Fungsi submit form
  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);

    try {
      if (_isRegistering) {
        // Mode Register
        await authRepo.register(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akun berhasil dibuat! Silahkan login.'),
            ),
          );
          setState(() => _isRegistering = false); // Balik ke mode login
        }
      } else {
        // Mode Login
        await authRepo.login(_emailController.text, _passwordController.text);
        // Jika sukses, pindah ke Home (akan dihandle di main.dart, tapi ini backup)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Logo
              Text(
                "Kalo.",
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                _isRegistering
                    ? "Buat akun baru, yuk!"
                    : "Halo, selamat datang!",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const Gap(40),

              // 2. Input Fields
              if (_isRegistering) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const Gap(16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const Gap(16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const Gap(24),

              // 3. Action Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isRegistering ? "Daftar Sekarang" : "Masuk"),
              ),
              const Gap(16),

              // 4. Toggle Button
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                  });
                },
                child: Text(
                  _isRegistering
                      ? "Sudah punya akun? Login"
                      : "Belum punya akun? Daftar",
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
