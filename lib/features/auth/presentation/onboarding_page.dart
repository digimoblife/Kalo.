import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kalo_app/features/home/presentation/home_page.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _manualCalorieController =
      TextEditingController(); // Controller baru untuk input manual

  String _gender = 'Male';
  String _activityLevel = 'Sedentary';
  DateTime? _birthDate;
  bool _isLoading = false;

  // State untuk opsi manual
  bool _isManualTarget = false;

  // Rumus Mifflin-St Jeor
  int _calculateTDEE(int age) {
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double height = double.tryParse(_heightController.text) ?? 0;

    // 1. Hitung BMR
    double bmr;
    if (_gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // 2. Kalikan dengan Aktivitas
    double multiplier;
    switch (_activityLevel) {
      case 'Sedentary':
        multiplier = 1.2;
        break;
      case 'Light':
        multiplier = 1.375;
        break;
      case 'Moderate':
        multiplier = 1.55;
        break;
      case 'Active':
        multiplier = 1.725;
        break;
      default:
        multiplier = 1.2;
    }

    return (bmr * multiplier).round();
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate() || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi data fisik Anda')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Hitung Umur
    final age = DateTime.now().year - _birthDate!.year;

    // LOGIKA PENENTUAN TARGET KALORI
    int finalTargetCalorie;
    if (_isManualTarget) {
      // Jika manual, pakai inputan user
      finalTargetCalorie = int.parse(_manualCalorieController.text);
    } else {
      // Jika otomatis, pakai rumus
      finalTargetCalorie = _calculateTDEE(age);
    }

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'current_weight': double.parse(_weightController.text),
            'height': double.parse(_heightController.text),
            'birth_date': _birthDate!.toIso8601String(),
            'gender': _gender,
            'activity_level': _activityLevel,
            'daily_calorie_target': finalTargetCalorie, // Nilai final disimpan
            'current_streak': 0,
          })
          .eq('id', user.id);

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Isi Data Diri")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Data fisik tetap diperlukan untuk memantau progress Anda.",
              ),
              const Gap(24),

              // --- FORM DATA FISIK (Tetap Wajib) ---
              const Text(
                "Jenis Kelamin",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Pria"),
                      value: "Male",
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v.toString()),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Wanita"),
                      value: "Female",
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v.toString()),
                    ),
                  ),
                ],
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
                      validator: (v) => v!.isEmpty ? "Wajib isi" : null,
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
                      validator: (v) => v!.isEmpty ? "Wajib isi" : null,
                    ),
                  ),
                ],
              ),

              const Gap(24),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Tanggal Lahir",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _birthDate == null
                        ? "Pilih Tanggal"
                        : DateFormat('dd MMM yyyy').format(_birthDate!),
                  ),
                ),
              ),

              const Gap(24),
              DropdownButtonFormField<String>(
                value: _activityLevel,
                decoration: const InputDecoration(
                  labelText: "Aktivitas Fisik",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Sedentary',
                    child: Text("Jarang Olahraga"),
                  ),
                  DropdownMenuItem(
                    value: 'Light',
                    child: Text("Ringan (1-3x/minggu)"),
                  ),
                  DropdownMenuItem(
                    value: 'Moderate',
                    child: Text("Sedang (3-5x/minggu)"),
                  ),
                  DropdownMenuItem(
                    value: 'Active',
                    child: Text("Aktif (Tiap hari)"),
                  ),
                ],
                onChanged: (v) => setState(() => _activityLevel = v!),
              ),

              const Divider(height: 48, thickness: 1),

              // --- FITUR BARU: Opsi Target Manual ---
              SwitchListTile(
                title: const Text("Atur Target Kalori Sendiri?"),
                subtitle: const Text(
                  "Aktifkan jika Anda sudah punya angka target spesifik dari dokter/coach.",
                ),
                value: _isManualTarget,
                activeColor: Colors.black,
                onChanged: (val) {
                  setState(() {
                    _isManualTarget = val;
                  });
                },
              ),

              // Tampilkan Input Field HANYA jika Switch Aktif
              if (_isManualTarget)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextFormField(
                    controller: _manualCalorieController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Target Kalori Harian (Manual)",
                      border: OutlineInputBorder(),
                      suffixText: "kkal",
                      helperText: "Contoh: 1800",
                    ),
                    validator: (v) {
                      // Validasi: Wajib diisi JIKA mode manual aktif
                      if (_isManualTarget && (v == null || v.isEmpty)) {
                        return "Mohon isi target kalori Anda";
                      }
                      return null;
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Target kalori akan dihitung otomatis oleh sistem berdasarkan data fisik di atas.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

              const Gap(32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isManualTarget
                            ? "Simpan Target Manual"
                            : "Hitung & Simpan",
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
