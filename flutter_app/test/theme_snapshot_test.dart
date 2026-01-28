import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_finder/theme/app_theme.dart';
import 'package:imposter_finder/theme/pastel_theme.dart';

void main() {
  test('Snapshot of all Theme Colors', () {
    // 1. Get the Light Theme
    final theme = AppTheme.lightTheme;

    // 2. Extract Extensions

    final game = theme.extension<GameScreenColors>()!;
    final ai = theme.extension<AiStudioColors>()!;
    final pastel = theme.extension<PastelTheme>()!;
    final custom = theme.extension<CustomColors>()!;

    print('\n--- BASELINE COLOR SNAPSHOT ---');

    // Standard Material 3 Mapping (Target State)
    // Primary -> Primary Brand
    expect(
      theme.colorScheme.primary.value,
      0xff307de8,
      reason: 'Primary should match Primary Brand',
    );
    // Secondary -> Secondary Brand
    expect(
      theme.colorScheme.secondary.value,
      0xff8b7cf6,
      reason: 'Secondary should match Secondary Brand',
    );
    // Tertiary -> Accent
    expect(
      theme.colorScheme.tertiary.value,
      0xff6347eb,
      reason: 'Tertiary should match Accent',
    );
    // Surface -> Off White
    expect(
      theme.colorScheme.surface.value,
      0xfffdfcf8,
      reason: 'Surface should match Off White',
    );
    // Surface Container -> Soft Surface
    expect(
      theme.colorScheme.surfaceContainer.value,
      0xfff9fafb,
      reason: 'Surface Container should match Soft Surface',
    );
    // On Surface -> Deep Charcoal
    expect(
      theme.colorScheme.onSurface.value,
      0xff121118,
      reason: 'On Surface should match Deep Charcoal',
    );
    // Primary Container -> Soft Lavender (Approx mapping)
    expect(
      theme.colorScheme.primaryContainer.value,
      0xffe6e1ff,
      reason: 'Primary Container should match Soft Lavender',
    );
    // Tertiary Container -> Hero Yellow
    expect(
      theme.colorScheme.tertiaryContainer.value,
      0xffbda02e,
      reason: 'Tertiary Container should match Hero Yellow',
    );
    // Outline -> Slate Text
    expect(
      theme.colorScheme.outline.value,
      0xff718096,
      reason: 'Outline should match Slate Text',
    );

    // GameScreenColors
    expect(game.cardFrontPrimary.value, 0xff0a2472);
    expect(game.cardFrontBackground.value, 0xfffffff8);
    expect(game.cardFrontTextDark.value, 0xff181811);
    expect(game.cardFrontTextMuted.value, 0xff7889a9);
    expect(game.innocentBackground.value, 0xffffffff);
    expect(game.innocentAccent.value, 0xff10b981);
    expect(game.innocentText.value, 0xff064e3b);
    expect(game.innocentMuted.value, 0xff3b6e58);
    expect(game.imposterBackground.value, 0xffffffff);
    expect(game.imposterAccent.value, 0xffef4444);
    expect(game.imposterText.value, 0xff7f1d1d);
    expect(game.imposterMuted.value, 0xff991b1b);
    expect(game.buttonPrimary.value, 0xff0a2472);
    expect(game.buttonText.value, 0xffffffff);
    expect(game.headerText.value, 0xff181811);
    expect(game.headerSubtext.value, 0xff898961);

    // AiStudioColors
    expect(ai.primary.value, 0xff9c27b0);
    expect(ai.background.value, 0xfff3e5f5);
    expect(ai.border.value, 0xffce93d8);

    // PastelTheme
    expect(pastel.pastelPink.value, 0xfffde2e4);
    expect(pastel.pastelMint.value, 0xffe2f0cb);
    expect(pastel.pastelLavender.value, 0xffe0bbe4);
    expect(pastel.pastelYellow.value, 0xfffff4bd);
    expect(pastel.pastelBlue.value, 0xffd1e9ff);
    expect(pastel.pastelPeach.value, 0xffffd8be);
    expect(pastel.pastelGreen.value, 0xffc1e1c1);
    expect(pastel.softCoral.value, 0xfff08080);
    expect(pastel.doneMint.value, 0xff98d8a0);

    // CustomColors
    expect(custom.succeed?.value, 0xff80cbc4);
    expect(custom.warn?.value, 0xffff5252);

    print('--- END SNAPSHOT ---\n');
  });
}
