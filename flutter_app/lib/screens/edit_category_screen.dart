import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/ui_utils.dart';
import '../theme/pastel_theme.dart';

class EditCategoryScreen extends StatefulWidget {
  final String? initialCategoryName;
  final List<String> initialWords;
  final Function(String name, List<String> words) onSave;

  const EditCategoryScreen({
    super.key,
    this.initialCategoryName,
    required this.initialWords,
    required this.onSave,
  });

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late TextEditingController _nameController;
  late TextEditingController _wordInputController;
  late List<String> _words;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCategoryName ?? '',
    );
    _wordInputController = TextEditingController();
    _words = List.from(widget.initialWords);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wordInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWord() {
    final text = _wordInputController.text.trim();
    if (text.isNotEmpty && !_words.contains(text)) {
      setState(() {
        _words.add(text);
        _wordInputController.clear();
      });
    }
  }

  void _removeWord(String word) {
    setState(() {
      _words.remove(word);
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && _words.isNotEmpty) {
      widget.onSave(name, _words);
      Navigator.of(context).pop();
    } else {
      // Show error?
      showIosSnackBar(context, 'Please enter a name and at least one word.');
    }
  }

  IconData _getCategoryIcon(String category) {
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
    final pastelTheme = Theme.of(context).extension<PastelTheme>()!;
    // Mapping HTML colors to Flutter
    final primaryColor = Theme.of(context).colorScheme.primary;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(context, isDark),

              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    160,
                  ), // Bottom padding for footer
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: pastelTheme.pastelBlue,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _getCategoryIcon(_nameController.text),
                                  size: 48,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Editable Title
                            TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.splineSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Category Name',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            Text(
                              '${_words.length} Words',
                              style: GoogleFonts.splineSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Word Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _words
                            .map(
                              (word) => _buildWordChip(
                                word,
                                pastelTheme,
                                primaryColor,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                      // Add Word Input
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _wordInputController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a new word...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                onSubmitted: (_) => _addWord(),
                              ),
                            ),
                            GestureDetector(
                              onTap: _addWord,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Footer
          if (MediaQuery.of(context).viewInsets.bottom == 0)
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    // Mimic iOS blur sticky header
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      color: Theme.of(
        context,
      ).scaffoldBackgroundColor.withValues(alpha: 0.8), // Placeholder for blur
      // Note: Real blur requires BackdropFilter + ClipRect, which is expensive, utilizing opacity for now as per previous patterns
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.centerLeft,
              color: Colors.transparent,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            'Edit Word List',
            style: GoogleFonts.splineSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface, // Was 0xFF111418
            ),
          ),
          const SizedBox(width: 40), // Balance center
        ],
      ),
    );
  }

  Widget _buildWordChip(String word, PastelTheme theme, Color primary) {
    final color = theme.pastelBlue;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 40,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              word,
              style: GoogleFonts.splineSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeWord(word),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, PastelTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
          ],
        ),
      ),
      child: SizedBox(
        height: 64,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.pastelMint, // soft-mint from html
            elevation: 4,
            shadowColor: theme.pastelMint.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer, // Was emeraldText
              ),
              const SizedBox(width: 8),
              Text(
                'Save Changes',
                style: GoogleFonts.splineSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
