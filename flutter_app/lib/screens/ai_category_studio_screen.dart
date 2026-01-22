import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';
import '../services/usage_service.dart';
import 'paywall_screen.dart';

/// Screen for managing word categories and AI generation.
/// Redesigned as "AI Category Studio" with integrated generation and category grid.
class AiCategoryStudioScreen extends StatefulWidget {
  final List<String> existingCategoryNames;

  const AiCategoryStudioScreen({
    super.key,
    required this.existingCategoryNames,
  });

  @override
  State<AiCategoryStudioScreen> createState() => _AiCategoryStudioScreenState();
}

class _AiCategoryStudioScreenState extends State<AiCategoryStudioScreen> {
  void _showLimitDialog(String title, String content) {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
    });
  }

  bool _isLoading = false;
  String _errorMessage = '';

  final TextEditingController _topicController = TextEditingController();

  // Tips to show in the Creator Tip section
  static const List<String> _creatorTips = [
    'Niche categories work best for Imposter Finder! Try "Items in a 1920s detective\'s office".',
    'The more specific your theme, the more challenging the game becomes!',
    'Try combining two unrelated topics for unique categories.',
    'Historical themes like "Victorian era inventions" create engaging gameplay.',
    'Pop culture references make great categories for themed parties!',
  ];

  String _currentTip = _creatorTips[0];

  @override
  void initState() {
    super.initState();
    // _categories = Map.from(widget.initialCategories); // No longer needed
    _shuffleTip();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _shuffleTip() {
    final tips = List<String>.from(_creatorTips);
    tips.shuffle();
    setState(() {
      _currentTip = tips.first;
    });
  }

  void _addCategory(String name, List<String> words) {
    if (!UsageService().canSaveCategory && !SubscriptionService().isPremium) {
      // Fixed: added isPremium check
      _showLimitDialog(
        'Category Limit Reached',
        'You can only save up to 20 categories with a free account.',
      );
      return;
    }

    // Check for duplicate name
    if (widget.existingCategoryNames.contains(name)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "$name" already exists.')),
        );
      }
      return;
    }

    // Return the new category
    Navigator.of(context).pop(MapEntry(name, words));
  }

  Future<void> _generateAiList({bool isRegeneration = false}) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Please enter a topic.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final words = await ApiService.generateWordList(topic);
      if (mounted) {
        if (words.isNotEmpty) {
          // Show generated words in a bottom sheet
          _showGeneratedWordsSheet(topic, words);
        } else {
          setState(
            () => _errorMessage = 'Could not generate a list for that topic.',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error: Check connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGeneratedWordsSheet(String topic, List<String> words) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GeneratedWordsSheet(
        topic: topic,
        words: words,
        onDiscard: () {
          Navigator.pop(context);
          setState(() => _topicController.clear());
        },
        onRetry: () {
          Navigator.pop(context);
          _generateAiList(isRegeneration: true);
        },
        onSave: () {
          _addCategory(topic, words);
          Navigator.pop(context);
          setState(() => _topicController.clear());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Category "$topic" saved!')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          centerTitle: true,
          scrolledUnderElevation: 0,
          leadingWidth: 120,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_back_ios,
                  color: colorScheme.primary,
                  size: 20,
                ),
                Text(
                  'Back',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Animated Hero Header

                // Simple Hero Header
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Studio',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3748),
                        letterSpacing: -1.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Describe a topic or theme to create a category.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Input Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _topicController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g., Things found in a bakery, items in a wizard\'s pocket, or 90\'s cartoons...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI POWERED',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 16),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B7CF6), Color(0xFF6B5CE7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B5CE7).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateAiList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bolt, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Generate with AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const SizedBox(height: 24),

                // Creator Tip Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFFFB300),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'CREATOR TIP',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _shuffleTip,
                                  child: Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                _currentTip,
                                key: ValueKey<String>(_currentTip),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF718096),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for viewing generated words
class _GeneratedWordsSheet extends StatelessWidget {
  final String topic;
  final List<String> words;
  final VoidCallback onDiscard;
  final VoidCallback onRetry;
  final VoidCallback onSave;

  const _GeneratedWordsSheet({
    required this.topic,
    required this.words,
    required this.onDiscard,
    required this.onRetry,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    // Determine category count from passed list for usage check display if needed
    // But mainly we rely on checking limit in _addCategory
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Generated: $topic',
                    style: const TextStyle(
                      color: Color(0xFF6B5CE7),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onDiscard,
                icon: const Icon(Icons.close, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: words.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDiscard,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFF6B5CE7)),
                    foregroundColor: const Color(0xFF6B5CE7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B7CF6), Color(0xFF6B5CE7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Save to Library',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}
