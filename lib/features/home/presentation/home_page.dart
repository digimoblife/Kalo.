import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/features/home/data/home_repository.dart';
import 'package:kalo_app/features/auth/data/auth_repository.dart';
import 'package:kalo_app/features/logging/presentation/add_food_page.dart';
import 'package:kalo_app/features/history/presentation/history_page.dart'; // Import Halaman History
import 'package:kalo_app/features/profile/presentation/profile_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mengambil data dari Repository (Real-time)
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: Colors.white, // Clean Look
      // --- APP BAR (Header) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // 1. TOMBOL HISTORY (Kiri)
        leading: IconButton(
          icon: const Icon(Icons.history_edu),
          tooltip: "Riwayat",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
          },
        ),

        // 2. JUDUL TENGAH
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kalo.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const Text(
              "Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),

        // 3. STREAK & LOGOUT (Kanan)
        actions: [
          // Widget Streak
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 20,
                ),
                const Gap(4),
                // Tampilkan Streak dari Database
                dashboardAsync.when(
                  data: (data) => Text(
                    "${data['profile']['current_streak']} Hari",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  error: (_, __) => const Text("-"),
                  loading: () => const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ),
          ),
          // Tombol Profil
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            tooltip: "Profil Saya",
            onPressed: () async {
              // Buka halaman profil
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              // Refresh dashboard saat kembali (siapa tahu user ganti target kalori)
              ref.refresh(dashboardDataProvider);
            },
          ),
        ],
      ),

      // --- BODY ---
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final int target = data['profile']['daily_calorie_target'] ?? 2000;
          final int consumed = data['totalConsumed'];
          final double progress = (consumed / target).clamp(0.0, 1.0);
          final int remaining = target - consumed;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardDataProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // A. HERO SECTION (Progress Ring)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lingkaran Background
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 15,
                          color: Colors.grey[200],
                        ),
                      ),
                      // Lingkaran Progress Utama
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 15,
                          color: Colors.black,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Teks di Tengah
                      Column(
                        children: [
                          Text(
                            "$consumed",
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          Text(
                            "dari $target kkal",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Gap(32),

                  // B. SUMMARY CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          title: "Sisa",
                          value: "$remaining",
                          unit: "kkal",
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _SummaryItem(
                          title: "Protein",
                          value: "0",
                          unit: "g",
                        ), // Placeholder (Hitungan ada di History)
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _SummaryItem(title: "Carbs", value: "0", unit: "g"),
                      ],
                    ),
                  ),

                  const Gap(32),

                  // C. LIST MAKANAN (LOGS)
                  if ((data['logs'] as List).isEmpty) ...[
                    // Tampilan Kosong (Empty State)
                    Column(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const Gap(16),
                        const Text("Belum ada makanan tercatat hari ini."),
                        const Text(
                          "Yuk mulai tracking!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Header List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Riwayat Makan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "${(data['logs'] as List).length} item",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const Gap(16),

                    // List Item Makanan
                    ListView.separated(
                      shrinkWrap:
                          true, // Wajib agar tidak error di dalam SingleChildScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // Scroll ikut induknya
                      itemCount: (data['logs'] as List).length,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (context, index) {
                        final log = (data['logs'] as List)[index];
                        final food = log['foods'];

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon berdasarkan Meal Type
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getMealIcon(log['meal_type']),
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                              const Gap(16),

                              // Nama & Porsi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${log['meal_type']} • ${log['portion']}x Porsi",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Total Kalori Item Ini
                              Text(
                                "${log['total_calories']} kkal",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Gap(
                      80,
                    ), // Jarak ekstra di bawah agar tidak tertutup tombol FAB
                  ],
                ],
              ),
            ),
          );
        },
      ),

      // --- FAB (Tombol Tambah) ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 1. Tunggu user kembali dari halaman AddFoodPage
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFoodPage()),
          );
          // 2. Refresh data dashboard agar update
          ref.refresh(dashboardDataProvider);
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Catat Makan"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Widget Kecil untuk Summary
class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const Gap(4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

// Helper Function untuk Icon
IconData _getMealIcon(String type) {
  switch (type) {
    case 'Breakfast':
      return Icons.wb_sunny_outlined;
    case 'Lunch':
      return Icons.restaurant;
    case 'Dinner':
      return Icons.nights_stay_outlined;
    case 'Snack':
      return Icons.coffee;
    default:
      return Icons.fastfood;
  }
}
