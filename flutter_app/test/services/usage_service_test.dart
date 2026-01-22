import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imposter_finder/services/usage_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('UsageService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tz.initializeTimeZones();
    });

    test('Initializes with 0 requests', () async {
      final service = UsageService();
      await service.init();
      expect(service.dailyRequestCount, 0);
      expect(service.canMakeRequest, true);
    });

    test('Increments request count correctly', () async {
      final service = UsageService();
      await service.init();

      await service.incrementRequestCount();
      expect(service.dailyRequestCount, 1);

      // Persists
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('daily_request_count'), 1);
    });

    test('Enforces max daily requests', () async {
      final service = UsageService();
      await service.init();

      // Exhaust limit
      for (var i = 0; i < 10; i++) {
        await service.incrementRequestCount();
      }

      expect(service.dailyRequestCount, 10);
      expect(service.canMakeRequest, false);

      // Try one more
      await service.incrementRequestCount();
      expect(service.dailyRequestCount, 10); // Should not increase
    });

    test('Saved category limit logic', () {
      final service = UsageService();
      service.updateSavedCategoryCount(19);
      expect(service.canSaveCategory, true);

      service.updateSavedCategoryCount(20);
      expect(service.canSaveCategory, false);
    });
  });
}
