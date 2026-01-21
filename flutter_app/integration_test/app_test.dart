import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:imposter_finder/main.dart';

/// Integration test for the main app flow.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('full game setup flow', (tester) async {
      // Arrange - Launch app
      await tester.pumpWidget(const ImposterFinderApp());
      await tester.pumpAndSettle();

      // Assert - Setup screen is displayed
      expect(find.text('Imposter Finder'), findsOneWidget);
      expect(find.text('START GAME'), findsOneWidget);

      // Act - Increase player count
      final addButton = find.byIcon(Icons.add_circle);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Assert - Player count increased
      expect(find.text('5'), findsOneWidget);

      // Act - Tap start game
      final startButton = find.text('START GAME');
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Assert - Game screen is displayed
      expect(find.text('PLAYER 1/5'), findsOneWidget);
      expect(find.text('TAP TO REVEAL'), findsOneWidget);

      // Act - Tap Card to Reveal
      await tester.tap(find.text('TAP TO REVEAL'));
      await tester.pumpAndSettle(); // Wait for flip animation

      // Assert - Card is revealed (Innocent or Imposter)
      if (find.text('INNOCENT').evaluate().isNotEmpty) {
        expect(find.text('INNOCENT'), findsOneWidget);
      } else {
        expect(find.text('IMPOSTER'), findsOneWidget);
      }
      // Act - Tap Next Player
      final nextButton = find.text('NEXT PLAYER');
      await tester.tap(nextButton);
      await tester.pumpAndSettle(); // Wait for flip back animation

      // Assert - Advance to Player 2
      expect(find.text('PLAYER 2/5'), findsOneWidget);
    });

    testWidgets('manage categories navigation', (tester) async {
      // Arrange
      await tester.pumpWidget(const ImposterFinderApp());
      await tester.pumpAndSettle();

      // Act - Navigate to manage categories
      final manageButton = find.text('AI Studio');
      await tester.tap(manageButton);
      await tester.pumpAndSettle();

      // Assert - Manage categories screen is displayed
      expect(find.text('AI Category Studio'), findsOneWidget);
      expect(find.text('Forge Your Words'), findsOneWidget);
    });
  });
}
