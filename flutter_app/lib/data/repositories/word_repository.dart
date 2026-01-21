/// Repository for managing game categories and words.
class WordRepository {
  /// Hardcoded word lists by category.
  final Map<String, List<String>> _categoryLists = {
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

  /// Returns a list of all available categories.
  List<String> get categories => _categoryLists.keys.toList();

  /// Returns the words for a specific category.
  List<String>? getWordsForCategory(String category) =>
      _categoryLists[category];

  /// Returns all words for the selected categories.
  List<String> getWordsForCategories(Set<String> categories) {
    final List<String> allWords = [];
    for (final category in categories) {
      if (_categoryLists.containsKey(category)) {
        allWords.addAll(_categoryLists[category]!);
      }
    }
    return allWords;
  }

  /// Returns the current category lists.
  Map<String, List<String>> get categoryLists =>
      Map.unmodifiable(_categoryLists);

  /// Adds a new category with words.
  void addCategory(String name, List<String> words) {
    _categoryLists[name] = words;
  }

  /// Updates repository with new category lists.
  void updateCategories(Map<String, List<String>> newCategories) {
    _categoryLists.clear();
    _categoryLists.addAll(newCategories);
  }
}
