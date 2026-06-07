import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/core/constants/app_strings.dart';
import 'package:kalo_app/features/home/data/insights_repository.dart';

class WeeklyInsightsCard extends ConsumerWidget {
  const WeeklyInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(weeklyInsightsProvider);

    return insightsAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final daysLogged = data['daysLogged'] as int;
        final avgCalories = data['avgCalories'] as int;
        final target = data['target'] as int;
        final calorieDiff = data['calorieDiff'] as int;
        final avgProtein = data['avgProtein'] as int;
        final avgCarbs = data['avgCarbs'] as int;
        final avgFats = data['avgFats'] as int;
        final topFood = data['topFood'] as String;

        final isOver = calorieDiff > 0;
        final diffColor = isOver ? Colors.red : Colors.green;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.weeklyInsights,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${isOver ? '+' : ''}$calorieDiff% vs target',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: diffColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),

              Row(
                children: [
                  Expanded(
                    child: _InsightItem(
                      label: AppStrings.avgCalories,
                      value: '$avgCalories',
                      unit: AppStrings.kcal,
                      subtitle: 'Target: $target',
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  Expanded(
                    child: _InsightItem(
                      label: AppStrings.consistency,
                      value: '$daysLogged',
                      unit: '/ 7 days',
                      subtitle: '${(daysLogged / 7 * 100).round()}%',
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  Expanded(
                    child: _InsightItem(
                      label: AppStrings.topFood,
                      value: topFood,
                      unit: '',
                      subtitle: 'Most logged',
                    ),
                  ),
                ],
              ),

              const Gap(16),

              Row(
                children: [
                  Expanded(
                    child: _MacroAvgItem(
                      label: AppStrings.protein,
                      value: avgProtein,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _MacroAvgItem(
                      label: AppStrings.carbs,
                      value: avgCarbs,
                      color: Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _MacroAvgItem(
                      label: AppStrings.fat,
                      value: avgFats,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String subtitle;

  const _InsightItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const Gap(4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            if (unit.isNotEmpty) ...[
              const Gap(2),
              Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ],
        ),
        const Gap(2),
        Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}

class _MacroAvgItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MacroAvgItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${value}g',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ),
        const Gap(4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}

final weeklyInsightsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(insightsRepositoryProvider);
  return repo.getWeeklyInsights();
});