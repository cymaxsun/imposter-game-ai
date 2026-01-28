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

  static const int _maxSparks = 1;
  static const int _maxSavedCategories = 5;

  // Pro user limits
  static const int _maxSparksPro = 100; // Effectively unlimited relative to 3

  static const String _keySparks = 'remaining_sparks';
  static const String _keyLastReset = 'last_reset_time';

  int _remainingSparks = _maxSparks;
  int _savedCategoryCount = 0;

  int get remainingSparks => _remainingSparks;

  int get maxSparks =>
      SubscriptionService().isPremium ? _maxSparksPro : _maxSparks;

  int get maxSavedCategories => _maxSavedCategories;
  int get savedCategoryCount => _savedCategoryCount;

  Future<void> init() async {
    tz.initializeTimeZones();

    final sparksStr = await _storage.read(key: _keySparks);
    if (sparksStr != null) {
      _remainingSparks = int.tryParse(sparksStr) ?? maxSparks;
    } else {
      _remainingSparks = maxSparks; // Default to full (respects Pro status)
    }

    final resetStr = await _storage.read(key: _keyLastReset);
    final lastReset = resetStr != null ? int.tryParse(resetStr) ?? 0 : 0;

    developer.log(
      'Init: remainingSparks: $_remainingSparks, lastReset: $lastReset',
      name: 'usage_service',
    );

    // Listen to subscription changes to refresh UI and sync sparks
    SubscriptionService().addListener(_handleSubscriptionChange);

    await _checkAndRefillSparks(lastReset);
  }

  void _handleSubscriptionChange() {
    // If the user just upgraded, ensure they have the Pro limit
    if (SubscriptionService().isPremium && _remainingSparks < _maxSparksPro) {
      _remainingSparks = _maxSparksPro;
      _saveSparks();
    } else if (!SubscriptionService().isPremium &&
        _remainingSparks > _maxSparks) {
      // If they downgraded, cap them at the Free limit
      _remainingSparks = _maxSparks;
      _saveSparks();
    }
    notifyListeners();
  }

  void updateSavedCategoryCount(int count) {
    _savedCategoryCount = count;
    notifyListeners();
  }

  bool get canMakeRequest {
    if (SubscriptionService().isPremium) return true;
    return _remainingSparks > 0;
  }

  bool get canSaveCategory {
    if (SubscriptionService().isPremium) return true;
    return _savedCategoryCount < _maxSavedCategories;
  }

  // Formerly incrementRequestCount
  Future<void> consumeSpark() async {
    if (_remainingSparks > 0) {
      _remainingSparks--;
      await _saveSparks();
      notifyListeners();
    }
  }

  // Formerly grantBonusRequest
  Future<void> addSpark() async {
    if (_remainingSparks < maxSparks) {
      _remainingSparks++;
      await _saveSparks();
      notifyListeners();
      developer.log(
        'Added spark. New count: $_remainingSparks',
        name: 'usage_service',
      );
    }
  }

  Future<void> _saveSparks() async {
    await _storage.write(key: _keySparks, value: _remainingSparks.toString());
  }

  Future<void> _checkAndRefillSparks(int lastResetEpoch) async {
    final networkTime = await TimeService().getNetworkTimeEST();

    if (networkTime == null) {
      developer.log(
        'Could not fetch network time, skipping spark check',
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
      // Refill to full
      _remainingSparks = maxSparks;
      await _saveSparks();

      await _storage.write(
        key: _keyLastReset,
        value: now.millisecondsSinceEpoch.toString(),
      );
      developer.log(
        'Sparks refilled (new day detected). New limit: $maxSparks',
        name: 'usage_service',
      );
      notifyListeners();
    }
  }

  // For debug/testing
  Future<void> resetDailyLimit() async {
    _remainingSparks = maxSparks;
    await _saveSparks();
    notifyListeners();
  }
}
