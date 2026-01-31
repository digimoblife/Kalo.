import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/features/logging/data/food_repository.dart';
import 'package:kalo_app/features/logging/presentation/create_food_page.dart';

class AddFoodPage extends ConsumerStatefulWidget {
  const AddFoodPage({super.key});

  @override
  ConsumerState<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends ConsumerState<AddFoodPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  // Fungsi pencarian dengan "Debounce"
  // (Nunggu user berhenti ngetik 500ms baru cari, biar gak spam API)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) return; // Minimal 3 huruf

      setState(() => _isLoading = true);
      final repo = ref.read(foodRepositoryProvider);
      final results = await repo.searchFood(query);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    });
  }

  // Munculkan Bottom Sheet untuk konfirmasi porsi
  void _showLogSheet(Map<String, dynamic> food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LogFoodSheet(food: food),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true, // Keyboard langsung muncul
          decoration: const InputDecoration(
            hintText: "Cari makanan (misal: Telur Rebus)",
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        // --- TAMBAHAN BARU ---
        actions: [
          IconButton(
            tooltip: "Input Manual",
            icon: const Icon(Icons.playlist_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateFoodPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(color: Colors.black),

          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey[300]),
                        const Gap(16),
                        Text(
                          "Ketik min. 3 huruf untuk mencari",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Gap(24),
                        // --- TOMBOL SHORTCUT ---
                        OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text("Input Manual"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateFoodPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final isExternal = item['is_external'] == true;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExternal
                              ? Colors.blue[50]
                              : Colors.green[50],
                          child: Icon(
                            isExternal ? Icons.cloud_outlined : Icons.storage,
                            color: isExternal ? Colors.blue : Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${item['calories']} kkal / 100g • P: ${item['protein']}g",
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => _showLogSheet(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET KECIL: FORM INPUT PORSI ---
class _LogFoodSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> food;
  const _LogFoodSheet({required this.food});

  @override
  ConsumerState<_LogFoodSheet> createState() => _LogFoodSheetState();
}

class _LogFoodSheetState extends ConsumerState<_LogFoodSheet> {
  String _selectedMeal = 'Lunch'; // Default
  double _portion = 1.0;
  bool _isSaving = false;

  Future<void> _saveLog() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(foodRepositoryProvider)
          .logFood(
            foodData: widget.food,
            mealType: _selectedMeal,
            portion: _portion,
          );
      if (mounted) {
        Navigator.pop(context); // Tutup Sheet
        Navigator.pop(context); // Tutup Search Page (Balik ke Home)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Makanan berhasil dicatat!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung estimasi kalori real-time saat slider digeser
    final baseCal = widget.food['calories'] as num;
    final totalCal = (baseCal * _portion).round();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 24, // Handle keyboard
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.food['name'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Gap(4),
          Text(
            "$totalCal kkal (Est.)",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const Gap(24),
          const Text(
            "Waktu Makan",
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

          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Porsi (x100g)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${_portion.toStringAsFixed(1)}x",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Slider(
            value: _portion,
            min: 0.1,
            max: 5.0,
            divisions: 49, // Biar stepnya 0.1
            activeColor: Colors.black,
            onChanged: (val) => setState(() => _portion = val),
          ),

          const Gap(24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text("Simpan ke Jurnal"),
          ),
        ],
      ),
    );
  }
}
