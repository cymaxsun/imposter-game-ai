import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Screen for managing word categories and AI generation.
class ManageCategoriesScreen extends StatefulWidget {
  final Map<String, List<String>> initialCategories;

  const ManageCategoriesScreen({super.key, required this.initialCategories});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, List<String>> _categories;
  late TabController _tabController;

  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _generatedWords;

  final TextEditingController _topicController = TextEditingController();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _categories = Map.from(widget.initialCategories);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _tabController.dispose();
    super.dispose();
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
      if (!isRegeneration) _generatedWords = null;
    });

    try {
      final words = await ApiService.generateWordList(topic);
      if (mounted) {
        if (words.isNotEmpty) {
          setState(() => _generatedWords = {'topic': topic, 'words': words});
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

  void _saveAiCategory() {
    if (_generatedWords == null) return;

    final topic = _generatedWords!['topic'] as String;
    final words = _generatedWords!['words'] as List<String>;

    _addCategory(topic, words);

    setState(() {
      _generatedWords = null;
      _topicController.clear();
    });

    _tabController.animateTo(0);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Category "$topic" saved!')));
  }

  void _discardAiList() {
    setState(() {
      _generatedWords = null;
      _topicController.clear();
      _errorMessage = '';
    });
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

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
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
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: colorScheme.surfaceContainerLow,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 2,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.primary),
              onPressed: () => Navigator.of(context).pop(_categories),
            ),
            title: Text(
              'Manage Categories',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.primary.withValues(
                    alpha: 0.5,
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: "Library"),
                    Tab(text: "AI Studio"),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _LibraryTab(
                    categories: _categories,
                    isEditMode: _isEditMode,
                    onCategoryTap: (name) =>
                        _showCategoryEditor(categoryName: name),
                    onDeleteCategory: _deleteCategory,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _generatedWords != null
                      ? _GeneratedWordsView(
                          generatedWords: _generatedWords!,
                          onDiscard: _discardAiList,
                          onRetry: () => _generateAiList(isRegeneration: true),
                          onSave: _saveAiCategory,
                        )
                      : _AiGeneratorForm(
                          topicController: _topicController,
                          isLoading: _isLoading,
                          errorMessage: _errorMessage,
                          onGenerate: _generateAiList,
                        ),
                ),
              ),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, child) {
              final double animValue = _tabController.animation!.value;
              final double opacity = (1.0 - (animValue * 5)).clamp(0.0, 1.0);
              final double scale = (1.0 - (animValue * 2)).clamp(0.0, 1.0);

              if (opacity <= 0) return const SizedBox.shrink();

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'delete',
                        mini: true,
                        backgroundColor: _isEditMode
                            ? colorScheme.error
                            : colorScheme.surface,
                        foregroundColor: _isEditMode
                            ? colorScheme.onError
                            : colorScheme.error,
                        onPressed: _toggleEditMode,
                        child: Icon(
                          _isEditMode ? Icons.check : Icons.delete_outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'add',
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        onPressed: () => _showCategoryEditor(),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Displays the list of categories.
class _LibraryTab extends StatelessWidget {
  final Map<String, List<String>> categories;
  final bool isEditMode;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<String> onDeleteCategory;

  const _LibraryTab({
    required this.categories,
    required this.isEditMode,
    required this.onCategoryTap,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No categories yet.",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add one manually or use AI!",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final categoryKeys = categories.keys.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: categoryKeys.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey.withValues(alpha: 0.3),
          indent: 56,
        ),
        itemBuilder: (context, index) {
          final name = categoryKeys[index];
          final wordCount = categories[name]?.length ?? 0;
          final isFirst = index == 0;
          final isLast = index == categoryKeys.length - 1;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(12) : Radius.zero,
                bottom: isLast ? const Radius.circular(12) : Radius.zero,
              ),
              boxShadow: isFirst || isLast || categoryKeys.length == 1
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: _CategoryRow(
              name: name,
              wordCount: wordCount,
              isEditMode: isEditMode,
              onTap: () => onCategoryTap(name),
              onDelete: () => onDeleteCategory(name),
            ),
          );
        },
      ),
    );
  }
}

/// A single category row in the library list.
class _CategoryRow extends StatelessWidget {
  final String name;
  final int wordCount;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.name,
    required this.wordCount,
    required this.isEditMode,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const double iconAreaSize = 36.0;

    return InkWell(
      onTap: onTap,
      highlightColor: Colors.black.withValues(alpha: 0.05),
      splashColor: Colors.black.withValues(alpha: 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
            child: SizedBox(
              width: iconAreaSize,
              height: iconAreaSize,
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: isEditMode ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      width: iconAreaSize,
                      height: iconAreaSize,
                      child: Icon(
                        Icons.folder_open,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: ClipRect(
                      child: SizedBox(
                        height: iconAreaSize,
                        width: isEditMode ? iconAreaSize : 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                              size: 30,
                            ),
                            onPressed: () => _showDeleteDialog(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 17, color: colorScheme.onSurface),
            ),
          ),
          AnimatedOpacity(
            opacity: isEditMode ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$wordCount',
                style: TextStyle(fontSize: 17, color: Colors.grey[400]),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: isEditMode ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text(
          "Are you sure you want to delete '$name'? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

/// Form for entering a topic and generating words via AI.
class _AiGeneratorForm extends StatelessWidget {
  final TextEditingController topicController;
  final bool isLoading;
  final String errorMessage;
  final VoidCallback onGenerate;

  const _AiGeneratorForm({
    required this.topicController,
    required this.isLoading,
    required this.errorMessage,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.03),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 32,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "AI Generator",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter a topic and let AI create a category for you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: topicController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'e.g. "90s Movies", "Exotic Fruits"',
                    hintStyle: TextStyle(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            "Generate",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays AI-generated words with save/discard/retry options.
class _GeneratedWordsView extends StatelessWidget {
  final Map<String, dynamic> generatedWords;
  final VoidCallback onDiscard;
  final VoidCallback onRetry;
  final VoidCallback onSave;

  const _GeneratedWordsView({
    required this.generatedWords,
    required this.onDiscard,
    required this.onRetry,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topic = generatedWords['topic'] as String;
    final words = generatedWords['words'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Result: $topic',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
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
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
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
              const SizedBox(width: 16),
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
                    side: BorderSide(color: colorScheme.primary),
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: colorScheme.secondary.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Save to Library',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isNew = widget.initialName.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
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
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Words",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_wordControllers.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _wordControllers.length - 1 ? 0 : 8,
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          if (_wordControllers.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeWordField(index),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addWordField,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Another Word"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!isNew && widget.onDelete != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: OutlinedButton(
                      onPressed: widget.onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
