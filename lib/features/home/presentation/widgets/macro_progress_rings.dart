import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/core/constants/app_strings.dart';

class MacroProgressRings extends StatelessWidget {
  final int proteinCurrent;
  final int proteinTarget;
  final int carbsCurrent;
  final int carbsTarget;
  final int fatsCurrent;
  final int fatsTarget;

  const MacroProgressRings({
    super.key,
    required this.proteinCurrent,
    required this.proteinTarget,
    required this.carbsCurrent,
    required this.carbsTarget,
    required this.fatsCurrent,
    required this.fatsTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MacroRing(
          label: AppStrings.protein,
          current: proteinCurrent,
          target: proteinTarget,
          color: Colors.green,
          icon: Icons.fitness_center,
        ),
        _MacroRing(
          label: AppStrings.carbs,
          current: carbsCurrent,
          target: carbsTarget,
          color: Colors.orange,
          icon: Icons.grain,
        ),
        _MacroRing(
          label: AppStrings.fat,
          current: fatsCurrent,
          target: fatsTarget,
          color: Colors.red,
          icon: Icons.opacity,
        ),
      ],
    );
  }
}

class _MacroRing extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;
  final IconData icon;

  const _MacroRing({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.icon,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: 8,
                color: color.withValues(alpha: 0.1),
              ),
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const Gap(2),
                Text(
                  '$current',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Gap(8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '/ $target g',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}