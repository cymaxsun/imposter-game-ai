import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing game categories and words.
class WordRepository {
  static const String _customCategoriesKey = 'custom_categories_v1';
  static const String _hiddenDefaultsKey = 'hidden_default_categories_v1';

  /// Hardcoded word lists by category.
  final Map<String, List<String>> _defaultCategoryLists = {
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

  final Map<String, List<String>> _customCategoryLists = {};
  final Set<String> _hiddenDefaultCategories = {};

  /// Loads persisted categories and hidden defaults from local storage.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getString(_customCategoriesKey);
    if (customJson != null) {
      try {
        final decoded = jsonDecode(customJson);
        if (decoded is Map<String, dynamic>) {
          _customCategoryLists
            ..clear()
            ..addAll(_decodeCategoryMap(decoded));
        }
      } catch (error, stackTrace) {
        developer.log(
          'Failed to decode custom categories.',
          name: 'word_repository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final hidden = prefs.getStringList(_hiddenDefaultsKey);
    if (hidden != null) {
      _hiddenDefaultCategories
        ..clear()
        ..addAll(hidden);
    }
  }

  /// Returns a list of all available categories.
  List<String> get categories => _buildCategoryLists().keys.toList();

  /// Returns the words for a specific category.
  List<String>? getWordsForCategory(String category) {
    final custom = _customCategoryLists[category];
    if (custom != null) {
      return List.unmodifiable(custom);
    }
    if (_hiddenDefaultCategories.contains(category)) {
      return null;
    }
    final defaults = _defaultCategoryLists[category];
    return defaults == null ? null : List.unmodifiable(defaults);
  }

  /// Returns all words for the selected categories.
  List<String> getWordsForCategories(Set<String> categories) {
    final List<String> allWords = [];
    for (final category in categories) {
      final words = getWordsForCategory(category);
      if (words != null) allWords.addAll(words);
    }
    return allWords;
  }

  /// Returns the current category lists.
  Map<String, List<String>> get categoryLists =>
      Map.unmodifiable(_buildCategoryLists());

  /// Returns the count of custom categories.
  int get customCategoryCount => _customCategoryLists.length;

  /// Adds a new category with words.
  void addCategory(String name, List<String> words) {
    _customCategoryLists[name] = List.from(words);
    _hiddenDefaultCategories.remove(name);
    _persistSafely();
  }

  /// Renames a category while preserving its position in the list.
  void renameCategory(String oldName, String newName, List<String> words) {
    if (_customCategoryLists.containsKey(oldName)) {
      // Rebuild map to preserve order
      final newMap = <String, List<String>>{};
      for (final key in _customCategoryLists.keys) {
        if (key == oldName) {
          newMap[newName] = List.from(words);
        } else {
          newMap[key] = _customCategoryLists[key]!;
        }
      }
      _customCategoryLists
        ..clear()
        ..addAll(newMap);
    } else {
      // If it's a default category or from elsewhere, just add/hide as needed
      if (_defaultCategoryLists.containsKey(oldName)) {
        _hiddenDefaultCategories.add(oldName);
      }
      _customCategoryLists[newName] = List.from(words);
    }
    _persistSafely();
  }

  /// Deletes a category.

  /// Deletes a category.
  void deleteCategory(String name) {
    if (_customCategoryLists.containsKey(name)) {
      _customCategoryLists.remove(name);
    } else if (_defaultCategoryLists.containsKey(name)) {
      _hiddenDefaultCategories.add(name);
    }
    _persistSafely();
  }

  /// Updates repository with new category lists.
  void updateCategories(Map<String, List<String>> newCategories) {
    _customCategoryLists
      ..clear()
      ..addAll(
        newCategories.map((key, value) => MapEntry(key, List.from(value))),
      );
    _hiddenDefaultCategories
      ..clear()
      ..addAll(
        _defaultCategoryLists.keys.where(
          (key) => !newCategories.containsKey(key),
        ),
      );
    _persistSafely();
  }

  Map<String, List<String>> _buildCategoryLists() {
    final merged = <String, List<String>>{};
    for (final entry in _defaultCategoryLists.entries) {
      if (_hiddenDefaultCategories.contains(entry.key)) {
        continue;
      }
      merged[entry.key] = List.unmodifiable(entry.value);
    }
    for (final entry in _customCategoryLists.entries) {
      merged[entry.key] = List.unmodifiable(entry.value);
    }
    return merged;
  }

  Map<String, List<String>> _decodeCategoryMap(Map<String, dynamic> decoded) {
    final map = <String, List<String>>{};
    for (final entry in decoded.entries) {
      final rawList = entry.value;
      if (rawList is List) {
        map[entry.key] = rawList.map((item) => item.toString()).toList();
      }
    }
    return map;
  }

  void _persistSafely() {
    unawaited(_persist());
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _customCategoriesKey,
        jsonEncode(_customCategoryLists),
      );
      await prefs.setStringList(
        _hiddenDefaultsKey,
        _hiddenDefaultCategories.toList(),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to persist categories.',
        name: 'word_repository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
