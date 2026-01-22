import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;

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

  Future<void> _purchase() async {
    setState(() => _isLoading = true);
    try {
      final success = await SubscriptionService().purchasePremium();
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark gaming background
      body: SafeArea(
        child: Stack(
          children: [
            // Background elements (optional subtle gradients here)

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),

                  // Header
                  const AutoSizeText(
                    'Unlock Full Access',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Remove limits and unleash your creativity.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 48),

                  // Features
                  _buildFeatureRow(
                    Icons.check_circle,
                    'Unlimited Word Generation',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow(Icons.check_circle, 'Unlimited Categories'),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    Icons.check_circle,
                    'Support Independent Devs',
                  ),

                  const Spacer(),

                  // Actions
                  if (_isLoading)
                    const CircularProgressIndicator(color: Color(0xFF6B5CE7))
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _purchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B5CE7),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Subscribe for \$4.99/mo', // Example Price
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _restorePurchases,
                          child: const Text(
                            'Restore Purchases',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Terms of Service  •  Privacy Policy',
                    style: TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B5CE7)),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
