import 'package:checks/checks.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_finder/screens/ai_category_studio_screen.dart';
import 'package:imposter_finder/services/api_service.dart';
import 'package:mocktail/mocktail.dart'; // Needed for fallback values if used
import 'package:http/http.dart' as http;

import '../helpers/pump_app.dart';
import '../helpers/screen_sizes.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  group('AiCategoryStudioScreen', () {
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
        AiCategoryStudioScreen(
          existingCategoryNames: initialCategories.keys.toList(),
        ),
      );

      // Assert
      check(find.text('AI Studio').evaluate()).isNotEmpty();
      check(
        find.text('Describe a topic or theme to create a category.').evaluate(),
      ).isNotEmpty();
      check(find.text('Generate with AI').evaluate()).isNotEmpty();

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
        AiCategoryStudioScreen(
          existingCategoryNames: initialCategories.keys.toList(),
        ),
      );

      check(find.text('AI Studio').evaluate()).isNotEmpty();

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
