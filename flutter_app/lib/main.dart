import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';
import 'theme/app_theme.dart';
import 'services/usage_service.dart';
import 'services/subscription_service.dart';

/// Entry point for the Imposter Finder application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services

  await UsageService().init();
  try {
    await SubscriptionService().init();
  } catch (e) {
    debugPrint('Failed to initialize SubscriptionService: $e');
  }

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
