import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class StreakMilestoneDialog extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;

  const StreakMilestoneDialog({
    super.key,
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<StreakMilestoneDialog> createState() => _StreakMilestoneDialogState();
}

class _StreakMilestoneDialogState extends State<StreakMilestoneDialog> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
    _controller.play();
    Future.delayed(const Duration(seconds: 4), widget.onDismiss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          maxBlastForce: 10,
          minBlastForce: 5,
          colors: [Colors.orange, Colors.deepOrange, Colors.amber, Colors.red],
        ),
        Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔥', style: TextStyle(fontSize: 64)),
                const Gap(16),
                Text(
                  '${widget.milestone} Day Streak!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Gap(8),
                Text(
                  _getMessage(widget.milestone),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMessage(int m) {
    switch (m) {
      case 3:
        return 'Consistency is building! 💪';
      case 7:
        return 'One week strong! 📅';
      case 14:
        return 'Two weeks — habit forming! 🧠';
      case 30:
        return 'Monthly master! 🏆';
      case 60:
        return '60 days — lifestyle change! 🌟';
      case 100:
        return 'Century club! 💯';
      case 365:
        return 'A YEAR! Legendary! 👑';
      default:
        return 'Keep going!';
    }
  }
}