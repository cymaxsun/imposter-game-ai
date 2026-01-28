import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imposter_finder/services/usage_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  group('UsageService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tz.initializeTimeZones();
    });

    test('Initializes with max sparks', () async {
      final service = UsageService();
      await service.init();
      expect(service.remainingSparks, 3);
      expect(service.canMakeRequest, true);
    });

    test('Consumes sparks correctly', () async {
      final service = UsageService();
      await service.init();

      await service.consumeSpark();
      expect(service.remainingSparks, 2);
    });

    test('Enforces spark usage', () async {
      final service = UsageService();
      await service.init();

      // Exhaust sparks
      await service.consumeSpark(); // 2
      await service.consumeSpark(); // 1
      await service.consumeSpark(); // 0

      expect(service.remainingSparks, 0);
      expect(service.canMakeRequest, false);

      // Try one more
      await service.consumeSpark();
      expect(service.remainingSparks, 0); // Should not go negative
    });

    test('Adds sparks correctly with cap', () async {
      final service = UsageService();
      await service.init();

      // Start full
      expect(service.remainingSparks, 3);
      await service.addSpark();
      expect(service.remainingSparks, 3); // Cap enforced

      // Consume one
      await service.consumeSpark(); // 2
      expect(service.remainingSparks, 2);

      // Add back
      await service.addSpark(); // 3
      expect(service.remainingSparks, 3);
    });

    test('Saved category limit logic', () {
      final service = UsageService();
      service.updateSavedCategoryCount(4);
      expect(service.canSaveCategory, true);

      service.updateSavedCategoryCount(5);
      expect(service.canSaveCategory, false);
    });
  });
}
