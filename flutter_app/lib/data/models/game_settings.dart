/// Model representing the configuration for a game session.
class GameSettings {
  /// The number of players in the game (3-12).
  final int playerCount;

  /// List of player names.
  final List<String> playerNames;

  /// Number of imposters (1 to playerCount-1, or -1 for random).
  final int imposterCount;

  /// Whether to use a decoy word.
  final bool useDecoyWord;

  /// Whether to show imposter hints.
  final bool showImposterHints;

  /// Whether to randomize the imposter count.
  final bool randomizeImposters;

  /// The time limit for discussion in seconds.
  final int timeLimitSeconds;

  /// The categories selected for this session.
  final Set<String> selectedCategories;

  /// Creates a new [GameSettings] instance.
  const GameSettings({
    required this.playerCount,
    required this.playerNames,
    required this.imposterCount,
    required this.useDecoyWord,
    required this.showImposterHints,
    required this.randomizeImposters,
    required this.timeLimitSeconds,
    required this.selectedCategories,
  });

  /// Creates a default [GameSettings] instance.
  factory GameSettings.initial() {
    return GameSettings(
      playerCount: 4,
      playerNames: List.generate(4, (i) => 'Player ${i + 1}'),
      imposterCount: 1,
      useDecoyWord: false,
      showImposterHints: false,
      randomizeImposters: false,
      timeLimitSeconds: 120,
      selectedCategories: {},
    );
  }

  /// Creates a copy of this [GameSettings] with updated fields.
  GameSettings copyWith({
    int? playerCount,
    List<String>? playerNames,
    int? imposterCount,
    bool? useDecoyWord,
    bool? showImposterHints,
    bool? randomizeImposters,
    int? timeLimitSeconds,
    Set<String>? selectedCategories,
  }) {
    return GameSettings(
      playerCount: playerCount ?? this.playerCount,
      playerNames: playerNames ?? this.playerNames,
      imposterCount: imposterCount ?? this.imposterCount,
      useDecoyWord: useDecoyWord ?? this.useDecoyWord,
      showImposterHints: showImposterHints ?? this.showImposterHints,
      randomizeImposters: randomizeImposters ?? this.randomizeImposters,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }
}
