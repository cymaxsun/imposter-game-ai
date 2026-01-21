import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_finder/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget, {NavigatorObserver? navigatorObserver}) {
    return pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Default to light for consistency
        home: Scaffold(body: widget),
        navigatorObservers: navigatorObserver != null
            ? [navigatorObserver]
            : [],
      ),
    );
  }

  Future<void> pumpAppScaffold(
    Widget widget, {
    NavigatorObserver? navigatorObserver,
  }) {
    return pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: widget,
        navigatorObservers: navigatorObserver != null
            ? [navigatorObserver]
            : [],
      ),
    );
  }
}
