import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kalo_app/features/auth/data/auth_repository.dart';
import 'package:kalo_app/features/auth/presentation/login_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _manualCalController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isManualTarget = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    setState(() {
      _weightController.text = data['current_weight']
          .toString(); // Perhatikan nama kolom ini
      _heightController.text = data['height'].toString();

      // Deteksi apakah user pakai target manual?
      // Logika sederhana: Kita anggap manual jika user mencentang opsi manual nanti.
      // Untuk load awal, kita set default false dulu, atau baca dari kolom khusus jika ada.
      // Di MVP ini kita biarkan user set ulang.
      _manualCalController.text = data['daily_calorie_target'].toString();

      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      int newTarget;

      if (_isManualTarget) {
        newTarget = int.parse(_manualCalController.text);
      } else {
        // Hitung ulang BMR otomatis (Logika sederhana Mifflin-St Jeor)
        // Kita perlu data umur & gender, tapi untuk mempersingkat di halaman ini,
        // kita ambil data lama user dari DB atau hitung kasar.
        // AGAR AMAN: Kita pakai target yang sedang diedit di text field saja
        // Asumsi: User kalau mau auto, dia harusnya balik ke Onboarding,
        // tapi di Profile Page biasanya user edit manual.
        newTarget = int.parse(_manualCalController.text);
      }

      await Supabase.instance.client
          .from('profiles')
          .update({
            'current_weight': double.parse(_weightController.text),
            'height': double.parse(_heightController.text),
            'daily_calorie_target': newTarget,
          })
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diupdate!")),
        );
        Navigator.pop(context); // Kembali ke Home
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // AVATAR
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const Gap(16),
                  Text(
                    user?.email ?? "User",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const Gap(32),

                  // FORM EDIT
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Data Fisik",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Berat (kg)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Tinggi (cm)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Gap(24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Target Kalori",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Gap(8),
                  TextFormField(
                    controller: _manualCalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Target Harian (kkal)",
                      border: OutlineInputBorder(),
                      helperText: "Ubah angka ini sesuai keinginanmu",
                    ),
                  ),

                  const Gap(40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Simpan Perubahan"),
                    ),
                  ),

                  const Gap(24),
                  const Divider(),
                  const Gap(24),

                  // TOMBOL LOGOUT
                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).logout();
                      if (mounted) {
                        // Paksa pindah ke Login Page & Hapus semua history navigasi
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      "Keluar Akun",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
