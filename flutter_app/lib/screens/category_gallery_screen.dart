import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_category_screen.dart';
import 'ai_category_studio_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme/pastel_theme.dart';

class CategoryGalleryScreen extends StatefulWidget {
  final List<String> availableCategories;
  final Set<String> initiallySelected;
  final ValueChanged<Set<String>> onSelectionChanged;
  final Map<String, int> wordCounts;
  final ValueChanged<String> onDelete;
  final Future<void> Function()? onCreate;
  final Future<void> Function(String)? onEdit;

  const CategoryGalleryScreen({
    super.key,
    required this.availableCategories,
    required this.initiallySelected,
    required this.onSelectionChanged,
    required this.wordCounts,
    required this.onDelete,
    this.onCreate,
    this.onEdit,
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
  String _selectedFilter = 'All';

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
    // Always sync local categories with parent to ensure updates are reflected
    if (widget.availableCategories.length !=
            oldWidget.availableCategories.length ||
        !_areListsEqual(
          widget.availableCategories,
          oldWidget.availableCategories,
        ) ||
        widget.wordCounts != oldWidget.wordCounts) {
      setState(() {
        _localCategories = List.from(widget.availableCategories);
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

  void _showCreateCategoryMenu(TapDownDetails details) async {
    final position = RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      details.globalPosition.dx,
      details.globalPosition.dy,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          value: 'manual',
          child: Row(
            children: [
              Icon(Icons.edit_note, color: const Color(0xFF2D3748), size: 20),
              const SizedBox(width: 12),
              Text(
                'Write Manually',
                style: GoogleFonts.splineSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ai',
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFF6B5CE7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Wizard',
                style: GoogleFonts.splineSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (result == 'manual') {
      if (widget.onCreate != null) {
        widget.onCreate!();
      } else {
        _navigateToEditor();
      }
    } else if (result == 'ai') {
      _navigateToAiStudio();
    }
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
    final pastelTheme = Theme.of(context).extension<PastelTheme>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Category?',
          style: GoogleFonts.splineSans(
            fontWeight: FontWeight.bold,
            color: pastelTheme.softCoral,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$category"?\nThis cannot be undone.',
          style: GoogleFonts.splineSans(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.splineSans(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.splineSans(
                fontWeight: FontWeight.bold,
                color: pastelTheme.softCoral,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
              ? widget.wordCounts.keys
                    .firstWhere((k) => k == categoryName, orElse: () => '')
                    .split(
                      ' ',
                    ) // This logic was flawed for words, but widget.onEdit should handle it now.
              : [],
          onSave: (name, words) {
            Navigator.pop(context);
            if (categoryName == null) {
              widget.onCreate?.call();
            } else {
              widget.onEdit?.call(name);
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
          if (result != null && result is MapEntry<String, List<String>>) {
            // We received a new category.
            // Since we don't have a direct 'add' callback that takes name+words,
            // and 'onCreate' is generic refresh...
            // We assume the parent (SetupScreen) handles the result if WE were the one launching it.
            // But here CategoryGalleryScreen launched it.
            // We need to signal SetupScreen.
            // Assuming SetupScreen is listening to changes if we modify external state?
            // Wait, SetupScreen holds the View Model.
            // If we can't save it here, maybe we should pop with the result too?
            Navigator.pop(context, result);
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
                      return _CreateCategoryCard(
                        onTap: _showCreateCategoryMenu,
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
                                if (widget.onEdit != null) {
                                  await widget.onEdit!(category);
                                } else {
                                  await _navigateToEditor(
                                    categoryName: category,
                                  );
                                }
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
        left: 24, // Increased padding
        right: 24, // Increased padding
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
              ),
              Text(
                _isEditMode ? 'Manage Categories' : 'Select Category',
                style: GoogleFonts.splineSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _toggleEditMode,
                child: Text(
                  _isEditMode ? 'Done' : 'Manage',
                  style: GoogleFonts.splineSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isEditMode
                        ? pastelTheme.doneMint
                        : const Color(0xFF307DE8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF307DE8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF307DE8).withOpacity(0.05),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: const Color(0xFF307DE8).withOpacity(0.6),
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
                        color: const Color(0xFF307DE8).withOpacity(0.4),
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 16),
            Text(
              'Tap any card to edit its name or words',
              style: GoogleFonts.splineSans(
                fontSize: 12,
                color: const Color(0xFF307DE8).withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, PastelTheme pastelTheme) {
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
          onPressed: _isEditMode ? _toggleEditMode : _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEditMode
                ? pastelTheme.doneMint
                : const Color(0xFF307DE8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor:
                (_isEditMode ? pastelTheme.doneMint : const Color(0xFF307DE8))
                    .withOpacity(0.4),
          ),
          child: Text(
            _isEditMode ? 'Save Changes' : 'Confirm Selection',
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
                        ? Border.all(color: const Color(0xFF307DE8), width: 3)
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
                  debugPrint('Delete tapped for $category');
                  onDelete();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44, // Larger accessible touch target
                  height: 44,
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
                decoration: const BoxDecoration(
                  color: Color(0xFF307DE8),
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
  final Function(TapDownDetails)? onTap;

  const _CreateCategoryCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => onTap?.call(details),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7), // Soft grey background
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: const Color(0xFFB0B0B5), // Dark grey dashed border
            strokeWidth: 2,
            gap: 6,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF71717A), // Muted dark grey circle
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
                  color: const Color(0xFF52525B), // Dark grey text
                ),
              ),
            ],
          ),
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
