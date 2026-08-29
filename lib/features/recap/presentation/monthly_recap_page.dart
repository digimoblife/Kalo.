import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kalo_app/core/constants/app_strings.dart';
import 'package:kalo_app/features/recap/data/recap_repository.dart';
import 'package:kalo_app/features/recap/presentation/widgets/recap_card_widget.dart';

class MonthlyRecapPage extends ConsumerStatefulWidget {
  const MonthlyRecapPage({super.key});

  @override
  ConsumerState<MonthlyRecapPage> createState() => _MonthlyRecapPageState();
}

class _MonthlyRecapPageState extends ConsumerState<MonthlyRecapPage> {
  final GlobalKey _globalKey = GlobalKey();
  DateTime _selectedMonth = DateTime.now();
  bool _isSharing = false;

  Future<void> _shareRecap() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/kalo_monthly_recap.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my monthly consistency on Kalo.! 🍃 #KaloApp #Consistency',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.failed}$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    if (next.isBefore(DateTime.now()) || DateUtils.isSameMonth(next, DateTime.now())) {
      setState(() => _selectedMonth = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recapAsync = ref.watch(monthlyRecapProvider(_selectedMonth));
    final isCurrentMonth = DateUtils.isSameMonth(_selectedMonth, DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: const Text(AppStrings.monthlyRecap),
        backgroundColor: const Color(0xFFFAFAF8),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Month Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: isCurrentMonth ? null : _nextMonth,
                  ),
                ],
              ),
            ),

            const Gap(20),

            // Card Section
            recapAsync.when(
              loading: () => const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('${AppStrings.error}$err'),
                ),
              ),
              data: (data) {
                final int daysLogged = data['daysLogged'] ?? 0;
                if (daysLogged == 0) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(top: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 48, color: Colors.grey[400]),
                        const Gap(16),
                        const Text(
                          AppStrings.noRecapData,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    RepaintBoundary(
                      key: _globalKey,
                      child: RecapCardWidget(data: data),
                    ),

                    const Gap(28),

                    // Share Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSharing ? null : _shareRecap,
                        icon: _isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.ios_share, size: 20),
                        label: const Text(
                          AppStrings.shareRecap,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const Gap(32),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
