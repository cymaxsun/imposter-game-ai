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
          Navigator.pop(context);
        },
        onDelete: isEditing
            ? () {
                _deleteCategory(initialName);
                Navigator.pop(context);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.of(context).pop(_categories);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Same as setup screen
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: colorScheme.primary,
              size: 20 * scaleFactor,
            ),
            onPressed: () => Navigator.of(context).pop(_categories),
          ),
          title: Text(
            'AI Category Studio',
            style: TextStyle(
              color: const Color(0xFF6B5CE7),
              fontWeight: FontWeight.w600,
              fontSize: 18 * scaleFactor,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16 * scaleFactor),

                // Header Section
                Text(
                  'Describe your theme',
                  style: TextStyle(
                    fontSize: 24 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  'What should players identify in "Imposter Finder"?',
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16 * scaleFactor),

                // Input Card
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10 * scaleFactor,
                        offset: Offset(0, 4 * scaleFactor),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _topicController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          color: const Color(0xFF2D3748),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g., Things found in a bakery, items in a wizard\'s pocket, or 90\'s cartoons...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15 * scaleFactor,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14 * scaleFactor,
                            color: Colors.grey[400],
                          ),
                          SizedBox(width: 4 * scaleFactor),
                          Text(
                            'AI POWERED',
                            style: TextStyle(
                              fontSize: 11 * scaleFactor,
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
                  SizedBox(height: 8 * scaleFactor),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13 * scaleFactor,
                    ),
                  ),
                ],

                SizedBox(height: 16 * scaleFactor),

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
                      borderRadius: BorderRadius.circular(28 * scaleFactor),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B5CE7).withValues(alpha: 0.3),
                          blurRadius: 12 * scaleFactor,
                          offset: Offset(0, 4 * scaleFactor),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateAiList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          vertical: 16 * scaleFactor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28 * scaleFactor),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20 * scaleFactor,
                              width: 20 * scaleFactor,
                              child: CircularProgressIndicator(
                                strokeWidth: 2 * scaleFactor,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: Colors.white,
                                  size: 20 * scaleFactor,
                                ),
                                SizedBox(width: 8 * scaleFactor),
                                Text(
                                  'Generate with AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16 * scaleFactor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                SizedBox(height: 28 * scaleFactor),

                // Categories Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8 * scaleFactor,
                          height: 8 * scaleFactor,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6B5CE7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8 * scaleFactor),
                        Text(
                          'Your Categories',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _showCategoryEditor(),
                      child: Text(
                        'ADD NEW',
                        style: TextStyle(
                          fontSize: 12 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12 * scaleFactor),

                // Categories Grid
                if (_categories.isEmpty)
                  Container(
                    padding: EdgeInsets.all(32 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 48 * scaleFactor,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 12 * scaleFactor),
                          Text(
                            'No categories yet',
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4 * scaleFactor),
                          Text(
                            'Generate one with AI or add manually!',
                            style: TextStyle(
                              fontSize: 13 * scaleFactor,
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12 * scaleFactor,
                      mainAxisSpacing: 12 * scaleFactor,
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
                      );
                    },
                  ),

                SizedBox(height: 24 * scaleFactor),

                // Creator Tip Section
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8 * scaleFactor,
                        offset: Offset(0, 2 * scaleFactor),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8 * scaleFactor),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: const Color(0xFFFFB300),
                          size: 20 * scaleFactor,
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CREATOR TIP',
                              style: TextStyle(
                                fontSize: 11 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4 * scaleFactor),
                            Text(
                              _currentTip,
                              style: TextStyle(
                                fontSize: 13 * scaleFactor,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32 * scaleFactor),
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

  const _CategoryCard({
    required this.name,
    required this.wordCount,
    required this.onTap,
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

  String _getCategoryLabel(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('food') ||
        lowerName.contains('kitchen') ||
        lowerName.contains('restaurant') ||
        lowerName.contains('cook') ||
        lowerName.contains('sushi') ||
        lowerName.contains('bakery')) {
      return 'KITCHEN';
    }
    if (lowerName.contains('space') ||
        lowerName.contains('sci') ||
        lowerName.contains('robot') ||
        lowerName.contains('future')) {
      return 'SCI-FI';
    }
    if (lowerName.contains('nature') ||
        lowerName.contains('jungle') ||
        lowerName.contains('forest') ||
        lowerName.contains('animal')) {
      return 'NATURE';
    }
    if (lowerName.contains('castle') ||
        lowerName.contains('magic') ||
        lowerName.contains('fantasy') ||
        lowerName.contains('wizard')) {
      return 'FANTASY';
    }
    if (lowerName.contains('movie') ||
        lowerName.contains('film') ||
        lowerName.contains('tv') ||
        lowerName.contains('cartoon')) {
      return 'ENTERTAINMENT';
    }
    if (lowerName.contains('music') ||
        lowerName.contains('song') ||
        lowerName.contains('band')) {
      return 'MUSIC';
    }
    if (lowerName.contains('sport') ||
        lowerName.contains('game') ||
        lowerName.contains('play')) {
      return 'SPORTS';
    }
    if (lowerName.contains('travel') ||
        lowerName.contains('country') ||
        lowerName.contains('city')) {
      return 'TRAVEL';
    }

    return '$wordCount WORDS';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);
    final (icon, color) = _getCategoryStyle(name);
    final label = _getCategoryLabel(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8 * scaleFactor,
              offset: Offset(0, 2 * scaleFactor),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12 * scaleFactor),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12 * scaleFactor),
              ),
              child: Icon(icon, color: color, size: 28 * scaleFactor),
            ),
            SizedBox(height: 12 * scaleFactor),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 4 * scaleFactor),
            Text(
              label,
              style: TextStyle(
                fontSize: 10 * scaleFactor,
                color: color,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24 * scaleFactor),
        ),
      ),
      padding: EdgeInsets.all(24 * scaleFactor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF4CAF50),
                size: 24 * scaleFactor,
              ),
              SizedBox(width: 8 * scaleFactor),
              Expanded(
                child: Text(
                  'Generated: $topic',
                  style: TextStyle(
                    color: const Color(0xFF6B5CE7),
                    fontWeight: FontWeight.bold,
                    fontSize: 18 * scaleFactor,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDiscard,
                icon: Icon(Icons.close, size: 24 * scaleFactor),
              ),
            ],
          ),
          SizedBox(height: 16 * scaleFactor),
          Wrap(
            spacing: 8 * scaleFactor,
            runSpacing: 8 * scaleFactor,
            children: words.map((word) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scaleFactor,
                  vertical: 8 * scaleFactor,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    color: const Color(0xFF2D3748),
                    fontSize: 14 * scaleFactor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24 * scaleFactor),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDiscard,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text('Discard'),
                ),
              ),
              SizedBox(width: 12 * scaleFactor),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, size: 18 * scaleFactor),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                    ),
                    side: const BorderSide(color: Color(0xFF6B5CE7)),
                    foregroundColor: const Color(0xFF6B5CE7),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scaleFactor),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B7CF6), Color(0xFF6B5CE7)],
              ),
              borderRadius: BorderRadius.circular(16 * scaleFactor),
            ),
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16 * scaleFactor),
                ),
              ),
              child: Text(
                'Save to Library',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * scaleFactor,
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
class _CategoryEditorModal extends StatefulWidget {
  final String initialName;
  final List<String> initialWords;
  final Function(String, List<String>) onSave;
  final VoidCallback? onDelete;

  const _CategoryEditorModal({
    required this.initialName,
    required this.initialWords,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_CategoryEditorModal> createState() => _CategoryEditorModalState();
}

class _CategoryEditorModalState extends State<_CategoryEditorModal> {
  late TextEditingController _nameController;
  late List<TextEditingController> _wordControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _wordControllers = widget.initialWords
        .map((w) => TextEditingController(text: w))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _wordControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addWordField() {
    setState(() => _wordControllers.add(TextEditingController()));
  }

  void _removeWordField(int index) {
    setState(() {
      _wordControllers[index].dispose();
      _wordControllers.removeAt(index);
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final words = _wordControllers
        .map((c) => c.text.trim())
        .where((w) => w.isNotEmpty)
        .toList();

    widget.onSave(name, words);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialName.isEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24 * scaleFactor),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24 * scaleFactor,
        left: 24 * scaleFactor,
        right: 24 * scaleFactor,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24 * scaleFactor,
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
              Text(
                isNew ? 'New Category' : 'Edit Category',
                style: TextStyle(
                  fontSize: 20 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B5CE7),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, size: 24 * scaleFactor),
              ),
            ],
          ),
          SizedBox(height: 24 * scaleFactor),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12 * scaleFactor,
                        vertical: 16 * scaleFactor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scaleFactor),
                  Text(
                    "Words",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 14 * scaleFactor,
                    ),
                  ),
                  SizedBox(height: 8 * scaleFactor),
                  ...List.generate(_wordControllers.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _wordControllers.length - 1
                            ? 0
                            : 8 * scaleFactor,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _wordControllers[index],
                              decoration: InputDecoration(
                                hintText: 'Word ${index + 1}',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12 * scaleFactor,
                                  vertical: 12 * scaleFactor,
                                ),
                              ),
                            ),
                          ),
                          if (_wordControllers.length > 1)
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                                size: 24 * scaleFactor,
                              ),
                              onPressed: () => _removeWordField(index),
                            ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 8 * scaleFactor),
                  TextButton.icon(
                    onPressed: _addWordField,
                    icon: Icon(Icons.add, size: 24 * scaleFactor),
                    label: Text(
                      "Add Another Word",
                      style: TextStyle(fontSize: 14 * scaleFactor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16 * scaleFactor),
          Row(
            children: [
              if (!isNew && widget.onDelete != null)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16 * scaleFactor),
                    child: OutlinedButton(
                      onPressed: widget.onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 16 * scaleFactor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16 * scaleFactor),
                        ),
                      ),
                      child: Text(
                        "Delete",
                        style: TextStyle(fontSize: 14 * scaleFactor),
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B7CF6), Color(0xFF6B5CE7)],
                    ),
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16 * scaleFactor),
                      ),
                    ),
                    child: Text(
                      "Save Changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * scaleFactor,
                      ),
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
}
