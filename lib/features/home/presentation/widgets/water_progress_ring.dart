import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/core/constants/app_strings.dart';
import 'package:kalo_app/features/water/data/water_providers.dart';
import 'package:kalo_app/features/water/presentation/water_bottom_sheet.dart';

class WaterProgressRing extends ConsumerWidget {
  const WaterProgressRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(waterDataProvider);

    return waterAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final current = data['current'] as int;
        final target = data['target'] as int;
        final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
        final percentage = (progress * 100).round();

        return GestureDetector(
          onTap: () => _showWaterSheet(context),
          onLongPress: () => _showWaterSheet(context),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 10,
                      color: Colors.blue[50],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      color: Colors.blue,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue, size: 28),
                      const Gap(2),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(8),
              Text(
                '$current ml / $target ml',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Gap(4),
              Text(
                AppStrings.tapToAddWater,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWaterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WaterBottomSheet(),
    );
  }
}