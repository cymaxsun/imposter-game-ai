import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

/// Entry point for the Imposter Finder application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start the auth handshake immediately in the background.
  // We do NOT await this; let it race with the UI startup.
  ApiService.warmUp();

  runApp(const ImposterFinderApp());
}

/// Root widget for the Imposter Finder app.
///
/// Configures the [MaterialApp] with both light and dark themes,
/// and sets the initial route to [SplashScreen].
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
      home: const SplashScreen(),
    );
  }
}
