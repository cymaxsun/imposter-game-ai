import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Screen for managing word categories and AI generation.
/// Redesigned as "AI Category Studio" with integrated generation and category grid.
class ManageCategoriesScreen extends StatefulWidget {
  final Map<String, List<String>> initialCategories;

  const ManageCategoriesScreen({super.key, required this.initialCategories});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  late Map<String, List<String>> _categories;

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
    _categories = Map.from(widget.initialCategories);
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
    setState(() => _categories[name] = words);
  }

  void _updateCategory(String oldName, String newName, List<String> words) {
    setState(() {
      if (oldName != newName) _categories.remove(oldName);
      _categories[newName] = words;
    });
  }

  void _deleteCategory(String name) {
    setState(() => _categories.remove(name));
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

  void _showCategoryEditor({String? categoryName}) {
    final isEditing = categoryName != null;
    final initialName = categoryName ?? '';
    final initialWords = isEditing
        ? List<String>.from(_categories[categoryName]!)
        : <String>['', '', '', ''];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryEditorModal(
        initialName: initialName,
        initialWords: initialWords,
        onSave: (newName, newWords) {
          if (isEditing) {
            _updateCategory(initialName, newName, newWords);
          } else {
            _addCategory(newName, newWords);
          }
          // Navigator.pop(context); // Already popping in modal
        },
      ),
    );
  }

  Future<void> _confirmDelete(String categoryName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "$categoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteCategory(categoryName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "$categoryName" deleted')),
        );
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
        Navigator.of(context).pop(_categories);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 100,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(_categories),
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

                // Categories Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showCategoryEditor(),
                      child: const Text(
                        'ADD NEW',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA0AEC0),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Categories Grid
                if (_categories.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No categories yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Generate one with AI or add manually!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final name = _categories.keys.elementAt(index);
                      final wordCount = _categories[name]?.length ?? 0;
                      return _CategoryCard(
                        name: name,
                        wordCount: wordCount,
                        onTap: () => _showCategoryEditor(categoryName: name),
                        onDelete: () => _confirmDelete(name),
                      );
                    },
                  ),

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

/// Individual category card in the grid
class _CategoryCard extends StatelessWidget {
  final String name;
  final int wordCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CategoryCard({
    required this.name,
    required this.wordCount,
    required this.onTap,
    this.onDelete,
  });

  // Get an icon and color based on category name
  (IconData, Color) _getCategoryStyle(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('food') ||
        lowerName.contains('kitchen') ||
        lowerName.contains('restaurant') ||
        lowerName.contains('cook') ||
        lowerName.contains('sushi') ||
        lowerName.contains('bakery')) {
      return (Icons.restaurant, const Color(0xFF7C4DFF));
    }
    if (lowerName.contains('space') ||
        lowerName.contains('sci') ||
        lowerName.contains('robot') ||
        lowerName.contains('future')) {
      return (Icons.rocket_launch, const Color(0xFF2196F3));
    }
    if (lowerName.contains('nature') ||
        lowerName.contains('jungle') ||
        lowerName.contains('forest') ||
        lowerName.contains('animal')) {
      return (Icons.park, const Color(0xFF4CAF50));
    }
    if (lowerName.contains('castle') ||
        lowerName.contains('magic') ||
        lowerName.contains('fantasy') ||
        lowerName.contains('wizard')) {
      return (Icons.castle, const Color(0xFFE91E63));
    }
    if (lowerName.contains('movie') ||
        lowerName.contains('film') ||
        lowerName.contains('tv') ||
        lowerName.contains('cartoon')) {
      return (Icons.movie, const Color(0xFFFF9800));
    }
    if (lowerName.contains('music') ||
        lowerName.contains('song') ||
        lowerName.contains('band')) {
      return (Icons.music_note, const Color(0xFF9C27B0));
    }
    if (lowerName.contains('sport') ||
        lowerName.contains('game') ||
        lowerName.contains('play')) {
      return (Icons.sports_soccer, const Color(0xFF00BCD4));
    }
    if (lowerName.contains('travel') ||
        lowerName.contains('country') ||
        lowerName.contains('city')) {
      return (Icons.flight, const Color(0xFF3F51B5));
    }

    // Default icon
    return (Icons.category, const Color(0xFF6B5CE7));
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getCategoryStyle(name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Delete button in top-right
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),

              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.7,
                  child: FittedBox(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.15),
                                color.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Word count badge in subtitle position
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FittedBox(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.format_list_bulleted_rounded,
                                  size: 10,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$wordCount',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

/// Modal for creating/editing a category.
/// Modal for creating/editing a category.
class _CategoryEditorModal extends StatefulWidget {
  final String initialName;
  final List<String> initialWords;
  final Function(String, List<String>) onSave;

  const _CategoryEditorModal({
    required this.initialName,
    required this.initialWords,
    required this.onSave,
  });

  @override
  State<_CategoryEditorModal> createState() => _CategoryEditorModalState();
}

class _CategoryEditorModalState extends State<_CategoryEditorModal> {
  late TextEditingController _nameController;
  late TextEditingController _wordInputController;
  late List<String> _words;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _wordInputController = TextEditingController();
    _words = List.from(widget.initialWords);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wordInputController.dispose();
    super.dispose();
  }

  void _addWords(String text) {
    final newWords = text
        .split(RegExp(r'[,\n]')) // Split by comma or newline
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();

    if (newWords.isNotEmpty) {
      _words.addAll(newWords);
      _wordInputController.clear();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _removeWord(int index) {
    setState(() {
      _words.removeAt(index);
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Add any pending text in the input field as a word
    if (_wordInputController.text.isNotEmpty) {
      _addWords(_wordInputController.text);
    }

    if (_words.isEmpty) return; // Optional: Require at least one word?

    widget.onSave(name, _words);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialName.isEmpty;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Save automatically when closing (via back button, swipe, or close icon)
        _save();
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: viewInsets.bottom + 24,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isNew ? 'New Category' : 'Edit Category',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600, // Bolder
                        color: Color(0xFF2D3748), // Darker text
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATEGORY NAME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(
                              0xFF2D3748,
                            ).withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g., Space Stuff',
                              hintStyle: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Words",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Tip: Use comma/enter to add quickly',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA0AEC0),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._words.asMap().entries.map((entry) {
                          return InputChip(
                            label: Text(entry.value),
                            backgroundColor: const Color(0xFFF0F0FF),
                            labelStyle: const TextStyle(
                              color: Color(0xFF6B5CE7),
                              fontSize: 14,
                            ),
                            onDeleted: () => _removeWord(entry.key),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFF6B5CE7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: const Color(
                                  0xFF6B5CE7,
                                ).withValues(alpha: 0.2),
                              ),
                            ),
                          );
                        }),
                        Container(
                          width: 150,
                          constraints: const BoxConstraints(minWidth: 100),
                          child: TextField(
                            controller: _wordInputController,
                            onSubmitted: _addWords,
                            onChanged: (value) {
                              if (value.contains(',') || value.contains('\n')) {
                                _addWords(value);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Add words...',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
