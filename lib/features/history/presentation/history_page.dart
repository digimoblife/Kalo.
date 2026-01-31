import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:kalo_app/features/history/data/history_repository.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  DateTime _selectedDate = DateTime.now();

  // Fungsi Ganti Tanggal
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024), // Batas bawah (misal saat app rilis)
      lastDate: DateTime.now(), // Tidak bisa lihat masa depan
      builder: (context, child) {
        // Kustomisasi warna DatePicker agar sesuai tema Gen Z Black
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data berdasarkan tanggal yang dipilih (_selectedDate)
    final historyAsync = ref.watch(historyDateProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Makan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. DATE NAVIGATOR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                    () => _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    ),
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Disable tombol kanan jika hari ini
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedDate.day == DateTime.now().day
                      ? null
                      : () => setState(
                          () => _selectedDate = _selectedDate.add(
                            const Duration(days: 1),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // --- 2. BODY CONTENT ---
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (data) {
                final logs = data['logs'] as List;
                final summary = data['summary'] as Map<String, dynamic>;

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const Gap(16),
                        Text(
                          "Tidak ada data pada tanggal ini.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // A. MACRO SUMMARY CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MacroItem(
                            label: "Kalori",
                            value: "${summary['calories']}",
                            unit: "kkal",
                            isMain: true,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[800],
                          ),
                          _MacroItem(
                            label: "Protein",
                            value: "${summary['protein']}",
                            unit: "g",
                          ),
                          _MacroItem(
                            label: "Carbs",
                            value: "${summary['carbs']}",
                            unit: "g",
                          ),
                          _MacroItem(
                            label: "Fat",
                            value: "${summary['fat']}",
                            unit: "g",
                          ),
                        ],
                      ),
                    ),

                    const Gap(24),
                    const Text(
                      "Detail Makanan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Gap(12),

                    // B. LIST MAKANAN
                    ...logs.map((log) {
                      final food = log['foods'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            // Jam Makan (Ambil dari created_at)
                            Text(
                              DateFormat('HH:mm').format(
                                DateTime.parse(log['created_at']).toLocal(),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${log['portion']}x Porsi • ${log['meal_type']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${log['total_calories']} kkal",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Kecil untuk Macro (Putih di atas Hitam)
class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isMain;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.unit,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const Gap(4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMain ? 24 : 18,
                color: Colors.white,
              ),
            ),
            const Gap(2),
            Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ],
        ),
      ],
    );
  }
}
