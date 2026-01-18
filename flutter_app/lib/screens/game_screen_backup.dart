import 'package:flutter/material.dart';
import 'dart:math';

/// The main game screen where players view their roles.
class GameScreen extends StatefulWidget {
  final int playerCount;
  final List<String> words;
  final int timeLimitSeconds;

  const GameScreen({
    super.key,
    required this.playerCount,
    required this.words,
    required this.timeLimitSeconds,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late List<int> _playerRoles;
  late String _secretWord;
  int _imposterIndex = -1;

  int _currentPlayerIndex = 0;
  bool _isFront = true;
  bool _imposterRevealed = false;

  Duration? _timeLeft;
  bool _isTimerActive = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _initializeGame() {
    _playerRoles = List.filled(widget.playerCount, 0);
    _imposterIndex = Random().nextInt(widget.playerCount);
    _playerRoles[_imposterIndex] = 1;
    _secretWord = widget.words[Random().nextInt(widget.words.length)];
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);

    if (widget.timeLimitSeconds > 0) {
      _timeLeft = Duration(seconds: widget.timeLimitSeconds);
    }
  }

  void _startTimer() {
    if (widget.timeLimitSeconds <= 0 || _isTimerActive) return;

    setState(() => _isTimerActive = true);

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted ||
          !_isTimerActive ||
          _timeLeft == null ||
          _timeLeft! == Duration.zero) {
        return false;
      }

      setState(() {
        final seconds = _timeLeft!.inSeconds - 1;
        _timeLeft = Duration(seconds: seconds < 0 ? 0 : seconds);
      });

      return _timeLeft! > Duration.zero;
    });
  }

  void _nextPlayer() {
    if (!_isFront) {
      _controller.duration = const Duration(milliseconds: 300);
      _controller.reverse().then((_) {
        setState(() {
          _isFront = true;
          _currentPlayerIndex++;
          _controller.duration = const Duration(milliseconds: 600);
        });
      });
    } else {
      setState(() => _currentPlayerIndex++);
    }
  }

  void _revealImposter() {
    setState(() => _imposterRevealed = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPlayerIndex >= widget.playerCount) {
      _startTimer();
      return _DiscussionView(
        timeLimitSeconds: widget.timeLimitSeconds,
        timeLeft: _timeLeft,
        imposterRevealed: _imposterRevealed,
        imposterIndex: _imposterIndex,
        onReveal: _revealImposter,
        onEndGame: () => Navigator.pop(context),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'PLAYER ${_currentPlayerIndex + 1}/${widget.playerCount}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Semantics(
                      button: true,
                      label: _isFront
                          ? 'Player ${_currentPlayerIndex + 1} card. Tap to reveal your role.'
                          : 'Card revealed. View your role.',
                      child: GestureDetector(
                        onTap: _flipCard,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final angle = _animation.value * pi;
                            final transform = Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle);

                            return Transform(
                              transform: transform,
                              alignment: Alignment.center,
                              child: _animation.value < 0.5
                                  ? _CardFront(playerIndex: _currentPlayerIndex)
                                  : Transform(
                                      transform: Matrix4.identity()
                                        ..rotateY(pi),
                                      alignment: Alignment.center,
                                      child: _CardBack(
                                        isImposter:
                                            _playerRoles[_currentPlayerIndex] ==
                                            1,
                                        secretWord: _secretWord,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Semantics(
                      button: true,
                      enabled: !_isFront,
                      label: _currentPlayerIndex == widget.playerCount - 1
                          ? 'Start game after viewing role'
                          : 'Pass to next player',
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isFront ? null : _nextPlayer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSurface,
                            disabledBackgroundColor: colorScheme.secondary
                                .withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: Text(
                            _currentPlayerIndex == widget.playerCount - 1
                                ? 'Start Game'
                                : 'Next Player',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The front of the role card (tap to reveal).
class _CardFront extends StatelessWidget {
  final int playerIndex;

  const _CardFront({required this.playerIndex});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = min(screenWidth * 0.85, 350.0);
    final cardHeight = screenHeight < 600
        ? 360.0
        : (screenHeight < 800 ? 420.0 : 480.0);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Icon(
              Icons.help_outline,
              size: 40,
              color: colorScheme.onPrimary,
            ),
          ),
          Expanded(
            child: Align(
              alignment: const Alignment(0.0, -0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PLAYER ${playerIndex + 1}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Icon(Icons.touch_app, size: 60, color: colorScheme.tertiary),
                  const SizedBox(height: 20),
                  Text(
                    'TAP TO\nREVEAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The back of the role card showing role and secret word.
class _CardBack extends StatelessWidget {
  final bool isImposter;
  final String secretWord;

  const _CardBack({required this.isImposter, required this.secretWord});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = min(screenWidth * 0.85, 350.0);
    final cardHeight = screenHeight < 600
        ? 360.0
        : (screenHeight < 800 ? 420.0 : 480.0);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary, width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Icon(
              isImposter ? Icons.warning_amber_rounded : Icons.person_outline,
              size: 40,
              color: isImposter
                  ? Colors.red.withValues(alpha: 0.5)
                  : colorScheme.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Align(
              alignment: const Alignment(0.0, -0.1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'YOU ARE A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isImposter) ...[
                      const Text(
                        'IMPOSTER',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD32F2F),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Blend in.\nDon\'t get caught.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'CREWMATE',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'SECRET WORD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              secretWord,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The discussion phase view with timer and reveal button.
class _DiscussionView extends StatelessWidget {
  final int timeLimitSeconds;
  final Duration? timeLeft;
  final bool imposterRevealed;
  final int imposterIndex;
  final VoidCallback onReveal;
  final VoidCallback onEndGame;

  const _DiscussionView({
    required this.timeLimitSeconds,
    required this.timeLeft,
    required this.imposterRevealed,
    required this.imposterIndex,
    required this.onReveal,
    required this.onEndGame,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Discussion Time!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (timeLimitSeconds > 0 && timeLeft != null) ...[
                        _TimerDisplay(timeLeft: timeLeft!),
                        const SizedBox(height: 32),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          imposterRevealed
                              ? 'The Imposter was Player ${imposterIndex + 1}'
                              : 'Who is the imposter?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: imposterRevealed
                                ? Colors.red
                                : colorScheme.onSurface,
                            fontWeight: imposterRevealed
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (!imposterRevealed)
                        ElevatedButton.icon(
                          onPressed: onReveal,
                          icon: const Icon(Icons.visibility),
                          label: const Text('Reveal Imposter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.surface,
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: onEndGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('End Game'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays the countdown timer.
class _TimerDisplay extends StatelessWidget {
  final Duration timeLeft;

  const _TimerDisplay({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTimeUp = timeLeft == Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isTimeUp
            ? Colors.red.withValues(alpha: 0.1)
            : colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
        border: isTimeUp ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Text(
        isTimeUp
            ? "TIME'S UP!"
            : '${timeLeft.inMinutes}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
          color: isTimeUp ? Colors.red : colorScheme.onSurface,
        ),
      ),
    );
  }
}
