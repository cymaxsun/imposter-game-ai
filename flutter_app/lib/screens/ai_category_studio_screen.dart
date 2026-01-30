import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';
import '../services/usage_service.dart';
import '../services/ad_service.dart';
import '../utils/ui_utils.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../theme/app_theme.dart';
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

/// Result returned from the AI studio when saving a category.
class AiCategoryResult {
  /// Creates a result for a new AI-generated category.
  const AiCategoryResult({
    this.name,
    this.words,
    this.selectAfterSave = false,
    this.openGallery = false,
    this.customIconPath,
  });

  /// The category name.
  final String? name;

  /// The generated words for the category.
  final List<String>? words;

  /// Whether the category should be selected after saving.
  final bool selectAfterSave;

  /// Whether the user requested to open the gallery (manage categories).
  final bool openGallery;

  /// The path to a custom icon image, if any.
  final String? customIconPath;
}

class _AiCategoryStudioScreenState extends State<AiCategoryStudioScreen> {
  void _showAdOrPaywallDialog() {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Out of Sparks',
      message:
          'You are out of sparks!\n\nWatch a short ad to get 1 more spark, or upgrade to Pro for unlimited access.',
      actions: [
        AlertAction(
          title: 'Cancel',
          style: AlertActionStyle.destructive,
          onPressed: () {},
        ),
        AlertAction(
          title: 'View Plans',
          style: AlertActionStyle.defaultAction,
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
          },
        ),
        AlertAction(
          title: 'Watch Ad (+1 Spark)',
          style: AlertActionStyle.primary,
          onPressed: _showRewardedAd,
        ),
      ],
    );
  }

  void _showRewardedAd() {
    if (!AdService().isAdReady) {
      showIosSnackBar(
        context,
        'Ad not ready yet. Please try again in a moment.',
        isError: true,
      );
      return;
    }

    AdService().showRewardedAd(
      onUserEarnedReward: () {
        UsageService().addSpark();
        showIosSnackBar(
          context,
          'Spark added! You can now generate a category.',
        );
      },
    );
  }

  bool _isLoading = false;
  String _errorMessage = '';
  bool _useMockData = kDebugMode;

  Timer? _loadingTimer;
  int _loadingMessageIndex = 0;

  final List<String> _loadingMessages = [
    'Connecting to AI...',
    'Analyzing topic...',
    'Brainstorming words...',
    'Filtering for Imposters...',
    'Finalizing list...',
  ];

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
    _loadingTimer?.cancel();
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

  void _startLoadingTimer() {
    _loadingMessageIndex = 0;
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _loadingMessageIndex =
              (_loadingMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  void _addCategory(
    String name,
    List<String> words, {
    required bool selectAfterSave,
    String? customIconPath,
  }) {
    if (!UsageService().canSaveCategory && !SubscriptionService().isPremium) {
      // Fixed: added isPremium check
      AdaptiveAlertDialog.show(
        context: context,
        title: 'Library Full',
        message:
            'You have reached the limit of ${UsageService().maxSavedCategories} saved categories.\n\nPlease delete an old category before saving this one.',
        actions: [
          AlertAction(
            title: 'OK',
            style: AlertActionStyle.primary,
            onPressed: () {},
          ),
        ],
      );
      return;
    }

    if (widget.existingCategoryNames.contains(name)) {
      name = _uniqueCategoryName(name);
    }

    // Return the new category
    Navigator.of(context).pop(
      AiCategoryResult(
        name: name,
        words: words,
        selectAfterSave: selectAfterSave,
        openGallery: true,
        customIconPath: customIconPath,
      ),
    );
  }

  String _uniqueCategoryName(String baseName) {
    var candidate = baseName;
    var suffix = 2;
    while (widget.existingCategoryNames.contains(candidate)) {
      candidate = '$baseName ($suffix)';
      suffix++;
    }
    return candidate;
  }

  Future<void> _showAiResultScreen({
    required String topic,
    required List<String> words,
    String? errorMessage,
  }) async {
    final displayTopic = widget.existingCategoryNames.contains(topic)
        ? _uniqueCategoryName(topic)
        : topic;
    final action = await Navigator.of(context).push<_AiResultAction>(
      MaterialPageRoute(
        builder: (_) => _AiGenerationResultScreen(
          topic: displayTopic,
          words: words,
          errorMessage: errorMessage,
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _AiResultAction.discard:
        setState(() => _topicController.clear());
        break;
      case _AiResultAction.save:
        _addCategory(displayTopic, words, selectAfterSave: false);
        setState(() => _topicController.clear());
        showIosSnackBar(context, 'Category "$displayTopic" saved!');
        break;
      case _AiResultAction.useTheme:
        _addCategory(displayTopic, words, selectAfterSave: true);
        setState(() => _topicController.clear());
        showIosSnackBar(context, 'Theme "$displayTopic" ready!');
        break;
    }
  }

  Future<void> _generateAiList({bool isRegeneration = false}) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Please enter a topic.');
      return;
    }

    if (!UsageService().canSaveCategory && !SubscriptionService().isPremium) {
      if (mounted) {
        AdaptiveAlertDialog.show(
          context: context,
          title: 'Library Full',
          message:
              'You have reached the limit of ${UsageService().maxSavedCategories} saved categories.\n\nPlease delete an old category before generating a new one.',
          actions: [
            AlertAction(
              title: 'Cancel',
              style: AlertActionStyle.destructive,
              onPressed: () {},
            ),
            /*
             ### Finite Pro Sparks
            - **Limit Implementation**: Updated `UsageService` to enforce a daily limit of **100 sparks** for Pro users. Sparks are now consumed for Pro users just like Free users, but with a significantly higher capacity.
            - **Daily Refill**: Fixed the daily refill logic to ensure Pro users correctly refill to 100 sparks at the start of each day (EST).
            - **UI Update**: Reverted the "Unlimited Sparks" text in the AI Studio. Pro users now see their actual spark count (e.g., "99 / 100"), maintaining transparency and consistency with the free version.
            */
            AlertAction(
              title: 'Maybe Later',
              style: AlertActionStyle.primary,
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(const AiCategoryResult(openGallery: true));
              },
            ),
          ],
        );
      }
      return;
    }

    if (!UsageService().canMakeRequest && !SubscriptionService().isPremium) {
      if (mounted) {
        _showAdOrPaywallDialog();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _startLoadingTimer();
    });

    try {
      // START MOCK DATA CHANGE
      // Only use mock data in debug mode if toggled on
      final bool useMockData = kDebugMode && _useMockData;

      List<String> words;
      if (useMockData) {
        await Future.delayed(
          const Duration(seconds: 2),
        ); // Simulate network delay
        words = [
          'Astronaut',
          'Rocket',
          'Moon',
          'Star',
          'Comet',
          'Galaxy',
          'Telescope',
          'Satellite',
          'Meteor',
          'Planet',
          'Nebula',
          'Black Hole',
          'Space Station',
          'Alien',
          'UFO',
        ];
      } else {
        words = await ApiService.generateWordList(topic);
      }
      // END MOCK DATA CHANGE

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _stopLoadingTimer();
      });
      if (words.isNotEmpty) {
        // Increment usage count only on success
        await UsageService().consumeSpark();
        await _showAiResultScreen(topic: topic, words: words);
      } else {
        await _showAiResultScreen(
          topic: topic,
          words: const [],
          errorMessage: 'Could not generate a list for that topic.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _stopLoadingTimer();
      });
      await _showAiResultScreen(
        topic: topic,
        words: const [],
        errorMessage: 'Error: Check connection.',
      );
    } finally {
      if (!mounted) {
        _stopLoadingTimer();
      }
    }
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
          backgroundColor: colorScheme
              .surface, // Was 0xFFF8FAFC (matches offWhiteBackground/surface)
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
          actions: [
            // Debug-only button to toggle mock data
            if (kDebugMode)
              IconButton(
                icon: Icon(
                  _useMockData ? Icons.bug_report : Icons.cloud_done,
                  color: _useMockData ? Colors.orange : Colors.green,
                ),
                tooltip: _useMockData ? 'Using Mock Data' : 'Using Real Backend',
                onPressed: () {
                  setState(() {
                    _useMockData = !_useMockData;
                  });
                  showIosSnackBar(
                    context,
                    _useMockData
                        ? 'Debug: Switched to MOCK data'
                        : 'Debug: Switched to REAL backend',
                  );
                },
              ),
            // Debug-only button to reset daily limit
            if (kDebugMode)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'Reset Daily Limit (Debug)',
                onPressed: () {
                  UsageService().resetDailyLimit();
                  showIosSnackBar(context, 'Daily limit reset!');
                },
              ),
            const SizedBox(width: 8),
          ],
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Studio',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withValues(
                          alpha: 0.9,
                        ), // Was 0xFF2D3748 (Slate 800) -> deepCharcoal is close enough
                        letterSpacing: -1.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Describe a topic or theme to create a category.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme
                            .outline, // Was 0xFF718096 (Slate 500) -> slateText
                      ), // Was 0xFF718096 (Slate 500) -> slateText
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(
                          alpha: 0.1,
                        ), // Was 0xFF6B5CE7
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.primary.withValues(
                            alpha: 0.2,
                          ), // Was 0xFF6B5CE7
                        ),
                      ),
                      child: ListenableBuilder(
                        listenable: Listenable.merge([
                          UsageService(),
                          SubscriptionService(),
                        ]),
                        builder: (context, child) {
                          final isPremium = SubscriptionService().isPremium;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPremium ? Icons.auto_awesome : Icons.bolt,
                                size: 14,
                                color: colorScheme.primary, // Was 0xFF6B5CE7
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Sparks: ${UsageService().remainingSparks} / ${UsageService().maxSparks}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary, // Was 0xFF6B5CE7
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        controller: _topicController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface, // Was 0xFF2D3748
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
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary,
                          colorScheme.primary,
                        ], // Was 0xFF8B7CF6, 0xFF6B5CE7
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(
                            alpha: 0.3,
                          ), // Was 0xFF6B5CE7
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    _loadingMessages[_loadingMessageIndex],
                                    key: ValueKey<int>(_loadingMessageIndex),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
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

enum _AiResultAction { discard, save, useTheme }

class _AiGenerationResultScreen extends StatefulWidget {
  final String topic;
  final List<String> words;
  final String? errorMessage;

  const _AiGenerationResultScreen({
    required this.topic,
    required this.words,
    this.errorMessage,
  });

  @override
  State<_AiGenerationResultScreen> createState() =>
      _AiGenerationResultScreenState();
}

class _AiGenerationResultScreenState extends State<_AiGenerationResultScreen> {
  ColorScheme get _colorScheme => Theme.of(context).colorScheme;
  CustomColors get _customColors =>
      Theme.of(context).extension<CustomColors>()!;

  static const double _actionBarHeight = 52;
  static const double _actionBarPadding = 16;

  bool _isExpanded = false;
  bool _hasOverflow = false;
  double? _infoHeight;
  double? _wordsHeight;

  Widget _buildWordChips() {
    return _MeasureSize(
      onChange: (size) {
        if (_wordsHeight != size.height) {
          setState(() => _wordsHeight = size.height);
        }
      },
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.words.map((word) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              word,
              style: TextStyle(
                color: _colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow() {
    return _MeasureSize(
      onChange: (size) {
        if (_infoHeight != size.height) {
          setState(() => _infoHeight = size.height);
        }
      },
      child: Row(
        children: [
          Icon(Icons.info, color: _colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can edit the word list after adding it to your library.',
              style: TextStyle(
                fontSize: 12,
                color: _colorScheme.outline,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleOverflowUpdate(bool value) {
    if (_hasOverflow == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _hasOverflow = value);
    });
  }

  Widget _buildCard({
    required bool constrained,
    required Color cardBackground,
    required bool hasError,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            widget.topic.isEmpty ? 'AI Theme' : widget.topic,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: _colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'THEME WORDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _colorScheme.secondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (hasError)
            Text(
              widget.errorMessage!,
              style: TextStyle(
                color: _colorScheme.surface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (constrained)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  // Assume overflow until measured, then use actual height
                  final hasOverflow =
                      (_wordsHeight ?? double.infinity) > availableHeight + 1;
                  _scheduleOverflowUpdate(hasOverflow);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRect(
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: _buildWordChips(),
                                ),
                              ),
                            ),
                            if (hasOverflow)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    height: 72,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          cardBackground.withValues(alpha: 0),
                                          cardBackground,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (hasOverflow)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isExpanded = true;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _colorScheme.primary,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.expand_more, size: 20),
                            label: const Text(
                              'See more',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWordChips(),
                if (_hasOverflow)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _colorScheme.primary,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.expand_less, size: 20),
                      label: const Text(
                        'Show less',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResultContent({
    required bool hasError,
    required Color cardBackground,
    required double bottomPadding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double horizontalPadding = 24;
        const double topPadding = 8;
        const double cardPadding = 48; // 24 top + 24 bottom in card
        const double titleHeight = 60; // Approximate title + label height
        const double spacing = 20; // Gap between card and info row

        // Calculate if content would fit naturally
        final availableHeight =
            constraints.maxHeight - bottomPadding - topPadding;
        final estimatedCardContentHeight =
            cardPadding +
            titleHeight +
            (_wordsHeight ?? double.infinity) +
            spacing +
            (_infoHeight ?? 40);

        final contentFits = estimatedCardContentHeight <= availableHeight;

        // When expanded, always use scrollable natural layout
        if (_isExpanded) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  constrained: false,
                  cardBackground: cardBackground,
                  hasError: hasError,
                ),
                const SizedBox(height: 20),
                _buildInfoRow(),
              ],
            ),
          );
        }

        // When collapsed: use natural sizing if it fits, constrained if not
        if (contentFits && _wordsHeight != null) {
          // Content fits - use natural sizing (card shrinks to content)
          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCard(
                  constrained: false,
                  cardBackground: cardBackground,
                  hasError: hasError,
                ),
                const SizedBox(height: 20),
                _buildInfoRow(),
              ],
            ),
          );
        }

        // Content overflows or not yet measured - use constrained layout
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: _buildCard(
                  constrained: true,
                  cardBackground: cardBackground,
                  hasError: hasError,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionBar({required bool hasError}) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _colorScheme.surface.withValues(alpha: 0),
                      _colorScheme.surface.withValues(alpha: 0.8),
                      _colorScheme.surface,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(_actionBarPadding),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: _actionBarHeight,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: hasError
                            ? null
                            : () => Navigator.of(
                                context,
                              ).pop(_AiResultAction.save),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size.fromHeight(_actionBarHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor:
                              _customColors.succeed, // Was _mintAccent
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: _customColors.succeed!.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                        label: const Text(
                          'Save to Library',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: _actionBarHeight,
                      height: _actionBarHeight,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_AiResultAction.discard),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.center,
                          minimumSize: const Size.fromHeight(_actionBarHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Icon(Icons.delete_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        widget.errorMessage != null && widget.errorMessage!.isNotEmpty;

    final cardBackground = Color.alphaBlend(
      _colorScheme.secondary.withValues(alpha: 0.2), // Was _lavenderAccent
      _colorScheme.surface, // Was _warmWhite
    );

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final contentBottomPadding =
        _actionBarHeight + _actionBarPadding + bottomInset + 16;

    return Scaffold(
      backgroundColor: _colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _colorScheme.surface.withValues(alpha: 0.9),
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).pop(_AiResultAction.discard),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _isExpanded
            ? Stack(
                children: [
                  Positioned.fill(
                    child: _buildResultContent(
                      hasError: hasError,
                      cardBackground: cardBackground,
                      bottomPadding: contentBottomPadding,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildActionBar(hasError: hasError),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: _buildResultContent(
                      hasError: hasError,
                      cardBackground: cardBackground,
                      bottomPadding: 8,
                    ),
                  ),
                  _buildActionBar(hasError: hasError),
                ],
              ),
      ),
    );
  }
}

class _MeasureSize extends StatefulWidget {
  const _MeasureSize({required this.onChange, required this.child});

  final ValueChanged<Size> onChange;
  final Widget child;

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      if (size == null || _oldSize == size) return;
      _oldSize = size;
      widget.onChange(size);
    });
    return widget.child;
  }
}
