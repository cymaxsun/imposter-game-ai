import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/ui_utils.dart';
import 'game_screen.dart';
import '../theme/pastel_theme.dart';
import '../theme/app_theme.dart';
import 'ai_category_studio_screen.dart';
import '../viewmodels/setup_view_model.dart';
import 'category_gallery_screen.dart';
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
    if (result != null) {
      _handleAiStudioResult(result);
      if (result.openGallery) {
        if (!mounted) return;
        _navigateToCategoryGallery(context);
      }
    }
  }

  void _handleAiStudioResult(AiCategoryResult result) {
    if (result.name != null && result.words != null) {
      _viewModel.addCategory(result.name!, result.words!);
      if (result.selectAfterSave) {
        _viewModel.selectCategory(result.name!);
      }
    }
  }

  void _startGame() {
    if (_viewModel.settings.selectedCategories.isEmpty) {
      showIosSnackBar(
        context,
        'Please select a category to start!',
        isError: true,
      );
      return;
    }

    if (_viewModel.activeWordList.isEmpty) {
      showIosSnackBar(
        context,
        'Selected categories have no words!',
        isError: true,
      );
      return;
    }

    int imposterCount = _viewModel.settings.imposterCount;
    if (_viewModel.settings.randomizeImposters) {
      // Allow 0 to total players as per user request
      final max = _viewModel.settings.playerCount + 1;
      imposterCount = Random().nextInt(max);
    }

    const animalAssets = [
      'assets/images/octopus.png',
      'assets/images/otter.png',
      'assets/images/penguin.png',
      'assets/images/shark.png',
      'assets/images/lobster.png',
      'assets/images/polarbear.png',
      'assets/images/penguin.png',
    ];

    final playerAvatars = List.generate(
      _viewModel.settings.playerCount,
      (index) => animalAssets[index % animalAssets.length],
    );

    // Build category icons map
    final Map<String, String> categoryIcons = {};
    for (final category in _viewModel.settings.selectedCategories) {
      final icon = _viewModel.getCategoryIcon(category);
      if (icon != null) {
        categoryIcons[category] = icon;
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerCount: _viewModel.settings.playerCount,
          playerNames: _viewModel.settings.playerNames,
          playerAvatars: playerAvatars,
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
                    _StickyHeader(
                      textMain: gameColors.cardFrontTextDark,
                      onHowToPlay: () => _showHowToPlayDialog(context),
                    ),
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
                            getCategoryIcon: _viewModel.getCategoryIcon,
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
                if (!isKeyboardOpen) _StartButton(onTap: _startGame),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: const _HowToPlayCard(),
          ),
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
              categoryLists: _viewModel.categoryLists,
              onCreate: (name, words, {icon}) async {
                _viewModel.addCategory(name, words, icon: icon);
              },
              onEdit: (oldName, newName, words, {icon}) async {
                _viewModel.renameCategory(oldName, newName, words, icon: icon);
              },
              onResult: _handleAiStudioResult,
              getCategoryIcon: _viewModel.getCategoryIcon,
              customIconPaths: _viewModel.customIconPaths,
              onCustomIconAdded: _viewModel.addCustomIconPath,
            );
          },
        ),
      ),
    );
    if (result == null) return;
    _handleAiStudioResult(result);
  }
}

class _StickyHeader extends StatelessWidget {
  final Color textMain;
  final VoidCallback onHowToPlay;

  const _StickyHeader({required this.textMain, required this.onHowToPlay});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      toolbarHeight: 56,
      backgroundColor: colorScheme.surface.withValues(
        alpha: 0.7,
      ), // Was Colors.white
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: GestureDetector(
            onTap: onHowToPlay,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100, // Reverted softSurface
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline,
                size: 20,
                color: colorScheme.outline, // Was Colors.grey.shade600
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade100, // Reverted softSurface
                width: 1,
              ), // Was Colors.grey.shade100
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
}

class _SubscriptionBadge extends StatelessWidget {
  const _SubscriptionBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: SubscriptionService(),
      builder: (context, _) {
        final isPremium = SubscriptionService().isPremium;

        final backgroundColor = isPremium
            ? colorScheme.tertiaryContainer.withValues(
                alpha: 0.1,
              ) // Was 0xFFFFF8E1 (Amber 50)
            : Colors.grey.shade100;
        final textColor = isPremium
            ? colorScheme
                  .tertiaryContainer // Was 0xFFFF8F00 (Amber 800) -> Using Hero Yellow
            : Colors.grey.shade600;
        final icon = isPremium ? Icons.star : null;

        return GestureDetector(
          onTap: isPremium
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPremium
                    ? colorScheme
                          .tertiaryContainer // Was 0xFFFFD54F
                    : Colors.grey.shade300,
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
      },
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final aiColors = Theme.of(context).extension<AiStudioColors>()!;

    return _TappableButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: aiColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: aiColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: aiColors.primary.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: aiColors.primary),
            const SizedBox(width: 6),
            Text(
              'AI Studio',
              style: textTheme.labelSmall?.copyWith(
                color: aiColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: aiColors.primary.withValues(alpha: 0.7),
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
  final String? Function(String) getCategoryIcon;

  static const Map<String, IconData> _categoryIcons = {
    'Animals': Icons.pets,
    'Fruits': Icons.apple,
    'Space': Icons.rocket_launch,
    'Emotions': Icons.emoji_emotions,
  };

  const _CategoryCard({
    required this.selectedCategories,
    required this.onTap,
    required this.getCategoryIcon,
  });

  IconData _getIcon(String category) {
    // Check for custom icon first
    final iconString = getCategoryIcon(category);
    if (iconString != null && iconString.startsWith('codePoint:')) {
      try {
        final codePoint = int.parse(iconString.split(':')[1]);
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      } catch (_) {}
    }
    
    // Fallback to default mapping or generic icon
    return _categoryIcons[category] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;
    final colorScheme = Theme.of(context).colorScheme;

    final selectedCategory = selectedCategories.isEmpty
        ? 'None'
        : selectedCategories.first;
    
    // Determine icon
    final iconData = _getIcon(selectedCategory);
    final iconString = getCategoryIcon(selectedCategory);
    final isCustomImage = iconString != null && iconString.startsWith('path:');
    final imagePath = isCustomImage ? iconString.substring(5) : null;

    // Using Brand Primary (Purple) to replace Blue Accent
    final brandAccent = colorScheme.primary;
    final softAccent = brandAccent.withValues(alpha: 0.1);

    return _TappableButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Reverted to white for contrast
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
                color: softAccent, // Was softBlue
                borderRadius: BorderRadius.circular(16),
              ),
              child: isCustomImage && imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(imagePath), // Requires dart:io
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                         errorBuilder: (context, error, stackTrace) => Icon(
                           Icons.broken_image,
                           size: 36,
                           color: brandAccent,
                         ),
                      ),
                    )
                  : Icon(iconData, size: 36, color: brandAccent), // Was blueAccent
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
                      color: brandAccent, // Was blueAccent
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainer, // Use new softSurface TOKEN
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.chevron_right,
                color: colorScheme.outline.withValues(
                  alpha: 0.5,
                ), // Was Colors.grey.shade300
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
    final primaryColor = Theme.of(
      context,
    ).colorScheme.primary; // Was colorScheme.primary

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

    final pastelTheme = Theme.of(context).extension<PastelTheme>()!;

    // 6 distinct pastel colors for player avatars from PastelTheme
    final avatarColors = [
      pastelTheme.pastelPink, // Soft pink
      pastelTheme.pastelBlue, // Soft blue
      pastelTheme.pastelGreen, // Soft green
      pastelTheme.pastelPeach, // Was pastelOrange
      pastelTheme.pastelLavender, // Was pastelPurple
      pastelTheme.pastelYellow, // Soft yellow (fallback)
    ];

    const animalAssets = [
      'assets/images/octopus.png',
      'assets/images/otter.png',
      'assets/images/penguin.png',
      'assets/images/shark.png',
      'assets/images/lobster.png',
      'assets/images/polarbear.png',
    ];

    return Column(
      children: [
        ...List.generate(viewModel.settings.playerCount, (index) {
          final bgColor = avatarColors[index % avatarColors.length];
          final animalAsset = animalAssets[index % animalAssets.length];

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
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Transform.scale(
                      scale: 1.3,
                      child: Image.asset(animalAsset, fit: BoxFit.contain),
                    ),
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
    final customColors = Theme.of(context).extension<CustomColors>()!;
    // Red/pink theme for Imposters section
    final imposterRed = customColors.warn; // Was 0xFFE91E63 (Pink) -> RedAccent
    final imposterPink = customColors.warn!.withValues(
      alpha: 0.1,
    ); // Was 0xFFFFE4EC -> RedAccent 10%
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
                  activeTrackColor: Theme.of(
                    context,
                  ).colorScheme.primary, // Was colorScheme.primary
                  inactiveTrackColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer, // Use new softSurface TOKEN
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

    return Column(
      children: [
        _ToggleCard(
          title: 'Randomize Imposters',
          description: 'Let fate decide the imposter count',
          isEnabled: viewModel.settings.randomizeImposters,
          onToggle: viewModel.toggleRandomizeImposters,
          activeColor: Theme.of(context).colorScheme.primary,
          textMain: gameColors.cardFrontTextDark,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'Odd One Out',
          description: "Everyone gets a word! Find the odd one(s) out!",
          isEnabled: viewModel.settings.useDecoyWord,
          onToggle: viewModel.toggleDecoyWord,
          activeColor: Theme.of(context).colorScheme.primary,
          textMain: gameColors.cardFrontTextDark,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          title: 'Imposter Hints',
          description: 'Show category hints to imposters',
          isEnabled: viewModel.settings.showImposterHints,
          onToggle: viewModel.toggleImposterHints,
          activeColor: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.outline.withValues(
                      alpha: 0.7,
                    ), // Was Colors.grey.shade400
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
                color: isEnabled
                    ? activeColor
                    : Theme.of(context)
                          .colorScheme
                          .surfaceContainer, // Use new softSurface TOKEN
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surface, // Was Colors.white
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
              color: Theme.of(context).colorScheme.tertiaryContainer.withValues(
                alpha: 0.1,
              ), // Was 0xFFFFF3E0
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: Theme.of(
                context,
              ).colorScheme.tertiaryContainer, // Was 0xFFF9A825
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
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainer, // Was Colors.grey.shade50
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.outline.withValues(
            alpha: 0.5,
          ), // Was Colors.grey.shade300
          size: 20,
        ),
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
    final primaryColor = Theme.of(
      context,
    ).colorScheme.primary; // Was colorScheme.primary

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

class _HowToPlayCard extends StatelessWidget {
  const _HowToPlayCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How to Play',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStep(
            context,
            '1',
            'Setup',
            'Add players and choose a category.',
            colorScheme.primary,
          ),
          const SizedBox(height: 20),
          _buildStep(
            context,
            '2',
            'Pass the Phone',
            'Secrets revealed! Imposters get different words.',
            colorScheme.secondary,
          ),
          const SizedBox(height: 20),
          _buildStep(
            context,
            '3',
            'Discuss',
            'Describe your word without giving it away.',
            colorScheme.tertiary,
          ),
          const SizedBox(height: 20),
          _buildStep(
            context,
            '4',
            'Vote',
            'Eliminate the Imposter!',
            colorScheme.error,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    String title,
    String description,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
