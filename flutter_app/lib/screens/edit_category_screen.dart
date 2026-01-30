import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/ui_utils.dart';
import '../theme/pastel_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/dashed_border_painter.dart';

class EditCategoryScreen extends StatefulWidget {
  final String? initialCategoryName;
  final List<String> initialWords;
  final String? initialIcon;
  final Function(String name, List<String> words, {IconData? icon, String? customIconPath}) onSave;
  final List<String> customIconPaths;
  final ValueChanged<String>? onCustomIconAdded;

  const EditCategoryScreen({
    super.key,
    this.initialCategoryName,
    required this.initialWords,
    this.initialIcon,
    required this.onSave,
    this.customIconPaths = const [],
    this.onCustomIconAdded,
  });

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late TextEditingController _nameController;
  late TextEditingController _wordInputController;
  late List<String> _words;
  late IconData _selectedIcon;
  String? _customIconPath;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  static const List<IconData> _availableIcons = [
    Icons.rocket_launch,
    Icons.bakery_dining,
    Icons.pets,
    Icons.masks,
    Icons.sports_basketball,
    Icons.flight_takeoff,
    Icons.movie,
    Icons.forest,
    Icons.science,
    Icons.coffee,
    Icons.music_note,
    Icons.directions_car,
    Icons.school,
    Icons.work,
    Icons.home,
    Icons.shopping_cart,
    Icons.star,
    Icons.favorite,
    Icons.emoji_events,
    Icons.lightbulb,
    Icons.gamepad,
    Icons.smartphone,
    Icons.camera_alt,
    Icons.beach_access,
    Icons.restaurant,
    Icons.local_pizza,
    Icons.cake,
    Icons.icecream,
    Icons.local_bar,
    Icons.celebration,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCategoryName ?? '',
    );
    _wordInputController = TextEditingController();
    _words = List.from(widget.initialWords);
    
    _selectedIcon = AppTheme.categoryIcons[widget.initialCategoryName] ?? Icons.category;
    
    if (widget.initialIcon != null) {
      if (widget.initialIcon!.startsWith('path:')) {
        _customIconPath = widget.initialIcon!.substring(5);
      } else if (widget.initialIcon!.startsWith('codePoint:')) {
        try {
          final codePoint = int.parse(widget.initialIcon!.split(':')[1]);
          _selectedIcon = IconData(codePoint, fontFamily: 'MaterialIcons');
        } catch (_) {}
      }
    }
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
      // If we have a custom icon path selected (either new upload or from history)
      if (_customIconPath != null) {
        widget.onCustomIconAdded?.call(_customIconPath!);
      }
      
      widget.onSave(
        name,
        _words,
        icon: _selectedIcon,
        customIconPath: _customIconPath,
      );
      Navigator.of(context).pop();
    } else {
      showIosSnackBar(context, 'Please enter a name and at least one word.');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _customIconPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        showIosSnackBar(context, 'Failed to pick image: $e', isError: true);
      }
    }
  }

  void _showIconPicker() {
    final pastelTheme = Theme.of(context).extension<PastelTheme>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalItems = _availableIcons.length + 1 + widget.customIconPaths.length;
          
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Select Icon',
                        style: GoogleFonts.splineSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildUploadOption(pastelTheme, onUpload: () async {
                              await _pickImage();
                              setModalState(() {});
                            });
                          }
                          
                          // Custom icons come after upload button
                          if (index <= widget.customIconPaths.length) {
                            final customPath = widget.customIconPaths[index - 1];
                            return _buildCustomIconOption(customPath, pastelTheme, onTap: () {
                              setState(() {
                                _customIconPath = customPath;
                              });
                              setModalState(() {});
                            });
                          }
                          
                          // Standard icons
                          final iconIndex = index - 1 - widget.customIconPaths.length;
                          final icon = _availableIcons[iconIndex];
                          return _buildIconOption(icon, pastelTheme, onTap: () {
                            setState(() {
                              _selectedIcon = icon;
                              _customIconPath = null;
                            });
                            setModalState(() {});
                          });
                        },
                      ),
                    ),
                    // Confirm Button
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Confirm Selection',
                          style: GoogleFonts.splineSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUploadOption(PastelTheme theme, {VoidCallback? onUpload}) {
    final unselectedColor = Colors.grey.shade600;

    return GestureDetector(
      onTap: onUpload,
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: unselectedColor.withValues(alpha: 0.5),
          strokeWidth: 1,
          gap: 4,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: unselectedColor),
              const SizedBox(height: 4),
              Text(
                'Upload',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconOption(IconData icon, PastelTheme theme, {VoidCallback? onTap}) {
    final isSelected = _customIconPath == null && _selectedIcon == icon;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: primaryColor, width: 2)
              : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.grey.shade600,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCustomIconOption(String path, PastelTheme theme, {VoidCallback? onTap}) {
    final isSelected = _customIconPath == path;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: primaryColor, width: 2)
              : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
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
                            GestureDetector(
                              onTap: _showIconPicker,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: pastelTheme.pastelBlue,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _customIconPath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(24),
                                              child: Image.file(
                                                File(_customIconPath!),
                                                width: 96,
                                                height: 96,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              _selectedIcon,
                                              size: 48,
                                              color: primaryColor,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
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
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
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
