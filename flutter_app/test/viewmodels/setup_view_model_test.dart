import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_finder/data/repositories/word_repository.dart';
import 'package:imposter_finder/viewmodels/setup_view_model.dart';
import 'package:mocktail/mocktail.dart';

class MockWordRepository extends Mock implements WordRepository {}

void main() {
  group('SetupViewModel', () {
    late WordRepository wordRepository;
    late SetupViewModel viewModel;

    setUp(() {
      wordRepository = MockWordRepository();
      // Stub default category behavior
      when(
        () => wordRepository.getWordsForCategories(any()),
      ).thenReturn(['Lion', 'Tiger']);
      when(() => wordRepository.categories).thenReturn(['Animals', 'Fruits']);
      when(() => wordRepository.categoryLists).thenReturn({
        'Animals': ['Lion'],
        'Fruits': ['Apple'],
      });

      viewModel = SetupViewModel(wordRepository: wordRepository);
    });

    test('initial state is correct', () {
      check(viewModel.settings.playerCount).equals(4);
      check(viewModel.settings.imposterCount).equals(1);
      check(viewModel.settings.selectedCategories).contains('Animals');
      check(viewModel.playerControllers).length.equals(4);
    });

    group('Player Management', () {
      test('addPlayer increases count and adds controller', () {
        viewModel.addPlayer();
        check(viewModel.settings.playerCount).equals(5);
        check(viewModel.playerControllers).length.equals(5);
        check(viewModel.settings.playerNames.last).equals('Player 5');
      });

      test('addPlayer does not exceed 12', () {
        // Already has 4, add 8 more to reach 12
        for (var i = 0; i < 8; i++) {
          viewModel.addPlayer();
        }
        check(viewModel.settings.playerCount).equals(12);

        // Try adding one more
        viewModel.addPlayer();
        check(viewModel.settings.playerCount).equals(12);
      });

      test('removePlayer decreases count and removes controller', () {
        viewModel.removePlayer(0);
        check(viewModel.settings.playerCount).equals(3);
        check(viewModel.playerControllers).length.equals(3);
      });

      test('removePlayer does not go below 3', () {
        viewModel.removePlayer(0); // 3
        viewModel.removePlayer(0); // Should stay 3
        check(viewModel.settings.playerCount).equals(3);
      });

      test('updatePlayerName updates name in settings', () {
        viewModel.updatePlayerName(0, 'Max');
        check(viewModel.settings.playerNames[0]).equals('Max');
      });

      test('updatePlayerName reverts to default if empty', () {
        viewModel.updatePlayerName(0, '');
        check(viewModel.settings.playerNames[0]).equals('Player 1');
      });
    });

    group('Game Settings', () {
      test('updateImposterCount updates count', () {
        viewModel.updateImposterCount(2);
        check(viewModel.settings.imposterCount).equals(2);
      });

      test('toggleCategory adds and removes categories', () {
        // Initial is Animals
        viewModel.toggleCategory('Fruits');
        check(viewModel.settings.selectedCategories)
          ..contains('Animals')
          ..contains('Fruits');

        viewModel.toggleCategory('Animals');
        check(viewModel.settings.selectedCategories)
          ..not((it) => it.contains('Animals'))
          ..contains('Fruits');
      });

      test('toggleCategory prevents removing last category', () {
        // Initial is Animals
        viewModel.toggleCategory('Animals');
        check(viewModel.settings.selectedCategories).contains('Animals');
      });

      test('toggles update respective booleans', () {
        viewModel.toggleDecoyWord(true);
        check(viewModel.settings.useDecoyWord).isTrue();

        viewModel.toggleImposterHints(true);
        check(viewModel.settings.showImposterHints).isTrue();

        viewModel.toggleRandomizeImposters(true);
        check(viewModel.settings.randomizeImposters).isTrue();
      });

      test('updateTimeLimit updates seconds', () {
        viewModel.updateTimeLimit(60);
        check(viewModel.settings.timeLimitSeconds).equals(60);
      });
    });

    group('Repository Integration', () {
      test('activeWordList fetches from repository', () {
        final words = viewModel.activeWordList;
        check(words).contains('Lion');
        verify(() => wordRepository.getWordsForCategories(any())).called(1);
      });
    });
  });
}
