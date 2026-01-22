import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class UsageService extends ChangeNotifier {
  static final UsageService _instance = UsageService._internal();

  factory UsageService() {
    return _instance;
  }

  UsageService._internal();

  static const int _maxDailyRequests = 2; // Reduced for testing
  static const int _maxSavedCategories = 2; // Reduced for testing
  static const String _keyDailyCount = 'daily_request_count';
  static const String _keyLastReset = 'last_reset_time';

  int _dailyRequestCount = 0;
  int _savedCategoryCount = 0; // Injected or fetched from repository

  int get dailyRequestCount => _dailyRequestCount;
  int get maxDailyRequests => _maxDailyRequests;
  int get maxSavedCategories => _maxSavedCategories;

  Future<void> init() async {
    tz.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();

    _dailyRequestCount = prefs.getInt(_keyDailyCount) ?? 0;
    final lastReset = prefs.getInt(_keyLastReset) ?? 0;

    _checkAndResetDailyLimit(lastReset);
  }

  void updateSavedCategoryCount(int count) {
    _savedCategoryCount = count;
    notifyListeners();
  }

  bool get canMakeRequest {
    return _dailyRequestCount < _maxDailyRequests;
  }

  bool get canSaveCategory {
    return _savedCategoryCount < _maxSavedCategories;
  }

  Future<void> incrementRequestCount() async {
    if (!canMakeRequest) return;

    _dailyRequestCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyCount, _dailyRequestCount);
    notifyListeners();
  }

  Future<void> _checkAndResetDailyLimit(int lastResetEpoch) async {
    final now = tz.TZDateTime.now(tz.getLocation('America/New_York'));
    final lastReset = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.getLocation('America/New_York'),
      lastResetEpoch,
    );

    // Reset if the day has changed in EST
    if (now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day) {
      _dailyRequestCount = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDailyCount, 0);
      await prefs.setInt(_keyLastReset, now.millisecondsSinceEpoch);
      notifyListeners();
    }
  }
}
