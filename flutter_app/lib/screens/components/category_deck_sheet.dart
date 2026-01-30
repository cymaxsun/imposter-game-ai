import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// A split-view modal for selecting game categories.
///
/// Features:
/// - Top Rail ("Deck"): Shows currently selected categories.
/// - Bottom Grid ("Store"): Shows all available categories.
class CategoryDeckSheet extends StatelessWidget {
  final List<String> availableCategories;
  final Set<String> selectedCategories;
  final ValueChanged<String> onToggle;

  const CategoryDeckSheet({
    super.key,
    required this.availableCategories,
    required this.selectedCategories,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle (Optional, but keeping for aesthetic consistency)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Categories',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface, // Was 0xFF2D3436
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurface,
                  ), // Was 0xFF2D3436
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 1. Deck Rail (Selected Items)
          if (selectedCategories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Your Deck (${selectedCategories.length})',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.9, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = selectedCategories.elementAt(index);
                    return _DeckItemCard(
                      category: category,
                      onRemove: () => onToggle(category),
                    );
                  },
                ),
              ),
            ),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.9, // Spans 90% of the screen
                child: Divider(height: 32, color: Colors.grey.shade200),
              ),
            ),
          ],

          // 2. Available Grid (Store)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Available Categories',
              style: textTheme.labelLarge?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: availableCategories.length,
              itemBuilder: (context, index) {
                final category = availableCategories[index];
                final isSelected = selectedCategories.contains(category);
                return _CategoryGridCard(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => onToggle(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact card representing a selected category in the "Deck".
class _DeckItemCard extends StatelessWidget {
  final String category;
  final VoidCallback onRemove;

  const _DeckItemCard({required this.category, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(
            alpha: 0.1,
          ), // Was 0xFFF0F4FF (Light blue tint) -> Primary Brand 10%
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary,
            width: 1.5,
          ), // Was 0xFF6C5CE7
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: AutoSizeText(
                category,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.primary, // Was 0xFF6C5CE7
                ),
                maxLines: 1,
                minFontSize: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 16,
              color: colorScheme.primary,
            ), // Was 0xFF6C5CE7
          ],
        ),
      ),
    );
  }
}

/// A card representing an available category in the grid.
class _CategoryGridCard extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  static const Map<String, IconData> _categoryIcons = {
    'Animals': Icons.pets,
    'Fruits': Icons.apple,
    'Space': Icons.rocket_launch,
    'Emotions': Icons.emoji_emotions,
  };

  const _CategoryGridCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category] ?? Icons.category;
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: isSelected
                          ? Colors.grey.shade400
                          : colorScheme.onSurface, // Was 0xFF2D3436
                    ),
                    const SizedBox(height: 8),
                    AutoSizeText(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected
                            ? Colors.grey.shade400
                            : colorScheme.onSurface, // Was 0xFF2D3436
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: customColors.succeed!, // Was Colors.green
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
