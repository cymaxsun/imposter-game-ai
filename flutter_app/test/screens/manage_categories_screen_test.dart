import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_finder/screens/manage_categories_screen.dart';
import 'package:imposter_finder/services/api_service.dart';
import 'package:mocktail/mocktail.dart'; // Needed for fallback values if used
import 'package:http/http.dart' as http;

import '../helpers/pump_app.dart';
import '../helpers/screen_sizes.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  group('ManageCategoriesScreen', () {
    late MockClient client;
    final Map<String, List<String>> initialCategories = {
      'Animals': ['Lion', 'Tiger'],
      'Space': ['Mars', 'Venus'],
      'Fruits': ['Apple', 'Banana'],
    };

    setUp(() {
      client = MockClient();
      ApiService.client = client;
    });

    testWidgets('renders correctly on iPhone SE (375x667)', (tester) async {
      // Arrange: Set screen size
      tester.view.physicalSize =
          ScreenSizes.iphoneSE * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpApp(
        ManageCategoriesScreen(initialCategories: initialCategories),
      );

      // Assert
      check(find.text('AI Category Studio').evaluate()).isNotEmpty();
      check(find.text('Animals').evaluate()).isNotEmpty();
      check(find.text('Space').evaluate()).isNotEmpty();

      // Verify GridView handles small width (check for overflow exception by absence)
      // Check for common error texts if any, or just ensure widget is present
      check(find.byType(GridView).evaluate()).isNotEmpty();

      // Teardown size
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('renders correctly on iPhone Pro Max (430x932)', (
      tester,
    ) async {
      tester.view.physicalSize =
          ScreenSizes.iphoneProMax * tester.view.devicePixelRatio;
      tester.view.devicePixelRatio =
          3.0; // Pro Max typically has 3.0 pixel ratio

      await tester.pumpApp(
        ManageCategoriesScreen(initialCategories: initialCategories),
      );

      check(find.text('AI Category Studio').evaluate()).isNotEmpty();
      check(find.text('Animals').evaluate()).isNotEmpty();

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });

    testWidgets('shows delete confirmation dialog', (tester) async {
      await tester.pumpApp(
        ManageCategoriesScreen(initialCategories: initialCategories),
      );

      // Find delete button for "Animals" (first one usually)
      final deleteIcon = find.byIcon(Icons.delete_outline);
      check(deleteIcon.evaluate()).isNotEmpty();

      // Tap delete on the first one
      await tester.tap(deleteIcon.first);
      await tester.pumpAndSettle();

      // Verify dialog appears
      check(find.text('Delete Category?').evaluate()).isNotEmpty();
      check(find.text('Delete').evaluate()).isNotEmpty();
      check(find.text('Cancel').evaluate()).isNotEmpty();
    });
  });
}
