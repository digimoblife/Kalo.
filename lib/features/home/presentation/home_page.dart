import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/core/constants/app_strings.dart';
import 'package:kalo_app/features/home/data/home_repository.dart';
import 'package:kalo_app/features/logging/data/food_repository.dart';
import 'package:kalo_app/features/logging/presentation/add_food_page.dart';
import 'package:kalo_app/features/history/presentation/history_page.dart';
import 'package:kalo_app/features/profile/presentation/profile_page.dart';
import 'package:kalo_app/core/services/streak_service.dart';
import 'package:kalo_app/features/home/presentation/widgets/streak_milestone_dialog.dart';
import 'package:kalo_app/features/home/presentation/widgets/weekly_insights_card.dart';
import 'package:kalo_app/features/home/presentation/widgets/water_progress_ring.dart';
import 'package:kalo_app/features/home/presentation/widgets/macro_progress_rings.dart';
import 'package:kalo_app/features/recap/presentation/monthly_recap_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _milestoneChecked = false;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.history_edu),
          tooltip: AppStrings.historyTooltip,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
          },
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.appTitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              AppStrings.dashboard,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 20,
                ),
                const Gap(4),
                dashboardAsync.when(
                  data: (data) => Text(
                    "${data['profile']['current_streak']} ${AppStrings.day}",
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
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            tooltip: AppStrings.myProfile,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              ref.invalidate(dashboardDataProvider);
            },
          ),
        ],
      ),

      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${AppStrings.error}$err')),
        data: (data) {
          final int target = data['profile']['daily_calorie_target'] ?? 2000;
          final int consumed = data['totalConsumed'];
          final double progress = (consumed / target).clamp(0.0, 1.0);

          final int proteinTarget = data['profile']['protein_target_gram'] ?? 150;
          final int carbsTarget = data['profile']['carbs_target_gram'] ?? 200;
          final int fatsTarget = data['profile']['fats_target_gram'] ?? 67;
          final int totalProtein = data['totalProtein'] ?? 0;
          final int totalCarbs = data['totalCarbs'] ?? 0;
          final int totalFats = data['totalFats'] ?? 0;

          final int currentStreak = data['profile']['current_streak'] ?? 0;
          if (!_milestoneChecked) {
            _milestoneChecked = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final milestone = await StreakService.checkMilestone(currentStreak);
              if (milestone != null && context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => StreakMilestoneDialog(
                    milestone: milestone,
                    onDismiss: () async {
                      Navigator.pop(context);
                      await StreakService.markCelebrated(milestone);
                    },
                  ),
                );
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardDataProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 15,
                          color: Colors.grey[200],
                        ),
                      ),
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
                            "${AppStrings.of} $target ${AppStrings.kcal}",
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

                  MacroProgressRings(
                    proteinCurrent: totalProtein,
                    proteinTarget: proteinTarget,
                    carbsCurrent: totalCarbs,
                    carbsTarget: carbsTarget,
                    fatsCurrent: totalFats,
                    fatsTarget: fatsTarget,
                  ),

                  const Gap(24),

                  WaterProgressRing(),

                  const Gap(24),

                  WeeklyInsightsCard(),

                  const Gap(24),

                  // Monthly Recap Banner
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MonthlyRecapPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6B9E6B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B9E6B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF6B9E6B),
                              size: 22,
                            ),
                          ),
                          const Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppStrings.monthlyRecap,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  AppStrings.recapSubtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Gap(24),

                  if ((data['logs'] as List).isEmpty) ...[
                    Column(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const Gap(16),
                        const Text(AppStrings.noFoodToday),
                        Text(
                          AppStrings.startTracking,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.foodLog,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "${(data['logs'] as List).length} ${AppStrings.items}",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const Gap(16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (data['logs'] as List).length,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (context, index) {
                        final log = (data['logs'] as List)[index];
                        final food = log['foods'];

                        return Dismissible(
                          key: ValueKey(log['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            await ref
                                .read(foodRepositoryProvider)
                                .deleteLog(log['id']);
                            ref.invalidate(dashboardDataProvider);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
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
                                        "${log['meal_type']} • ${log['portion']}x ${AppStrings.portion}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  "${log['total_calories']} ${AppStrings.kcal}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const Gap(80),
                  ],
                ],
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFoodPage()),
          );
          ref.invalidate(dashboardDataProvider);
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.logFood),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

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

