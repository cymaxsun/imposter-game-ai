import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  bool _isYearlySelected = true;

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      await SubscriptionService().restorePurchases();
      if (SubscriptionService().isPremium && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully!')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscriptions found.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchase(PackageType packageType) async {
    setState(() => _isLoading = true);
    try {
      final success = await SubscriptionService().purchasePremium(
        packageType: packageType,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Premium! Limits removed.'),
            backgroundColor: Color(0xFF6B5CE7),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepCharcoal = Color(0xFF121118);
    const warmOffWhite = Color(0xFFFDFCF8);
    const softLavender = Color(0xFFE6E1FF);
    const vibrantMint = Color(0xFFBBF7D0);
    const primaryGreen = Color(0xFF4ADE80);
    const golden = Color(0xFFFACC15);
    const octoLavender = Color(0xFFB8A9FF);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    ).apply(bodyColor: deepCharcoal, displayColor: deepCharcoal);

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: warmOffWhite,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 16.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      height: 56,
                                    ), // Spacer for fixed close button (32 + 24)
                                    _OctoHero(
                                      accentColor: octoLavender,
                                      glowColor: softLavender,
                                      starColor: golden,
                                      inkColor: deepCharcoal,
                                    ),
                                    const SizedBox(height: 32),
                                    AutoSizeText(
                                      'Unlock Full Chaos!',
                                      style: textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    _FeatureList(
                                      iconColor: primaryGreen,
                                      textColor: deepCharcoal.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 48), // Added spacing
                                    if (_isLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        child: CircularProgressIndicator(),
                                      )
                                    else ...[
                                      _buildPlanSelector(
                                        deepCharcoal: deepCharcoal,
                                        softLavender: softLavender,
                                        vibrantMint: vibrantMint,
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF34D399,
                                                ).withValues(alpha: 0.25),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () => _purchase(
                                              _isYearlySelected
                                                  ? PackageType.annual
                                                  : PackageType.monthly,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: vibrantMint,
                                              foregroundColor: deepCharcoal,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical:
                                                        16, // Increased padding
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: AutoSizeText(
                                              'Go Pro',
                                              style: textTheme.titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 18, // Larger font
                                                  ),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 16,
                                      ), // Reduced bottom spacing
                                      Builder(
                                        builder: (context) {
                                          final footerGroup = AutoSizeGroup();
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: TextButton(
                                                  onPressed: _restorePurchases,
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        deepCharcoal.withValues(
                                                          alpha: 0.4,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                        ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: AutoSizeText(
                                                    'Restore Purchases',
                                                    group: footerGroup,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    minFontSize: 8,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '•',
                                                style: TextStyle(
                                                  color: deepCharcoal
                                                      .withValues(alpha: 0.4),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Flexible(
                                                child: TextButton(
                                                  onPressed: () {},
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        deepCharcoal.withValues(
                                                          alpha: 0.4,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                        ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: AutoSizeText(
                                                    'Terms of Service',
                                                    group: footerGroup,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    minFontSize: 8,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '•',
                                                style: TextStyle(
                                                  color: deepCharcoal
                                                      .withValues(alpha: 0.4),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Flexible(
                                                child: TextButton(
                                                  onPressed: () {},
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        deepCharcoal.withValues(
                                                          alpha: 0.4,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                        ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: AutoSizeText(
                                                    'Privacy Policy',
                                                    group: footerGroup,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    minFontSize: 8,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 16,
                        right: horizontalPadding,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: deepCharcoal,
                                  size: 24,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSelector({
    required Color deepCharcoal,
    required Color softLavender,
    required Color vibrantMint,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPlanButton(
          label: 'Monthly',
          sublabel: '\$4.99',
          caption: null,
          isSelected: !_isYearlySelected,
          accentColor: softLavender,
          highlightColor: softLavender,
          badgeColor: softLavender,
          deepCharcoal: deepCharcoal,
          onTap: () => setState(() => _isYearlySelected = false),
        ),
        const SizedBox(height: 12),
        _buildPlanButton(
          label: 'Yearly',
          sublabel: '\$29.99',
          caption: '(Save 50%)',
          isSelected: _isYearlySelected,
          accentColor: vibrantMint,
          highlightColor: const Color(0xFF22C55E),
          badgeColor: const Color(0xFF10B981),
          deepCharcoal: deepCharcoal,
          showBadge: true,
          onTap: () => setState(() => _isYearlySelected = true),
        ),
      ],
    );
  }

  Widget _buildPlanButton({
    required String label,
    required String sublabel,
    required String? caption,
    required bool isSelected,
    required Color accentColor,
    required Color highlightColor,
    required Color badgeColor,
    required Color deepCharcoal,
    bool showBadge = false,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? highlightColor : accentColor;
    final backgroundColor = accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ), // Increased padding
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF2A2A2A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                      ),
                      if (caption == null)
                        AutoSizeText(
                          sublabel,
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                        )
                      else
                        AutoSizeText.rich(
                          TextSpan(
                            text: sublabel,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              TextSpan(
                                text: '  $caption',
                                style: TextStyle(
                                  color: deepCharcoal.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SelectionDot(
                  isSelected: isSelected,
                  borderColor: label == 'Yearly'
                      ? badgeColor.withValues(alpha: 0.6)
                      : deepCharcoal.withValues(alpha: 0.2),
                  fillColor: label == 'Yearly'
                      ? const Color(0xFF059669)
                      : deepCharcoal,
                ),
              ],
            ),
          ),
          if (showBadge)
            Positioned(
              top: -10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({
    required this.isSelected,
    required this.borderColor,
    required this.fillColor,
  });

  final bool isSelected;
  final Color borderColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        color: Colors.white.withValues(alpha: 0.5),
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: isSelected ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fillColor),
          ),
        ),
      ),
    );
  }
}

class _OctoHero extends StatelessWidget {
  const _OctoHero({
    required this.accentColor,
    required this.glowColor,
    required this.starColor,
    required this.inkColor,
  });

  final Color accentColor;
  final Color glowColor;
  final Color starColor;
  final Color inkColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        color: glowColor.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 40),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.sentiment_satisfied_alt_rounded,
          size: 100,
          color: starColor,
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.iconColor, required this.textColor});

  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final items = [
      'Unlimited Category Library',
      'Up to 10 AI generations per day',
    ];

    return FractionallySizedBox(
      widthFactor: 0.9,
      child: Column(
        children: [
          for (final item in items) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: AutoSizeText(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    minFontSize: 10,
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
