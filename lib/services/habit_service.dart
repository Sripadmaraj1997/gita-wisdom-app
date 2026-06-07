// Legacy daily habit counter.
//
// This predates the gentler "Days of Reflection" flow in LocalStorageService.
// It remains available for compatibility, but current Home/Journeys UI uses the
// reflection activity methods so the app avoids aggressive streak messaging.
import 'package:shared_preferences/shared_preferences.dart';

class HabitStatus {
  const HabitStatus({
    required this.streakDays,
    required this.completedToday,
  });

  final int streakDays;
  final bool completedToday;
}

class HabitService {
  const HabitService._();

  static const _lastCompletedDateKey = 'gita_wisdom_last_completed_date';
  static const _streakKey = 'gita_wisdom_daily_streak';

  static Future<HabitStatus> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompleted = prefs.getString(_lastCompletedDateKey);
    final streak = prefs.getInt(_streakKey) ?? 0;
    return HabitStatus(
      streakDays: streak,
      completedToday: lastCompleted == _dateKey(DateTime.now()),
    );
  }

  static Future<HabitStatus> markTodayComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final lastCompleted = prefs.getString(_lastCompletedDateKey);
    final currentStreak = prefs.getInt(_streakKey) ?? 0;

    if (lastCompleted == todayKey) {
      return HabitStatus(
        streakDays: currentStreak,
        completedToday: true,
      );
    }

    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
    final nextStreak = lastCompleted == yesterdayKey ? currentStreak + 1 : 1;
    await prefs.setString(_lastCompletedDateKey, todayKey);
    await prefs.setInt(_streakKey, nextStreak);

    return HabitStatus(
      streakDays: nextStreak,
      completedToday: true,
    );
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
