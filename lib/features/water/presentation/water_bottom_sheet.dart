import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:kalo_app/core/constants/app_strings.dart';
import 'package:kalo_app/features/water/data/water_repository.dart';
import 'package:kalo_app/features/water/data/water_providers.dart';

class WaterBottomSheet extends ConsumerStatefulWidget {
  const WaterBottomSheet({super.key});

  @override
  ConsumerState<WaterBottomSheet> createState() => _WaterBottomSheetState();
}

class _WaterBottomSheetState extends ConsumerState<WaterBottomSheet> {
  int _customAmount = 250;
  bool _isSaving = false;

  Future<void> _addWater(int amount) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(waterRepositoryProvider).addWater(amount);
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(waterDataProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.failed}$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.addWater,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Gap(16),

          Text(
            AppStrings.quickAdd,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const Gap(12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [100, 250, 350, 500].map((ml) {
              return OutlinedButton(
                onPressed: _isSaving ? null : () => _addWater(ml),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue[300]!),
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('$ml ml'),
              );
            }).toList(),
          ),

          const Gap(24),

          Text(
            AppStrings.customAmount,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const Gap(12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _customAmount.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.amountMl,
                    border: OutlineInputBorder(),
                    suffixText: 'ml',
                  ),
                  onChanged: (v) => _customAmount = int.tryParse(v) ?? 250,
                ),
              ),
              const Gap(12),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _addWater(_customAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(AppStrings.save),
              ),
            ],
          ),

          const Gap(24),

          Divider(),
          const Gap(16),

          Text(
            AppStrings.waterDailyTarget,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const Gap(12),

          Consumer(
            builder: (context, ref, _) {
              final targetAsync = ref.watch(waterTargetProvider);
              return targetAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (target) {
                  final controller = TextEditingController(text: target.toString());
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.targetMl,
                            border: OutlineInputBorder(),
                            suffixText: 'ml',
                          ),
                        ),
                      ),
                      const Gap(12),
                      ElevatedButton(
                        onPressed: () async {
                          final newTarget = int.tryParse(controller.text) ?? 2000;
                          await ref.read(waterRepositoryProvider).setTarget(newTarget);
                          if (mounted) {
                            Navigator.pop(context);
                            ref.invalidate(waterDataProvider);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(AppStrings.save),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
