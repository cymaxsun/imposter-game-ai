import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Color.withValues should work', () {
    const color = Color(0xFFE6E1FF);
    final newColor = color.withValues(alpha: 0.3);
    expect(newColor.a, closeTo(0.3, 0.001));
  });
}
