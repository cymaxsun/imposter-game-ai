import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'subscription_service.dart';
import 'time_service.dart';

class UsageService extends ChangeNotifier {
  static final UsageService _instance = UsageService._internal();

  factory UsageService() {
    return _instance;
  }

  UsageService._internal();

  static const _storage = FlutterSecureStorage();

  static const int _maxDailyRequests = 3;
  static const int _maxSavedCategories = 5;

  // Pro user limits - adjust these values as needed
  static const int _maxDailyRequestsPro = 100;
  // Note: Pro users have unlimited saved categories (no _maxSavedCategoriesPro)

  static const String _keyDailyCount = 'daily_request_count';
  static const String _keyLastReset = 'last_reset_time';

  int _dailyRequestCount = 0;
  int _savedCategoryCount = 0; // Injected or fetched from repository

  int get dailyRequestCount => _dailyRequestCount;
  int get maxDailyRequests => SubscriptionService().isPremium
      ? _maxDailyRequestsPro
      : _maxDailyRequests;
  int get maxSavedCategories =>
      _maxSavedCategories; // Pro users have unlimited (checked in canSaveCategory)
  int get savedCategoryCount => _savedCategoryCount;

  Future<void> init() async {
    tz.initializeTimeZones();
    // tz.initializeTimeZones(); // Already initialized in main? keeping if needed
    // Assuming main calls tz.initializeTimeZones now or simpler to keep it here if cheap.
    // Actually typically initTimeZones is cheap.

    final dailyStr = await _storage.read(key: _keyDailyCount);
    _dailyRequestCount = dailyStr != null ? int.tryParse(dailyStr) ?? 0 : 0;

    final resetStr = await _storage.read(key: _keyLastReset);
    final lastReset = resetStr != null ? int.tryParse(resetStr) ?? 0 : 0;
    developer.log(
      'Init: dailyRequestCount: $_dailyRequestCount, lastReset: $lastReset',
      name: 'usage_service',
    );
    await _checkAndResetDailyLimit(lastReset);
  }

  void updateSavedCategoryCount(int count) {
    _savedCategoryCount = count;
    notifyListeners();
  }

  bool get canMakeRequest {
    return _dailyRequestCount < _maxDailyRequests;
  }

  bool get canSaveCategory {
    // Pro users have unlimited saved categories
    if (SubscriptionService().isPremium) return true;
    return _savedCategoryCount < _maxSavedCategories;
  }

  Future<void> incrementRequestCount() async {
    if (!canMakeRequest) return;

    _dailyRequestCount++;
    await _storage.write(
      key: _keyDailyCount,
      value: _dailyRequestCount.toString(),
    );
    notifyListeners();
  }

  Future<void> _checkAndResetDailyLimit(int lastResetEpoch) async {
    // Fetch network time to prevent device time manipulation
    final networkTime = await TimeService().getNetworkTimeEST();

    if (networkTime == null) {
      // No internet = can't verify time, don't reset (be cautious)
      // AI generation requires internet anyway, so this is fine
      developer.log(
        'Could not fetch network time, skipping daily limit check',
        name: 'usage_service',
      );
      return;
    }

    final now = networkTime;
    final lastReset = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.getLocation('America/New_York'),
      lastResetEpoch,
    );

    // Reset if the day has changed in EST
    if (now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day) {
      _dailyRequestCount = 0;
      await _storage.write(key: _keyDailyCount, value: '0');
      await _storage.write(
        key: _keyLastReset,
        value: now.millisecondsSinceEpoch.toString(),
      );
      developer.log(
        'Daily limit reset (new day detected via network time)',
        name: 'usage_service',
      );
      notifyListeners();
    }
  }

  Future<void> resetDailyLimit() async {
    _dailyRequestCount = 0;
    await _storage.write(key: _keyDailyCount, value: '0');
    notifyListeners();
  }
}
