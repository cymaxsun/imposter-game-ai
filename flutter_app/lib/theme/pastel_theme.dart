import 'package:flutter/material.dart';

@immutable
class PastelTheme extends ThemeExtension<PastelTheme> {
  const PastelTheme({
    required this.pastelPink,
    required this.pastelMint,
    required this.pastelLavender,
    required this.pastelYellow,
    required this.pastelBlue,
    required this.pastelPeach,
    required this.pastelGreen,
    required this.softCoral,
    required this.doneMint,
  });

  final Color pastelPink;
  final Color pastelMint;
  final Color pastelLavender;
  final Color pastelYellow;
  final Color pastelBlue;
  final Color pastelPeach;
  final Color pastelGreen;
  final Color softCoral;
  final Color doneMint;

  static const light = PastelTheme(
    pastelPink: Color(0xFFFDE2E4),
    pastelMint: Color(0xFFE2F0CB),
    pastelLavender: Color(0xFFE0BBE4),
    pastelYellow: Color(0xFFFFF4BD),
    pastelBlue: Color(0xFFD1E9FF),
    pastelPeach: Color(0xFFFFD8BE),
    pastelGreen: Color(0xFFC1E1C1),
    softCoral: Color(0xFFF08080),
    doneMint: Color(0xFF98D8A0),
  );

  static const dark = PastelTheme(
    pastelPink: Color(
      0xFFFDE2E4,
    ), // Keep pastels bright even in dark mode for contrast/pop
    pastelMint: Color(0xFFE2F0CB),
    pastelLavender: Color(0xFFE0BBE4),
    pastelYellow: Color(0xFFFFF4BD),
    pastelBlue: Color(0xFFD1E9FF),
    pastelPeach: Color(0xFFFFD8BE),
    pastelGreen: Color(0xFFC1E1C1),
    softCoral: Color(0xFFF08080),
    doneMint: Color(0xFF98D8A0),
  );

  @override
  PastelTheme copyWith({
    Color? pastelPink,
    Color? pastelMint,
    Color? pastelLavender,
    Color? pastelYellow,
    Color? pastelBlue,
    Color? pastelPeach,
    Color? pastelGreen,
    Color? softCoral,
    Color? doneMint,
  }) {
    return PastelTheme(
      pastelPink: pastelPink ?? this.pastelPink,
      pastelMint: pastelMint ?? this.pastelMint,
      pastelLavender: pastelLavender ?? this.pastelLavender,
      pastelYellow: pastelYellow ?? this.pastelYellow,
      pastelBlue: pastelBlue ?? this.pastelBlue,
      pastelPeach: pastelPeach ?? this.pastelPeach,
      pastelGreen: pastelGreen ?? this.pastelGreen,
      softCoral: softCoral ?? this.softCoral,
      doneMint: doneMint ?? this.doneMint,
    );
  }

  @override
  PastelTheme lerp(ThemeExtension<PastelTheme>? other, double t) {
    if (other is! PastelTheme) {
      return this;
    }
    return PastelTheme(
      pastelPink: Color.lerp(pastelPink, other.pastelPink, t)!,
      pastelMint: Color.lerp(pastelMint, other.pastelMint, t)!,
      pastelLavender: Color.lerp(pastelLavender, other.pastelLavender, t)!,
      pastelYellow: Color.lerp(pastelYellow, other.pastelYellow, t)!,
      pastelBlue: Color.lerp(pastelBlue, other.pastelBlue, t)!,
      pastelPeach: Color.lerp(pastelPeach, other.pastelPeach, t)!,
      pastelGreen: Color.lerp(pastelGreen, other.pastelGreen, t)!,
      softCoral: Color.lerp(softCoral, other.softCoral, t)!,
      doneMint: Color.lerp(doneMint, other.doneMint, t)!,
    );
  }
}
