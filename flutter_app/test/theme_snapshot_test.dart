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

    // Standard Material 3 Mapping (Target State)
    // Primary -> Primary Brand
    expect(
      theme.colorScheme.primary.toARGB32(),
      0xff307de8,
      reason: 'Primary should match Primary Brand',
    );
    // Secondary -> Secondary Brand
    expect(
      theme.colorScheme.secondary.toARGB32(),
      0xff8b7cf6,
      reason: 'Secondary should match Secondary Brand',
    );
    // Tertiary -> Accent
    expect(
      theme.colorScheme.tertiary.toARGB32(),
      0xff6347eb,
      reason: 'Tertiary should match Accent',
    );
    // Surface -> Off White
    expect(
      theme.colorScheme.surface.toARGB32(),
      0xfffdfcf8,
      reason: 'Surface should match Off White',
    );
    // Surface Container -> Soft Surface
    expect(
      theme.colorScheme.surfaceContainer.toARGB32(),
      0xfff9fafb,
      reason: 'Surface Container should match Soft Surface',
    );
    // On Surface -> Deep Charcoal
    expect(
      theme.colorScheme.onSurface.toARGB32(),
      0xff121118,
      reason: 'On Surface should match Deep Charcoal',
    );
    // Primary Container -> Soft Lavender (Approx mapping)
    expect(
      theme.colorScheme.primaryContainer.toARGB32(),
      0xffe6e1ff,
      reason: 'Primary Container should match Soft Lavender',
    );
    // Tertiary Container -> Hero Yellow
    expect(
      theme.colorScheme.tertiaryContainer.toARGB32(),
      0xffbda02e,
      reason: 'Tertiary Container should match Hero Yellow',
    );
    // Outline -> Slate Text
    expect(
      theme.colorScheme.outline.toARGB32(),
      0xff718096,
      reason: 'Outline should match Slate Text',
    );

    // GameScreenColors
    expect(game.cardFrontPrimary.toARGB32(), 0xff0a2472);
    expect(game.cardFrontBackground.toARGB32(), 0xfffffff8);
    expect(game.cardFrontTextDark.toARGB32(), 0xff181811);
    expect(game.cardFrontTextMuted.toARGB32(), 0xff7889a9);
    expect(game.innocentBackground.toARGB32(), 0xffffffff);
    expect(game.innocentAccent.toARGB32(), 0xff10b981);
    expect(game.innocentText.toARGB32(), 0xff064e3b);
    expect(game.innocentMuted.toARGB32(), 0xff3b6e58);
    expect(game.imposterBackground.toARGB32(), 0xffffffff);
    expect(game.imposterAccent.toARGB32(), 0xffef4444);
    expect(game.imposterText.toARGB32(), 0xff7f1d1d);
    expect(game.imposterMuted.toARGB32(), 0xff991b1b);
    expect(game.buttonPrimary.toARGB32(), 0xff0a2472);
    expect(game.buttonText.toARGB32(), 0xffffffff);
    expect(game.headerText.toARGB32(), 0xff181811);
    expect(game.headerSubtext.toARGB32(), 0xff898961);

    // AiStudioColors
    expect(ai.primary.toARGB32(), 0xff9c27b0);
    expect(ai.background.toARGB32(), 0xfff3e5f5);
    expect(ai.border.toARGB32(), 0xffce93d8);

    // PastelTheme
    expect(pastel.pastelPink.toARGB32(), 0xfffde2e4);
    expect(pastel.pastelMint.toARGB32(), 0xffe2f0cb);
    expect(pastel.pastelLavender.toARGB32(), 0xffe0bbe4);
    expect(pastel.pastelYellow.toARGB32(), 0xfffff4bd);
    expect(pastel.pastelBlue.toARGB32(), 0xffd1e9ff);
    expect(pastel.pastelPeach.toARGB32(), 0xffffd8be);
    expect(pastel.pastelGreen.toARGB32(), 0xffc1e1c1);
    expect(pastel.softCoral.toARGB32(), 0xfff08080);
    expect(pastel.doneMint.toARGB32(), 0xff98d8a0);

    // CustomColors
    expect(custom.succeed?.toARGB32(), 0xff80cbc4);
    expect(custom.warn?.toARGB32(), 0xffff5252);
  });
}
