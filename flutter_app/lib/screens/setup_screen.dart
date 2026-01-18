import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_screen.dart';
import 'manage_categories_screen.dart';

/// Stitch-inspired setup screen with pastel colors and friendly layout.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _playerCount = 4;
  late List<String> _playerNames;
  late List<TextEditingController> _playerControllers;
  late List<FocusNode> _playerFocusNodes;
  late List<ScrollController> _playerScrollControllers;
  int _imposterCount = 1; // -1 for Random
  bool _useDecoyWord = false;
  bool _showImposterHints = false;
  bool _randomizeImposters = false;
  int _timeLimitSeconds = 120;
  final Set<String> _selectedCategories = {'Animals'};

  Map<String, List<String>> _categoryLists = {
    'Animals': [
      'Lion',
      'Tiger',
      'Elephant',
      'Giraffe',
      'Zebra',
      'Monkey',
      'Bear',
      'Hippo',
      'Kangaroo',
      'Penguin',
    ],
    'Fruits': [
      'Apple',
      'Banana',
      'Orange',
      'Grape',
      'Strawberry',
      'Blueberry',
      'Watermelon',
      'Pineapple',
      'Mango',
      'Peach',
    ],
    'Space': [
      'Planet',
      'Star',
      'Galaxy',
      'Comet',
      'Asteroid',
      'Nebula',
      'Black Hole',
      'Spaceship',
      'Astronaut',
      'Moon',
    ],
    'Emotions': [
      'Happy',
      'Sad',
      'Angry',
      'Surprised',
      'Scared',
      'Excited',
      'Anxious',
      'Proud',
      'Jealous',
      'Calm',
    ],
  };

  static const Map<String, IconData> _categoryIcons = {
    'Animals': Icons.pets,
    'Fruits': Icons.apple,
    'Space': Icons.rocket_launch,
    'Emotions': Icons.emoji_emotions,
  };

  @override
  void initState() {
    super.initState();
    _playerNames = List.generate(_playerCount, (i) => 'Player ${i + 1}');
    _playerControllers = List.generate(
      _playerCount,
      (i) => TextEditingController(text: ''),
    );
    _playerFocusNodes = List.generate(_playerCount, (i) => _createFocusNode());
    _playerScrollControllers = List.generate(
      _playerCount,
      (i) => ScrollController(),
    );
  }

  FocusNode _createFocusNode() {
    final node = FocusNode();
    node.addListener(() {
      if (!node.hasFocus) {
        // When focus is lost, scroll back to the start using ScrollController
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final index = _playerFocusNodes.indexOf(node);
          if (index != -1 && index < _playerScrollControllers.length) {
            if (_playerScrollControllers[index].hasClients) {
              _playerScrollControllers[index].jumpTo(0.0);
            }
          }
        });
      }
    });
    return node;
  }

  @override
  void dispose() {
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    for (final node in _playerFocusNodes) {
      node.dispose();
    }
    for (final controller in _playerScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _activeWordList {
    final List<String> allWords = [];
    for (final category in _selectedCategories) {
      if (_categoryLists.containsKey(category)) {
        allWords.addAll(_categoryLists[category]!);
      }
    }
    return allWords;
  }

  void _updatePlayerName(int index, String name) {
    _playerNames[index] = name.isEmpty ? 'Player ${index + 1}' : name;
  }

  void _addPlayer() {
    if (_playerCount < 12) {
      setState(() {
        _playerCount++;
        _playerNames.add('Player $_playerCount');
        _playerControllers.add(TextEditingController(text: ''));
        _playerFocusNodes.add(_createFocusNode());
        _playerScrollControllers.add(ScrollController());
      });
    }
  }

  void _removePlayer(int index) {
    if (_playerCount > 3) {
      setState(() {
        _playerCount--;
        _playerNames.removeAt(index);
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
        _playerFocusNodes[index].dispose();
        _playerFocusNodes.removeAt(index);
        _playerScrollControllers[index].dispose();
        _playerScrollControllers.removeAt(index);
      });
    }
  }

  void _toggleCategory(String name) {
    setState(() {
      if (_selectedCategories.contains(name)) {
        if (_selectedCategories.length > 1) {
          _selectedCategories.remove(name);
        }
      } else {
        _selectedCategories.add(name);
      }
    });
  }

  Future<void> _navigateToManageCategories() async {
    final updatedCategories = await Navigator.of(context)
        .push<Map<String, List<String>>>(
          MaterialPageRoute(
            builder: (context) =>
                ManageCategoriesScreen(initialCategories: _categoryLists),
          ),
        );

    if (updatedCategories != null) {
      setState(() {
        _categoryLists = updatedCategories;
        _selectedCategories.retainAll(_categoryLists.keys);
        if (_selectedCategories.isEmpty && _categoryLists.isNotEmpty) {
          _selectedCategories.add(_categoryLists.keys.first);
        }
      });
    }
  }

  void _startGame() {
    if (_activeWordList.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerCount: _playerCount,
          playerNames: _playerNames,
          imposterCountSetting: _randomizeImposters ? -1 : _imposterCount,
          useDecoyWord: _useDecoyWord,
          showImposterHints: _showImposterHints,
          words: _activeWordList,
          categoryMap: {
            for (var entry in _categoryLists.entries)
              for (var word in entry.value) word: entry.key,
          },
          timeLimitSeconds: _timeLimitSeconds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stitch-inspired colors
    const mint = Color(0xFFE0F2F1);
    const mintDark = Color(0xFF80CBC4);
    const softBlue = Color(0xFFE3F2FD);
    const blueAccent = Color(0xFF90CAF9);
    const paleYellow = Color(0xFFFFFDE7);
    const yellowAccent = Color(0xFFFFF59D);
    const softPink = Color(0xFFFCE4EC);
    const textMain = Color(0xFF455A64);
    const aiPurple = Color(0xFFF3E5F5);
    const aiAccent = Color(0xFFBA68C8);
    const iosBg = Color(0xFFF8FAFC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: iosBg,
        body: Stack(
          children: [
            // Main scrollable content
            CustomScrollView(
              slivers: [
                // Sticky Header
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  elevation: 0,
                  flexibleSpace: ClipRect(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    'Imposter Finder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                  centerTitle: true,
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 160),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Category Section
                      _buildSectionHeader(
                        context,
                        'Category',
                        trailing: _TappableButton(
                          onTap: _navigateToManageCategories,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: aiPurple,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: aiAccent.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: aiAccent.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: aiAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'AI Studio',
                                  style: TextStyle(
                                    color: aiAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 10,
                                  color: aiAccent.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryCard(
                        context,
                        softBlue: softBlue,
                        blueAccent: blueAccent,
                        textMain: textMain,
                      ),

                      const SizedBox(height: 32),

                      // Players Section
                      _buildSectionHeader(
                        context,
                        'Players',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: softBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'MIN 3 PLAYERS',
                            style: TextStyle(
                              color: blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPlayerList(
                        context,
                        softPink: softPink,
                        softBlue: softBlue,
                        mint: mint,
                        textMain: textMain,
                      ),

                      const SizedBox(height: 32),

                      // Number of Imposters
                      _buildSectionHeader(context, 'Imposters'),
                      const SizedBox(height: 16),
                      _buildImposterSlider(
                        context,
                        softPink: softPink,
                        textMain: textMain,
                      ),

                      const SizedBox(height: 32),

                      // Game Rules
                      _buildSectionHeader(context, 'Game Rules'),
                      const SizedBox(height: 12),
                      _buildGameRulesSection(
                        context,
                        mintDark: mintDark,
                        textMain: textMain,
                      ),

                      const SizedBox(height: 32),

                      // Discussion Time
                      _buildSectionHeader(context, 'Time Limit'),
                      const SizedBox(height: 16),
                      _buildDiscussionTimeSection(
                        context,
                        paleYellow: paleYellow,
                        yellowAccent: yellowAccent,
                        textMain: textMain,
                      ),
                    ]),
                  ),
                ),
              ],
            ),

            // Fixed bottom Start button - hides when keyboard is open
            Positioned(
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
                  opacity: MediaQuery.of(context).viewInsets.bottom > 0
                      ? 0.0
                      : 1.0,
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
                        onTap: _activeWordList.isNotEmpty ? _startGame : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: blueAccent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: blueAccent.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'START GAME',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF455A64),
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required Color softBlue,
    required Color blueAccent,
    required Color textMain,
  }) {
    final selectedCategory = _selectedCategories.first;
    final icon = _categoryIcons[selectedCategory] ?? Icons.category;

    return _TappableButton(
      onTap: () => _showCategoryModal(context),
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
              child: Icon(icon, size: 36, color: Colors.blue.shade500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT SELECTION',
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final text = _selectedCategories.length == 1
                          ? selectedCategory
                          : '${_selectedCategories.length} Categories';
                      final textStyle = TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      );

                      final textPainter = TextPainter(
                        text: TextSpan(text: text, style: textStyle),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      )..layout(maxWidth: double.infinity);

                      final hasOverflow =
                          textPainter.width > constraints.maxWidth;

                      Widget textWidget = Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: textStyle,
                      );

                      if (hasOverflow) {
                        return ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.black, Colors.transparent],
                              stops: [0.4, 0.8],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: textWidget,
                        );
                      }

                      return textWidget;
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Change category...',
                    style: TextStyle(
                      fontSize: 6,
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
              child: Icon(Icons.chevron_right, color: Colors.grey.shade300),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => _CategorySelectionSheet(
          categories: _categoryLists.keys.toList(),
          selectedCategories: _selectedCategories,
          onToggle: (category) {
            _toggleCategory(category);
            setSheetState(() {}); // Rebuild sheet
          },
          categoryIcons: _categoryIcons,
        ),
      ),
    );
  }

  Widget _buildPlayerList(
    BuildContext context, {
    required Color softPink,
    required Color softBlue,
    required Color mint,
    required Color textMain,
  }) {
    final colors = [softPink, softBlue, mint];

    return Column(
      children: [
        ...List.generate(_playerCount, (index) {
          final bgColor = colors[index % colors.length];

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
                Stack(
                  clipBehavior: Clip.none,
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
                        color: textMain.withValues(alpha: 0.6),
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _playerControllers[index],
                    focusNode: _playerFocusNodes[index],
                    scrollController: _playerScrollControllers[index],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Player ${index + 1}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                    onChanged: (value) => _updatePlayerName(index, value),
                  ),
                ),
                const SizedBox(width: 10),
                _TappableButton(
                  onTap: () => _removePlayer(index),
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

        // Add Player button
        if (_playerCount < 12)
          _TappableButton(
            onTap: _addPlayer,
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
                  Icon(Icons.add_circle, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'Add Player',
                    style: TextStyle(
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

  Widget _buildImposterSlider(
    BuildContext context, {
    required Color softPink,
    required Color textMain,
  }) {
    final maxImposters = _playerCount;

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
                  color: softPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _randomizeImposters ? '?' : '$_imposterCount',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade400,
                    ),
                  ),
                ),
              ),
              Text(
                _getImposterHint(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: const Color(0xFF90CAF9),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF90CAF9),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayColor: const Color(0xFF90CAF9).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _imposterCount.toDouble(),
              min: 0,
              max: maxImposters.toDouble(),
              divisions: maxImposters,
              onChanged: _randomizeImposters
                  ? null
                  : (value) {
                      setState(() => _imposterCount = value.round());
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                maxImposters + 1,
                (i) => Text(
                  '$i',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade300,
                  ),
                ),
              ).take(6).toList(), // Show max 6 labels
            ),
          ),
        ],
      ),
    );
  }

  String _getImposterHint() {
    if (_randomizeImposters) return 'Surprise everyone!';
    if (_imposterCount == 0) return 'No imposters mode!';
    if (_imposterCount == 1) return 'Classic mode';
    if (_imposterCount == 2) return 'Perfect for $_playerCount+ players!';
    return 'Chaotic fun!';
  }

  Widget _buildGameRulesSection(
    BuildContext context, {
    required Color mintDark,
    required Color textMain,
  }) {
    return Column(
      children: [
        _buildToggleCard(
          title: 'Randomize Imposters',
          description: 'Let fate decide the imposter count',
          isEnabled: _randomizeImposters,
          onToggle: (val) => setState(() => _randomizeImposters = val),
          activeColor: mintDark,
          textMain: textMain,
        ),
        const SizedBox(height: 12),
        _buildToggleCard(
          title: 'Odd One Out',
          description: "Everyone gets a word! Find the odd one(s) out!",
          isEnabled: _useDecoyWord,
          onToggle: (val) => setState(() => _useDecoyWord = val),
          activeColor: mintDark,
          textMain: textMain,
        ),
        const SizedBox(height: 12),
        _buildToggleCard(
          title: 'Imposter Hints',
          description: 'Show category hints to imposters',
          isEnabled: _showImposterHints,
          onToggle: (val) => setState(() => _showImposterHints = val),
          activeColor: mintDark,
          textMain: textMain,
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String description,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required Color activeColor,
    required Color textMain,
  }) {
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
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

  Widget _buildDiscussionTimeSection(
    BuildContext context, {
    required Color paleYellow,
    required Color yellowAccent,
    required Color textMain,
  }) {
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
              color: paleYellow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: Colors.yellow.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timeLimitSeconds == 0
                      ? 'No Limit'
                      : '${_timeLimitSeconds ~/ 60}:${(_timeLimitSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
                if (_timeLimitSeconds > 0)
                  Text(
                    'MINUTES',
                    style: TextStyle(
                      fontSize: 8,
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
              _buildTimeButton(
                icon: Icons.remove,
                onTap: () {
                  final times = [0, 60, 120, 180, 300];
                  final currentIndex = times.indexOf(_timeLimitSeconds);
                  if (currentIndex > 0) {
                    setState(() => _timeLimitSeconds = times[currentIndex - 1]);
                  }
                },
                yellowAccent: yellowAccent,
              ),
              const SizedBox(width: 8),
              _buildTimeButton(
                icon: Icons.add,
                onTap: () {
                  final times = [0, 60, 120, 180, 300];
                  final currentIndex = times.indexOf(_timeLimitSeconds);
                  if (currentIndex < times.length - 1) {
                    setState(() => _timeLimitSeconds = times[currentIndex + 1]);
                  }
                },
                yellowAccent: yellowAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color yellowAccent,
  }) {
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

/// Category selection bottom sheet
class _CategorySelectionSheet extends StatelessWidget {
  final List<String> categories;
  final Set<String> selectedCategories;
  final ValueChanged<String> onToggle;
  final Map<String, IconData> categoryIcons;

  const _CategorySelectionSheet({
    required this.categories,
    required this.selectedCategories,
    required this.onToggle,
    required this.categoryIcons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF455A64),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategories.contains(category);
                final icon = categoryIcons[category] ?? Icons.category;

                return GestureDetector(
                  onTap: () => onToggle(category),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE3F2FD)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF90CAF9)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: const Color(0xFF455A64)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF455A64),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF90CAF9),
                          )
                        else
                          const SizedBox(
                            width: 24,
                          ), // Consistent spacing even when not selected
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable widget with scale animation and haptic feedback
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
    // Delay reverse so animation is visible on quick taps
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
