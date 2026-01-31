import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/features/logging/data/food_repository.dart';

class CreateFoodPage extends ConsumerStatefulWidget {
  const CreateFoodPage({super.key});

  @override
  ConsumerState<CreateFoodPage> createState() => _CreateFoodPageState();
}

class _CreateFoodPageState extends ConsumerState<CreateFoodPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  final _unitController = TextEditingController(
    text: 'Porsi',
  ); // Default: Porsi

  bool _isSaving = false;
  String _selectedMeal = 'Lunch'; // Default waktu makan

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Siapkan Data Makanan Baru
      final newFoodData = {
        'id': null, // null menandakan ini makanan BARU (belum ada di DB)
        'name': _nameController.text,
        'calories': int.parse(_calController.text),
        'protein': double.tryParse(_proteinController.text) ?? 0,
        'carbs': double.tryParse(_carbsController.text) ?? 0,
        'fats': double.tryParse(_fatController.text) ?? 0,
        'serving_size': 1.0, // Kita anggap inputan user adalah untuk "1 Porsi"
        'serving_unit': _unitController.text,
        'is_external': false,
      };

      // 2. Panggil Repository untuk Simpan & Log
      // Logika di repository kita sudah pintar:
      // Jika id=null, dia akan INSERT ke tabel 'foods' dulu, baru INSERT ke 'food_logs'
      await ref
          .read(foodRepositoryProvider)
          .logFood(
            foodData: newFoodData,
            mealType: _selectedMeal,
            portion: 1.0, // Default 1 porsi saat create
          );

      if (mounted) {
        // Sukses! Tutup halaman ini & halaman search, kembali ke Dashboard
        Navigator.pop(context); // Tutup CreatePage
        Navigator.pop(context); // Tutup AddFoodPage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Makanan berhasil dibuat & dicatat!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Makanan Manual")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Data ini akan disimpan ke database publik agar bisa dipakai orang lain.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Gap(24),

              // NAMA MAKANAN
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Makanan *",
                  hintText: "Contoh: Nasi Goreng Spesial",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood),
                ),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const Gap(16),

              // KALORI & UNIT
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _calController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Kalori (kkal) *",
                        border: OutlineInputBorder(),
                        suffixText: "kkal",
                      ),
                      validator: (v) => v!.isEmpty ? "Wajib" : null,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: "Satuan",
                        hintText: "Porsi/Mangkok",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(24),

              const Text(
                "Makronutrisi (Opsional)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              Row(
                children: [
                  Expanded(
                    child: _MacroInput(
                      label: "Protein",
                      controller: _proteinController,
                      color: Colors.green,
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _MacroInput(
                      label: "Carbs",
                      controller: _carbsController,
                      color: Colors.orange,
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _MacroInput(
                      label: "Fat",
                      controller: _fatController,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const Gap(32),
              const Text(
                "Dimakan saat?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((meal) {
                  final isSelected = _selectedMeal == meal;
                  return ChoiceChip(
                    label: Text(meal),
                    selected: isSelected,
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (val) => setState(() => _selectedMeal = meal),
                  );
                }).toList(),
              ),

              const Gap(40),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan & Catat"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Kecil untuk Input Makro
class _MacroInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;

  const _MacroInput({
    required this.label,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: "g",
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }
}
