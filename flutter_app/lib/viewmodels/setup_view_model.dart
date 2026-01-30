import 'package:flutter/material.dart';
import '../data/models/game_settings.dart';
import '../data/repositories/word_repository.dart';
import '../services/usage_service.dart';

/// ViewModel for the [SetupScreen].
///
/// Follows the MVVM pattern to separate business logic from the UI.
class SetupViewModel extends ChangeNotifier {
  final WordRepository _wordRepository;

  GameSettings _settings;

  /// Current game settings.
  GameSettings get settings => _settings;

  /// Controllers for player names to allow UI updates.
  final List<TextEditingController> playerControllers = [];

  /// Focus nodes for player name input.
  final List<FocusNode> playerFocusNodes = [];

  /// Creates a [SetupViewModel] with an optional [WordRepository].
  SetupViewModel({WordRepository? wordRepository})
    : _wordRepository = wordRepository ?? WordRepository(),
      _settings = GameSettings.initial() {
    _initializeControllers();
  }

  /// Loads persisted categories and updates usage counts.
  Future<void> init() async {
    await _wordRepository.init();
    _normalizeSelectedCategories();
    _syncSavedCategoryCount();
    notifyListeners();
  }

  void _initializeControllers() {
    for (var i = 0; i < _settings.playerCount; i++) {
      // Initialize with empty text so hint is visible
      final controller = TextEditingController(text: '');
      playerControllers.add(controller);
      playerFocusNodes.add(FocusNode());
    }
  }

  /// Updates a player's name.
  void updatePlayerName(int index, String name) {
    if (index >= 0 && index < _settings.playerNames.length) {
      final newNames = List<String>.from(_settings.playerNames);
      newNames[index] = name.isEmpty ? 'Player ${index + 1}' : name;
      _settings = _settings.copyWith(playerNames: newNames);
      notifyListeners();
    }
  }

  /// Adds a new player to the game.
  void addPlayer() {
    if (_settings.playerCount < 12) {
      final newCount = _settings.playerCount + 1;
      final newNames = List<String>.from(_settings.playerNames)
        ..add('Player $newCount');

      _settings = _settings.copyWith(
        playerCount: newCount,
        playerNames: newNames,
      );

      final controller = TextEditingController(text: '');
      playerControllers.add(controller);
      playerFocusNodes.add(FocusNode());

      notifyListeners();
    }
  }

  /// Removes a player at the given [index].
  void removePlayer(int index) {
    if (_settings.playerCount > 3) {
      final newCount = _settings.playerCount - 1;
      final newNames = List<String>.from(_settings.playerNames)
        ..removeAt(index);

      _settings = _settings.copyWith(
        playerCount: newCount,
        playerNames: newNames,
      );

      playerControllers[index].dispose();
      playerControllers.removeAt(index);
      playerFocusNodes[index].dispose();
      playerFocusNodes.removeAt(index);

      notifyListeners();
    }
  }

  /// Updates the selected categories.
  void updateSelectedCategories(Set<String> newSelection) {
    if (newSelection.isNotEmpty) {
      _settings = _settings.copyWith(selectedCategories: newSelection);
      notifyListeners();
    }
  }

  /// Ensures the given category is selected.
  void selectCategory(String category) {
    if (_settings.selectedCategories.contains(category)) return;
    final newSelection = Set<String>.from(_settings.selectedCategories)
      ..add(category);
    _settings = _settings.copyWith(selectedCategories: newSelection);
    notifyListeners();
  }

  /// Toggles a category selection.
  void toggleCategory(String category) {
    final newCategories = Set<String>.from(_settings.selectedCategories);
    if (newCategories.contains(category)) {
      if (newCategories.length > 1) {
        newCategories.remove(category);
      }
    } else {
      newCategories.add(category);
    }

    _settings = _settings.copyWith(selectedCategories: newCategories);
    notifyListeners();
  }

  /// Updates the imposter count.
  void updateImposterCount(int count) {
    _settings = _settings.copyWith(imposterCount: count);
    notifyListeners();
  }

  /// Updates the time limit.
  void updateTimeLimit(int seconds) {
    _settings = _settings.copyWith(timeLimitSeconds: seconds);
    notifyListeners();
  }

  /// Toggles the decoy word setting.
  void toggleDecoyWord(bool value) {
    _settings = _settings.copyWith(useDecoyWord: value);
    notifyListeners();
  }

  /// Toggles the imposter hints setting.
  void toggleImposterHints(bool value) {
    _settings = _settings.copyWith(showImposterHints: value);
    notifyListeners();
  }

  /// Toggles the randomize imposters setting.
  void toggleRandomizeImposters(bool value) {
    _settings = _settings.copyWith(randomizeImposters: value);
    notifyListeners();
  }

  /// Returns the list of available categories from the repository.
  List<String> get availableCategories => _wordRepository.categories;

  /// Returns the list of words for currently selected categories.
  List<String> get activeWordList =>
      _wordRepository.getWordsForCategories(_settings.selectedCategories);

  /// Returns a map of word to category for all active categories.
  Map<String, String> get categoryMap {
    final Map<String, String> map = {};
    for (final category in _settings.selectedCategories) {
      final words = _wordRepository.getWordsForCategory(category);
      if (words != null) {
        for (final word in words) {
          map[word] = category;
        }
      }
    }
    return map;
  }

  /// Returns the current category lists.
  Map<String, List<String>> get categoryLists => _wordRepository.categoryLists;

  /// Returns the list of custom uploaded icon paths.
  List<String> get customIconPaths => _wordRepository.customIconPaths;

  /// Adds a new custom icon path to the global list.
  void addCustomIconPath(String path) {
    _wordRepository.addCustomIconPath(path);
    notifyListeners();
  }

  /// Adds a new category to the repository.
  void addCategory(String name, List<String> words, {String? icon}) {
    _wordRepository.addCategory(name, words, icon: icon);
    _syncSavedCategoryCount();
    notifyListeners();
  }

  /// Renames a category in the repository.
  void renameCategory(String oldName, String newName, List<String> words, {String? icon}) {
    _wordRepository.renameCategory(oldName, newName, words, icon: icon);
    _syncSavedCategoryCount();

    // If renamed category was selected, replace with new one
    if (_settings.selectedCategories.contains(oldName)) {
      final newSelected = Set<String>.from(_settings.selectedCategories)
        ..remove(oldName)
        ..add(newName);
      _settings = _settings.copyWith(selectedCategories: newSelected);
    }
    notifyListeners();
  }

  /// Returns the icon for a specific category.
  String? getCategoryIcon(String category) {
    return _wordRepository.getCategoryIcon(category);
  }

  /// Deletes a category from the repository.
  void deleteCategory(String category) {
    _wordRepository.deleteCategory(category);
    _syncSavedCategoryCount();
    // If deleted category was selected, remove it
    if (_settings.selectedCategories.contains(category)) {
      final newSelected = Set<String>.from(_settings.selectedCategories)
        ..remove(category);
      _settings = _settings.copyWith(selectedCategories: newSelected);
    }
    notifyListeners();
  }

  /// Returns the word count for a specific category.
  int getCategoryWordCount(String category) {
    return _wordRepository.getWordsForCategory(category)?.length ?? 0;
  }

  /// Updates the repository with new categories.
  void updateCategories(Map<String, List<String>> newCategories) {
    _wordRepository.updateCategories(newCategories);
    _syncSavedCategoryCount();
    notifyListeners();
  }

  void _syncSavedCategoryCount() {
    UsageService().updateSavedCategoryCount(_wordRepository.categories.length);
  }

  void _normalizeSelectedCategories() {
    final available = _wordRepository.categories.toSet();
    final selected = _settings.selectedCategories
        .where(available.contains)
        .toSet();

    if (selected.length != _settings.selectedCategories.length) {
      _settings = _settings.copyWith(selectedCategories: selected);
    }
  }

  @override
  void dispose() {
    for (final controller in playerControllers) {
      controller.dispose();
    }
    for (final node in playerFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
