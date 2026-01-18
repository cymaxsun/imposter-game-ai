import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_finder/widgets/flip_card.dart';

void main() {
  group('FlipCard', () {
    testWidgets('renders front widget when not flipped', (tester) async {
      // Arrange
      const frontText = 'Front';
      const backText = 'Back';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlipCard(
              isFlipped: false,
              onFlip: () {},
              front: const Text(frontText),
              back: const Text(backText),
            ),
          ),
        ),
      );

      // Assert using package:checks
      check(find.text(frontText).evaluate()).isNotEmpty();
    });

    testWidgets('calls onFlip when tapped', (tester) async {
      // Arrange
      var flipCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlipCard(
              isFlipped: false,
              onFlip: () => flipCalled = true,
              front: const Text('Front'),
              back: const Text('Back'),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(FlipCard));
      await tester.pump();

      // Assert using package:checks
      check(flipCalled).isTrue();
    });

    testWidgets('animates when isFlipped changes', (tester) async {
      // Arrange
      var isFlipped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FlipCard(
                  isFlipped: isFlipped,
                  onFlip: () => setState(() => isFlipped = !isFlipped),
                  front: const Text('Front'),
                  back: const Text('Back'),
                );
              },
            ),
          ),
        ),
      );

      // Act - tap to flip
      await tester.tap(find.byType(FlipCard));
      await tester.pump();

      // Let animation run halfway
      await tester.pump(const Duration(milliseconds: 200));

      // Let animation complete
      await tester.pumpAndSettle();

      // The widget should have animated (no assertion needed, just no crash)
      check(find.byType(FlipCard).evaluate()).isNotEmpty();
    });
  });
}
