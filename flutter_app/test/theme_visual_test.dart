import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_finder/theme/app_theme.dart';

void main() {
  testWidgets('Golden Test: Theme Visual Snapshot', (
    WidgetTester tester,
  ) async {
    // 1. Arrange: Build a widget that uses key theme components
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary Button
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Primary Button'),
                ),
                const SizedBox(height: 20),
                // Card with Text
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Headline Large',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Body Large', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Icon
                const Icon(Icons.star, size: 48),
              ],
            ),
          ),
        ),
      ),
    );

    // 2. Act & Assert: Match against golden file
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/theme_visual_baseline.png'),
    );
  });
}
