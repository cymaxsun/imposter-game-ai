import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/usage_service.dart';
import '../services/subscription_service.dart';
import '../services/ad_service.dart';

import 'setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _loadingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _loadingAnimation;

  double _loadingProgress = 0.0;
  String _loadingText = 'Loading Files...';

  @override
  void initState() {
    super.initState();

    // Pulse animation for the mascot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial progress bar animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _loadingAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _loadingController,
            curve: Curves.easeInOutCubic,
          ),
        )..addListener(() {
          setState(() {
            _loadingProgress = _loadingAnimation.value;
            if (_loadingProgress > 0.8) {
              _loadingText = 'Scanning for Imposters...';
            } else if (_loadingProgress > 0.4) {
              _loadingText = 'Initializing Services...';
            }
          });
        });

    _loadingController.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    final startTime = DateTime.now();

    try {
      // Run app initializations
      await SubscriptionService().init();
      await UsageService().init();
      await AdService().init();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }

    // Ensure we show the splash for at least 3 seconds for the "wow" factor
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 3000) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SetupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // HTML-inspired colors
    final colorScheme = Theme.of(context).colorScheme;

    // HTML-inspired colors
    final backgroundColor = isDark
        ? colorScheme.onSurface
        : colorScheme.surface; // Was 0xFFE0F2F1
    final primaryColor = colorScheme.tertiary; // Was 0xFF6347EB
    final textColor = isDark
        ? Colors.white
        : colorScheme.onSurface; // Was 0xFF121118
    final barBgColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : colorScheme.primaryContainer; // Was 0xFFE6E1FF

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Imposter Finder',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay sharp, detective.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // mascot
              Center(
                child: SizedBox(
                  width: 380,
                  height: 380,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Mascot Image
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Image.asset(
                              'assets/images/sharksplash.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading Section
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _loadingText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor.withValues(alpha: 0.7),
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '${(_loadingProgress * 100).toInt()}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: barBgColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _loadingProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _DotIndicator(
                          isActive: index == 0, // Simplified for now
                          color: primaryColor,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _DotIndicator({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
