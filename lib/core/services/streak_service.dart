import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const _milestones = [3, 7, 14, 30, 60, 100, 365];
  static const _prefsKey = 'last_celebrated_streak';

  static Future<int?> checkMilestone(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCelebrated = prefs.getInt(_prefsKey) ?? 0;

    for (final m in _milestones) {
      if (currentStreak >= m && lastCelebrated < m) {
        return m;
      }
    }
    return null;
  }

  static Future<void> markCelebrated(int milestone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, milestone);
  }

  static List<int> getEarnedMilestones(int currentStreak) {
    return _milestones.where((m) => m <= currentStreak).toList();
  }
}