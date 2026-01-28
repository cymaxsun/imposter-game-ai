import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_category_screen.dart';
import 'ai_category_studio_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme/pastel_theme.dart';

import '../services/usage_service.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';
import 'package:collection/collection.dart';

class CategoryGalleryScreen extends StatefulWidget {
  final List<String> availableCategories;
  final Set<String> initiallySelected;
  final ValueChanged<Set<String>> onSelectionChanged;
  final Map<String, int> wordCounts;
  final ValueChanged<String> onDelete;
  final Map<String, List<String>> categoryLists;
  final Future<void> Function(String, List<String>)? onCreate;
  final Future<void> Function(String, String, List<String>)? onEdit;
  final ValueChanged<AiCategoryResult>? onResult;

  const CategoryGalleryScreen({
    super.key,
    required this.availableCategories,
    required this.initiallySelected,
    required this.onSelectionChanged,
    required this.wordCounts,
    required this.onDelete,
    required this.categoryLists,
    this.onCreate,
    this.onEdit,
    this.onResult,
  });

  @override
  State<CategoryGalleryScreen> createState() => _CategoryGalleryScreenState();
}

class _CategoryGalleryScreenState extends State<CategoryGalleryScreen>
    with SingleTickerProviderStateMixin {
  late Set<String> _selectedCategories;
  late List<String> _localCategories;
  bool _isEditMode = false;
  late AnimationController _jiggleController;

  String _searchQuery = '';
  final String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.initiallySelected);
    _localCategories = List.from(widget.availableCategories);
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _jiggleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryGalleryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync available categories
    if (widget.availableCategories.length !=
            oldWidget.availableCategories.length ||
        !_areListsEqual(
          widget.availableCategories,
          oldWidget.availableCategories,
        )) {
      setState(() {
        _localCategories = List.from(widget.availableCategories);
      });
    }

    // Sync selection from parent if it changed (e.g. after a rename/delete refactor)
    if (!const SetEquality<String>().equals(
      widget.initiallySelected,
      oldWidget.initiallySelected,
    )) {
      setState(() {
        _selectedCategories = Set.from(widget.initiallySelected);
      });
    }
  }

  bool _areListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _jiggleController.repeat(reverse: true);
      } else {
        _jiggleController.stop();
        _jiggleController.reset();
      }
    });
  }

  void _handleManualCreate() {
    _navigateToEditor();
  }

  void _toggleSelection(String category) {
    if (_isEditMode) return;

    setState(() {
      if (_selectedCategories.contains(category)) {
        if (_selectedCategories.length > 1) {
          // Prevent deselecting last one? Optional
          _selectedCategories.remove(category);
        }
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _deleteCategory(String category) {
    widget.onDelete(category);
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      }
      _localCategories.remove(category);
    });
  }

  Future<void> _confirmDelete(String category) async {
    bool confirmed = false;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Delete Category?',
      message:
          'Are you sure you want to delete "$category"?\nThis cannot be undone.',
      actions: [
        AlertAction(
          title: 'Cancel',
          style: AlertActionStyle.primary,
          onPressed: () => confirmed = false,
        ),
        AlertAction(
          title: 'Delete',
          style: AlertActionStyle.destructive,
          onPressed: () => confirmed = true,
        ),
      ],
    );

    if (confirmed) {
      _deleteCategory(category);
    }
  }

  void _onConfirm() {
    widget.onSelectionChanged(_selectedCategories);
    Navigator.of(context).pop();
  }

  Future<void> _navigateToEditor({String? categoryName}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(
          initialCategoryName: categoryName,
          initialWords: categoryName != null
              ? widget.categoryLists[categoryName] ?? []
              : [],
          onSave: (name, words) {
            if (categoryName == null) {
              widget.onCreate?.call(name, words);
            } else {
              // This is the onEdit case.
              // The actual logic for remembering selection and updating it
              // should be handled by the parent's onEdit callback (widget.onEdit).
              // This screen just passes the old and new names, and the words.
              widget.onEdit?.call(categoryName, name, words);
            }
          },
        ),
      ),
    );
  }

  void _navigateToAiStudio() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AiCategoryStudioScreen(
              existingCategoryNames: widget.availableCategories,
            ),
          ),
        )
        .then((result) {
          if (result != null && result is AiCategoryResult) {
            if (widget.onResult != null) {
              widget.onResult!(result);
            } else {
              Navigator.pop(context, result);
            }
          }
        });
  }

  List<String> get _filteredCategories {
    return _localCategories.where((category) {
      final matchesSearch = category.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      if (!matchesSearch) return false;

      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Popular') {
        return (widget.wordCounts[category] ?? 0) > 10;
      }

      // Simple name matching for other chips
      return category == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pastelTheme = Theme.of(context).extension<PastelTheme>()!;
    final colors = [
      pastelTheme.pastelBlue,
      pastelTheme.pastelPink,
      pastelTheme.pastelYellow,
      pastelTheme.pastelLavender,
      pastelTheme.pastelMint,
      pastelTheme.pastelPeach,
      pastelTheme.pastelGreen,
    ];

    final filteredList = _filteredCategories;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context, pastelTheme),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    120,
                  ), // Increased padding
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20, // Increased spacing
                    mainAxisSpacing: 20, // Increased spacing
                    childAspectRatio: 0.9,
                  ),
                  itemCount: filteredList.length + (_isEditMode ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isEditMode && index == 0) {
                      final canCreate =
                          UsageService().canSaveCategory ||
                          SubscriptionService().isPremium;

                      if (!canCreate) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PaywallScreen(),
                              ),
                            );
                          },
                          child: const _CreateCategoryCard(),
                        );
                      }

                      return AdaptivePopupMenuButton.widget<String>(
                        items: [
                          AdaptivePopupMenuItem(
                            label: 'Write Manually',
                            icon: PlatformInfo.isIOS26OrHigher()
                                ? 'pencil'
                                : Icons.edit_note,
                            value: 'manual',
                          ),
                          AdaptivePopupMenuItem(
                            label: 'AI Studio',
                            icon: PlatformInfo.isIOS26OrHigher()
                                ? 'sparkles'
                                : Icons.auto_awesome,
                            value: 'ai',
                          ),
                        ],
                        onSelected: (idx, item) {
                          if (item.value == 'manual') {
                            _handleManualCreate();
                          } else if (item.value == 'ai') {
                            _navigateToAiStudio();
                          }
                        },
                        child: const _CreateCategoryCard(),
                      );
                    }

                    final adjustedIndex = _isEditMode ? index - 1 : index;
                    final category = filteredList[adjustedIndex];

                    // Cycle colors based on original index to keep stability
                    final colorIndex = widget.availableCategories.indexOf(
                      category,
                    );
                    final color = colors[colorIndex % colors.length];

                    return AnimatedBuilder(
                      animation: _jiggleController,
                      builder: (context, child) {
                        final isEven = adjustedIndex % 2 == 0;
                        final rotation = _isEditMode
                            ? sin(_jiggleController.value * 2 * pi) *
                                  (isEven ? 0.015 : -0.015)
                            : 0.0;
                        return Transform.rotate(
                          angle: rotation,
                          child: _CategoryCard(
                            category: category,
                            wordCount: widget.wordCounts[category] ?? 0,
                            isSelected: _selectedCategories.contains(category),
                            isEditMode: _isEditMode,
                            color: color,
                            onTap: () async {
                              if (_isEditMode) {
                                await _navigateToEditor(categoryName: category);
                                if (mounted) {
                                  setState(() {
                                    _isEditMode = false;
                                    _jiggleController.stop();
                                    _jiggleController.reset();
                                  });
                                }
                              } else {
                                _toggleSelection(category);
                              }
                            },
                            onDelete: () => _confirmDelete(category),
                            pastelTheme: pastelTheme,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFooter(context, pastelTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PastelTheme pastelTheme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: AutoSizeText(
                    _isEditMode ? 'Manage Categories' : 'Select Category',
                    maxLines: 1,
                    minFontSize: 12,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.splineSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: _toggleEditMode,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      _isEditMode ? Icons.check : Icons.edit,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!_isEditMode) const SizedBox(height: 12),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search categories...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.4),
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (!_isEditMode) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.inventory_2,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  ListenableBuilder(
                    listenable: SubscriptionService(),
                    builder: (context, _) {
                      return Text(
                        SubscriptionService().isPremium
                            ? '${UsageService().savedCategoryCount}'
                            : '${UsageService().savedCategoryCount} / '
                                  '${UsageService().maxSavedCategories}',
                        style: GoogleFonts.splineSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 16),
            Text(
              'Tap any card to edit its name or words',
              style: GoogleFonts.splineSans(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, PastelTheme pastelTheme) {
    if (_isEditMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          child: Text(
            'Confirm Selection',
            style: GoogleFonts.splineSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final int wordCount;
  final bool isSelected;
  final bool isEditMode;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final PastelTheme pastelTheme;

  const _CategoryCard({
    required this.category,
    required this.wordCount,
    required this.isSelected,
    required this.isEditMode,
    required this.color,
    required this.onTap,
    required this.onDelete,
    required this.pastelTheme,
  });

  IconData _getIcon() {
    // Simple mapping for demo, would be dynamic in real app
    switch (category) {
      case 'Space':
        return Icons.rocket_launch;
      case 'Desserts':
      case 'Food':
      case 'Fruits':
        return Icons.bakery_dining;
      case 'Animals':
        return Icons.pets;
      case 'Heroes':
        return Icons.masks;
      case 'Sports':
        return Icons.sports_basketball;
      case 'Travel':
        return Icons.flight_takeoff;
      case 'Movies':
        return Icons.movie;
      case 'Nature':
        return Icons.forest;
      case 'Science':
        return Icons.science;
      case 'Coffee':
        return Icons.coffee;
      case 'Music':
        return Icons.music_note;
      case 'Cars':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: isEditMode
                  ? null // Handled by CustomPaint
                  : (isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          )
                        : null),
              boxShadow: isEditMode || isSelected
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: CustomPaint(
              foregroundPainter: isEditMode
                  ? _DashedBorderPainter(
                      color: Colors.black.withOpacity(0.2),
                      strokeWidth: 2,
                      gap: 6,
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcon(),
                    size: 32,
                    color: Colors.black.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: AutoSizeText(
                      category,
                      style: GoogleFonts.splineSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      minFontSize: 9,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Edit Mode: Delete Badge (Top Left)
          if (isEditMode)
            Positioned(
              top: -8,
              left: -8,
              child: GestureDetector(
                onTap: () {
                  onDelete();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32, // Larger accessible touch target
                  height: 32,
                  alignment: Alignment.topLeft,
                  color: Colors.transparent, // Ensure it catches taps
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: pastelTheme.softCoral,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // Select Mode: Badge Count (Top Right)
          if (!isEditMode)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$wordCount',
                  style: GoogleFonts.splineSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
            ),

          // Select Mode: Checkmark (Bottom Right)
          if (!isEditMode && isSelected)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateCategoryCard extends StatelessWidget {
  const _CreateCategoryCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: colorScheme.outline.withValues(alpha: 0.5),
          strokeWidth: 2,
          gap: 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.outline,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Create New',
              style: GoogleFonts.splineSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16),
        ),
      );

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = gap;
        if (distance + len < metric.length) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += (len * 2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
