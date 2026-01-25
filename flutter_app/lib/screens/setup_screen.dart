import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_screen.dart';
import '../theme/app_theme.dart';
import 'ai_category_studio_screen.dart';
import '../viewmodels/setup_view_model.dart';
import 'category_gallery_screen.dart';
import 'edit_category_screen.dart';
import 'paywall_screen.dart';
import '../services/subscription_service.dart';

/// Stitch-inspired setup screen with pastel colors and friendly layout.
///
/// Refactored to follow MVVM pattern using [SetupViewModel].
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late SetupViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SetupViewModel();
    unawaited(_viewModel.init());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _navigateToManageCategories() async {
    final result = await Navigator.push<AiCategoryResult>(
      context,
      MaterialPageRoute(
        builder: (context) => AiCategoryStudioScreen(
          existingCategoryNames: _viewModel.categoryLists.keys.toList(),
        ),
      ),
    );
    // If AiCategoryStudioScreen returns a new category, add it
    if (result != null) {
      _viewModel.addCategory(result.name, result.words);
      if (result.selectAfterSave) {
        _viewModel.selectCategory(result.name);
      }
    }
  }

  void _startGame() {
    if (_viewModel.activeWordList.isEmpty) return;

    int imposterCount = _viewModel.settings.imposterCount;
    if (_viewModel.settings.randomizeImposters) {
      // Allow 0 to total players as per user request
      final max = _viewModel.settings.playerCount + 1;
      imposterCount = Random().nextInt(max);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerCount: _viewModel.settings.playerCount,
          playerNames: _viewModel.settings.playerNames,
          imposterCountSetting: imposterCount,
          useDecoyWord: _viewModel.settings.useDecoyWord,
          showImposterHints: _viewModel.settings.showImposterHints,
          words: _viewModel.activeWordList,
          categoryMap: _viewModel.categoryMap,
          timeLimitSeconds: _viewModel.settings.timeLimitSeconds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;
    final iosBg = Theme.of(context).scaffoldBackgroundColor;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: iosBg,
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    _StickyHeader(textMain: gameColors.cardFrontTextDark),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 160),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _SectionHeader(
                            title: 'Category',
                            trailing: _AiStudioButton(
                              onTap: _navigateToManageCategories,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CategoryCard(
                            selectedCategories:
                                _viewModel.settings.selectedCategories,
                            onTap: () => _navigateToCategoryGallery(context),
                          ),
                          const SizedBox(height: 32),
                          _SectionHeader(
                            title: 'Players',
                            trailing: const _PlayerCountTag(),
                          ),
                          const SizedBox(height: 12),
                          _PlayerList(viewModel: _viewModel),
                          const SizedBox(height: 32),
                          const _SectionHeader(title: 'Imposters'),
                          const SizedBox(height: 16),
                          _ImposterSlider(viewModel: _viewModel),
                          const SizedBox(height: 32),
                          const _SectionHeader(title: 'Game Rules'),
                          const SizedBox(height: 12),
                          _GameRulesSection(viewModel: _viewModel),
                          const SizedBox(height: 32),
                          const _SectionHeader(title: 'Time Limit'),
                          const SizedBox(height: 16),
                          _DiscussionTimeSection(viewModel: _viewModel),
                        ]),
                      ),
                    ),
                  ],
                ),
                if (!isKeyboardOpen)
                  _StartButton(
                    onTap: _viewModel.activeWordList.isNotEmpty
                        ? _startGame
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToEditCategory({String? initialCategory}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(
          initialCategoryName: initialCategory,
          initialWords: initialCategory != null
              ? _viewModel.categoryLists[initialCategory] ?? []
              : [],
          onSave: (newName, newWords) {
            if (initialCategory != null && initialCategory != newName) {
              _viewModel.deleteCategory(initialCategory);
            }
            _viewModel.addCategory(newName, newWords);

            // If checking "Select after create":
            // _viewModel.toggleCategory(newName);
          },
        ),
      ),
    );
  }

  Future<void> _navigateToCategoryGallery(BuildContext context) async {
    final result = await Navigator.of(context).push<AiCategoryResult>(
      MaterialPageRoute(
        builder: (context) => ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return CategoryGalleryScreen(
              availableCategories: _viewModel.availableCategories,
              initiallySelected: _viewModel.settings.selectedCategories,
              onSelectionChanged: _viewModel.updateSelectedCategories,
              wordCounts: {
                for (var category in _viewModel.availableCategories)
                  category: _viewModel.getCategoryWordCount(category),
              },
              onDelete: _viewModel.deleteCategory,
              onCreate: () => _navigateToEditCategory(),
              onEdit: (category) =>
                  _navigateToEditCategory(initialCategory: category),
            );
          },
        ),
      ),
    );
    if (result == null) return;
    _viewModel.addCategory(result.name, result.words);
    if (result.selectAfterSave) {
      _viewModel.selectCategory(result.name);
    }
  }
}

class _StickyHeader extends StatelessWidget {
  final Color textMain;

  const _StickyHeader({required this.textMain});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 56,
      backgroundColor: Colors.white.withValues(alpha: 0.7),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: GestureDetector(
            onTap: () => _showHowToPlayDialog(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
          ),
        ),
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Imposter Finder',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
        ),
      ),
      titleSpacing: 0,
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _SubscriptionBadge(),
        ),
      ],
    );
  }

  static void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('How to Play'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HowToPlayStep(
                number: '1',
                title: 'Setup',
                description: 'Add players and choose a category.',
              ),
              SizedBox(height: 12),
              _HowToPlayStep(
                number: '2',
                title: 'Pass the Phone',
                description:
                    'Each player secretly views their word. Imposters get a different word (or no word).',
              ),
              SizedBox(height: 12),
              _HowToPlayStep(
                number: '3',
                title: 'Discuss',
                description:
                    'Take turns describing your word without saying it directly.',
              ),
              SizedBox(height: 12),
              _HowToPlayStep(
                number: '4',
                title: 'Vote',
                description: 'Vote to eliminate who you think is the Imposter!',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _HowToPlayStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _HowToPlayStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubscriptionBadge extends StatelessWidget {
  const _SubscriptionBadge();

  @override
  Widget build(BuildContext context) {
    // Import these at top of file if not already present
    final isPremium = SubscriptionService().isPremium;

    final backgroundColor = isPremium
        ? const Color(0xFFFFF8E1) // Gold tint for Pro
        : Colors.grey.shade100;
    final textColor = isPremium
        ? const Color(0xFFFF8F00) // Amber for Pro
        : Colors.grey.shade600;
    final icon = isPremium ? Icons.star : null;

    return GestureDetector(
      onTap: isPremium
          ? null
          : () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPremium ? const Color(0xFFFFD54F) : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: textColor),
              const SizedBox(width: 2),
            ],
            Text(
              isPremium ? 'PRO' : 'FREE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: gameColors.cardFrontTextDark,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _AiStudioButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AiStudioButton({required this.onTap});

  // Purple theme for AI Studio
  static const _purpleAccent = Color(0xFF9C27B0);
  static const _purpleLight = Color(0xFFF3E5F5);
  static const _purpleBorder = Color(0xFFCE93D8);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _TappableButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _purpleLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _purpleBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: _purpleAccent.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: _purpleAccent),
            const SizedBox(width: 6),
            Text(
              'AI Studio',
              style: textTheme.labelSmall?.copyWith(
                color: _purpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: _purpleAccent.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Set<String> selectedCategories;
  final VoidCallback onTap;

  static const Map<String, IconData> _categoryIcons = {
    'Animals': Icons.pets,
    'Fruits': Icons.apple,
    'Space': Icons.rocket_launch,
    'Emotions': Icons.emoji_emotions,
  };

  const _CategoryCard({required this.selectedCategories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;
    final selectedCategory = selectedCategories.isEmpty
        ? 'None'
        : selectedCategories.first;
    final icon = _categoryIcons[selectedCategory] ?? Icons.category;
    final blueAccent = Theme.of(context).colorScheme.primary;
    final softBlue = blueAccent.withValues(alpha: 0.1);

    return _TappableButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: softBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 36, color: blueAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT SELECTION',
                    style: Theme.of(
                      context,
                    ).extension<CustomTypography>()?.extraSmallLabel,
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final text = selectedCategories.length <= 1
                          ? selectedCategory
                          : '${selectedCategories.length} Categories';
                      final textStyle = textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: gameColors.cardFrontTextDark,
                      );

                      // Simple overflow handling logic preserved
                      return Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Change category...',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: blueAccent,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey.shade300,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCountTag extends StatelessWidget {
  const _PlayerCountTag();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'MIN 3 PLAYERS',
        style: textTheme.labelSmall?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  final SetupViewModel viewModel;

  const _PlayerList({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;

    // 6 distinct pastel colors for player avatars
    const avatarColors = [
      Color(0xFFFFE4E4), // Soft pink
      Color(0xFFE3F2FD), // Soft blue
      Color(0xFFE8F5E9), // Soft green
      Color(0xFFFFF3E0), // Soft orange
      Color(0xFFEDE7F6), // Soft purple
      Color(0xFFFFFDE7), // Soft yellow
    ];

    return Column(
      children: [
        ...List.generate(viewModel.settings.playerCount, (index) {
          final bgColor = avatarColors[index % avatarColors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person,
                    color: gameColors.cardFrontTextDark.withValues(alpha: 0.6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: viewModel.playerControllers[index],
                    focusNode: viewModel.playerFocusNodes[index],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Player ${index + 1}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: gameColors.cardFrontTextDark,
                    ),
                    onChanged: (value) =>
                        viewModel.updatePlayerName(index, value),
                  ),
                ),
                const SizedBox(width: 10),
                _TappableButton(
                  onTap: () => viewModel.removePlayer(index),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade300,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        }),
        if (viewModel.settings.playerCount < 12)
          _TappableButton(
            onTap: viewModel.addPlayer,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: Colors.grey.shade400, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Add Player',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImposterSlider extends StatelessWidget {
  final SetupViewModel viewModel;

  const _ImposterSlider({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Red/pink theme for Imposters section
    const imposterRed = Color(0xFFE91E63);
    const imposterPink = Color(0xFFFFE4EC);
    final isRandom = viewModel.settings.randomizeImposters;
    final maxImposters = viewModel.settings.playerCount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: imposterPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    isRandom ? '?' : '${viewModel.settings.imposterCount}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: imposterRed,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    isRandom
                        ? 'Count will be random (0-$maxImposters)'
                        : _getImposterHint(
                            viewModel.settings.imposterCount,
                            viewModel.settings.playerCount,
                          ),
                    style: textTheme.bodyMedium?.copyWith(
                      color: isRandom ? imposterRed : Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                      fontWeight: isRandom
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AbsorbPointer(
            absorbing: isRandom,
            child: Opacity(
              opacity: isRandom ? 0.3 : 1.0,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  // Blue track as shown in reference
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: Theme.of(context).colorScheme.primary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  overlayColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: viewModel.settings.imposterCount.toDouble(),
                  min: 0,
                  max: maxImposters.toDouble(),
                  divisions: maxImposters,
                  onChanged: (value) =>
                      viewModel.updateImposterCount(value.round()),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                (maxImposters + 1).clamp(0, 6),
                (i) => Text(
                  '$i',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getImposterHint(int count, int players) {
    if (count == 0) return 'No imposters mode!';
    if (count == 1) return 'Classic mode';
    if (count == 2) return 'Perfect for $players+ players!';
    return 'Chaotic fun!';
  }
}

class _GameRulesSection extends StatelessWidget {
  final SetupViewModel viewModel;

  const _GameRulesSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        _ToggleCard(
          title: 'Randomize Imposters',
          description: 'Let fate decide the imposter count',
          isEnabled: viewModel.settings.randomizeImposters,
          onToggle: viewModel.toggleRandomizeImposters,
          activeColor: secondaryColor,
          textMain: gameColors.cardFrontTextDark,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'Odd One Out',
          description: "Everyone gets a word! Find the odd one(s) out!",
          isEnabled: viewModel.settings.useDecoyWord,
          onToggle: viewModel.toggleDecoyWord,
          activeColor: secondaryColor,
          textMain: gameColors.cardFrontTextDark,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'Imposter Hints',
          description: 'Show category hints to imposters',
          isEnabled: viewModel.settings.showImposterHints,
          onToggle: viewModel.toggleImposterHints,
          activeColor: secondaryColor,
          textMain: gameColors.cardFrontTextDark,
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final Color activeColor;
  final Color textMain;

  const _ToggleCard({
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onToggle,
    required this.activeColor,
    required this.textMain,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          _TappableButton(
            onTap: () => onToggle(!isEnabled),
            child: Container(
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isEnabled ? activeColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscussionTimeSection extends StatelessWidget {
  final SetupViewModel viewModel;

  const _DiscussionTimeSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              // Yellow/orange theme for timer (matching reference)
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: Color(0xFFF9A825), // Amber/orange
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.settings.timeLimitSeconds == 0
                      ? 'No Limit'
                      : '${viewModel.settings.timeLimitSeconds ~/ 60}:${(viewModel.settings.timeLimitSeconds % 60).toString().padLeft(2, '0')}',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: gameColors.cardFrontTextDark,
                  ),
                ),
                if (viewModel.settings.timeLimitSeconds > 0)
                  Text(
                    'MINUTES',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              _TimeButton(
                icon: Icons.remove,
                onTap: () {
                  final times = [0, 60, 120, 180, 300];
                  final currentIndex = times.indexOf(
                    viewModel.settings.timeLimitSeconds,
                  );
                  if (currentIndex > 0) {
                    viewModel.updateTimeLimit(times[currentIndex - 1]);
                  }
                },
              ),
              const SizedBox(width: 8),
              _TimeButton(
                icon: Icons.add,
                onTap: () {
                  final times = [0, 60, 120, 180, 300];
                  final currentIndex = times.indexOf(
                    viewModel.settings.timeLimitSeconds,
                  );
                  if (currentIndex < times.length - 1) {
                    viewModel.updateTimeLimit(times[currentIndex + 1]);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TimeButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TappableButton(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Colors.grey.shade300, size: 20),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _StartButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final iosBg = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: MediaQuery.of(context).viewInsets.bottom > 0
            ? const Offset(0, 1)
            : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: MediaQuery.of(context).viewInsets.bottom > 0 ? 0.0 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [iosBg.withValues(alpha: 0), iosBg, iosBg],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: SafeArea(
              top: false,
              child: _TappableButton(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'START GAME',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TappableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TappableButton({required this.child, this.onTap});

  @override
  State<_TappableButton> createState() => _TappableButtonState();
}

class _TappableButtonState extends State<_TappableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _controller.reverse();
    });
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: widget.child,
      ),
    );
  }
}
