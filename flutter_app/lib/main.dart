import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';
import 'theme/app_theme.dart';

/// Entry point for the Imposter Finder application.
void main() {
  runApp(const ImposterFinderApp());
}

/// Root widget for the Imposter Finder app.
///
/// Configures the [MaterialApp] with both light and dark themes,
/// and sets the initial route to [SetupScreen].
class ImposterFinderApp extends StatelessWidget {
  /// Creates the root [ImposterFinderApp] widget.
  const ImposterFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imposter Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Respects system preference
      home: const SetupScreen(),
    );
  }
}
