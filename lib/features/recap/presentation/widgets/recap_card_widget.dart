import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/core/constants/app_strings.dart';

class RecapCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const RecapCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String monthName = data['monthName'] ?? 'This Month';
    final int daysLogged = data['daysLogged'] ?? 0;
    final int totalMeals = data['totalMeals'] ?? 0;
    final int avgCalories = data['avgCalories'] ?? 0;
    final double avgWaterLiters = (data['avgWaterLiters'] as num?)?.toDouble() ?? 0.0;
    final int bestStreak = data['bestStreak'] ?? 0;
    final String topFood = data['topFood'] ?? '—';
    final int totalProtein = data['totalProtein'] ?? 0;
    final int totalCarbs = data['totalCarbs'] ?? 0;
    final int totalFat = data['totalFat'] ?? 0;

    final double totalMacros = (totalProtein + totalCarbs + totalFat).toDouble();
    final double proteinPct = totalMacros > 0 ? totalProtein / totalMacros : 0.33;
    final double carbsPct = totalMacros > 0 ? totalCarbs / totalMacros : 0.33;
    final double fatPct = totalMacros > 0 ? totalFat / totalMacros : 0.34;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2B2B2B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6B9E6B).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Kalo. logo + Month Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Kalo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 2, top: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B9E6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Text(
                  monthName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const Gap(28),

          // Hero Stat: Days Consistent
          Center(
            child: Column(
              children: [
                Text(
                  '$daysLogged',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF4832A),
                    height: 1.0,
                  ),
                ),
                const Gap(4),
                const Text(
                  AppStrings.daysConsistent,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const Gap(28),

          // 2x2 Stat Pills Grid
          Row(
            children: [
              Expanded(
                child: _RecapStatPill(
                  icon: '🔥',
                  label: AppStrings.bestStreak,
                  value: '$bestStreak ${AppStrings.day}${bestStreak == 1 ? '' : 's'}',
                  color: const Color(0xFFF4832A),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _RecapStatPill(
                  icon: '🥗',
                  label: AppStrings.totalMealsLogged,
                  value: '$totalMeals ${AppStrings.items}',
                  color: const Color(0xFF6B9E6B),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: _RecapStatPill(
                  icon: '💧',
                  label: AppStrings.avgWaterDaily,
                  value: '${avgWaterLiters.toStringAsFixed(1)} L/${AppStrings.day}',
                  color: const Color(0xFF5BA3D5),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _RecapStatPill(
                  icon: '⚡',
                  label: AppStrings.avgCalories,
                  value: '$avgCalories ${AppStrings.kcal}',
                  color: const Color(0xFFE8A87C),
                ),
              ),
            ],
          ),

          const Gap(24),

          // Top Food & Macro Ratio Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.topFood,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        topFood,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Gap(12),

                // Macro Bar
                Text(
                  'Macro Breakdown',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
                const Gap(6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (proteinPct * 100).round().clamp(1, 100),
                          child: Container(color: const Color(0xFF6B9E6B)),
                        ),
                        Expanded(
                          flex: (carbsPct * 100).round().clamp(1, 100),
                          child: Container(color: const Color(0xFFE8A87C)),
                        ),
                        Expanded(
                          flex: (fatPct * 100).round().clamp(1, 100),
                          child: Container(color: const Color(0xFFE07070)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MacroDotLabel(color: const Color(0xFF6B9E6B), label: 'P: ${totalProtein}g'),
                    _MacroDotLabel(color: const Color(0xFFE8A87C), label: 'C: ${totalCarbs}g'),
                    _MacroDotLabel(color: const Color(0xFFE07070), label: 'F: ${totalFat}g'),
                  ],
                ),
              ],
            ),
          ),

          const Gap(24),

          // Quote & Watermark Footer
          Center(
            child: Column(
              children: [
                const Text(
                  '💪 ${AppStrings.keepBuildingHabit}',
                  style: TextStyle(
                    color: Color(0xFF6B9E6B),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const Gap(4),
                    Text(
                      AppStrings.madeWithKalo,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapStatPill extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _RecapStatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const Gap(6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[300],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MacroDotLabel extends StatelessWidget {
  final Color color;
  final String label;

  const _MacroDotLabel({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
