import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import '../theme/app_theme.dart';

/// Layout and sizing constants for the game screen.
class GameScreenConstants {
  // Flex ratios
  static const int headerFlex = 1;
  static const int cardFlex = 5;
  static const int buttonFlex = 1;

  // Card sizing
  static const double cardWidthFactor = 0.9;
  static const double cardContentWidthFactor = 0.65;
  static const double cardContentHeightFactor = 0.65;
  static const double cardBackContentFactor = 0.7;

  // Border radii
  static const double cardBorderRadius = 24.0;
  static const double cardBackBorderRadius = 32.0;
  static const double buttonBorderRadius = 50.0;
  static const double badgeBorderRadius = 25.0;
  static const double wordBoxBorderRadius = 24.0;

  // Padding
  static const double cardPadding = 24.0;
  static const double buttonPaddingHorizontal = 24.0;
  static const double buttonPaddingVertical = 16.0;

  // Border widths
  static const double cardBorderWidth = 4.0;
  static const double cardBackBorderWidth = 3.0;

  // Animation
  static const Duration flipAnimationDuration = Duration(milliseconds: 400);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 2500);
  static const double pulseScaleAmount = 0.04;
  static const double maxGlowOpacity = 0.4;

  // Shadows
  static const double cardBlurRadius = 30.0;
  static const double cardSpreadRadius = 5.0;
  static const double buttonBlurRadius = 12.0;
  static const double cardBackBlurRadius = 64.0;

  // Icon sizes
  static const double questionMarkIconSize = 80.0;
  static const double emojiIconSize = 40.0;
  static const double buttonIconSize = 24.0;
  static const double touchIconSize = 20.0;
  static const double backgroundIconSize = 200.0;

  // Flex ratios for card content
  static const int iconFlex = 6;
  static const int secretTextFlex = 2;
  static const int instructionFlex = 1;
  static const int playerNameFlex = 2;
  static const int tapToRevealFlex = 1;

  // Card back flex ratios
  static const int backIconFlex = 4;
  static const int roleTitleFlex = 2;
  static const int subtitleFlex = 1;
  static const int wordBoxFlex = 3;
  static const double scrollBottomPadding = 80.0;
}

/// The main game screen where players view their roles.
class GameScreen extends StatefulWidget {
  final int playerCount;
  final List<String> playerNames;
  final List<String> playerAvatars;
  final List<String> words;
  final Map<String, String> categoryMap;
  final int timeLimitSeconds;
  final int imposterCountSetting;
  final bool useDecoyWord;
  final bool showImposterHints;

  const GameScreen({
    super.key,
    required this.playerCount,
    required this.playerNames,
    required this.playerAvatars,
    required this.imposterCountSetting,
    required this.useDecoyWord,
    required this.showImposterHints,
    required this.words,
    required this.categoryMap,
    required this.timeLimitSeconds,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late List<int> _playerRoles;
  late String _secretWord;
  late String _decoyWord;
  final List<int> _imposterIndices = [];
  late bool _useDecoyWord;

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
    _useDecoyWord = widget.useDecoyWord;

    // Determine number of imposters
    int numImposters = widget.imposterCountSetting;
    if (numImposters == -1) {
      numImposters = Random().nextInt(widget.playerCount + 1);
    }
    numImposters = numImposters.clamp(0, widget.playerCount);

    // Assignment logic preserved
    final random = Random();
    while (_imposterIndices.length < numImposters) {
      int index = random.nextInt(widget.playerCount);
      if (!_imposterIndices.contains(index)) {
        _imposterIndices.add(index);
        _playerRoles[index] = 1;
      }
    }

    _secretWord = widget.words[random.nextInt(widget.words.length)];

    if (_useDecoyWord) {
      List<String> remainingWords = List.from(widget.words)
        ..remove(_secretWord);
      if (remainingWords.isNotEmpty) {
        _decoyWord = remainingWords[random.nextInt(remainingWords.length)];
      } else {
        _decoyWord = _secretWord;
        _useDecoyWord = false;
      }
    } else {
      _decoyWord = '';
    }
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);

    if (widget.timeLimitSeconds > 0 && _timeLeft == null) {
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
        if (mounted) {
          setState(() {
            _isFront = true;
            _currentPlayerIndex++;
            _controller.duration = const Duration(milliseconds: 600);
          });
        }
      });
    } else {
      setState(() => _currentPlayerIndex++);
    }
  }

  void _revealImposter() {
    setState(() {
      _imposterRevealed = true;
      _isTimerActive = false;
    });
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
        imposterIndices: _imposterIndices,
        imposterNames: _imposterIndices
            .map((i) => widget.playerNames[i])
            .toList(),
        allPlayerNames: widget.playerNames,
        playerAvatars: widget.playerAvatars,
        secretWord: _secretWord,
        category: widget.categoryMap[_secretWord],
        decoyWord: _useDecoyWord ? _decoyWord : null,
        onReveal: _revealImposter,
        onEndGame: () => Navigator.pop(context),
      );
    }

    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderSection(gameColors: gameColors),
            const SizedBox(height: 16),
            Expanded(
              flex: GameScreenConstants.cardFlex,
              child: _RoleCard(
                animation: _animation,
                isFront: _isFront,
                playerName: widget.playerNames[_currentPlayerIndex],
                playerAvatar: widget.playerAvatars[_currentPlayerIndex],
                isImposter: _playerRoles[_currentPlayerIndex] == 1,
                secretWord: _secretWord,
                decoyWord: _useDecoyWord ? _decoyWord : null,
                hint: widget.showImposterHints
                    ? widget.categoryMap[_secretWord]
                    : null,
                onFlip: _flipCard,
              ),
            ),
            const SizedBox(height: 16),
            _ActionButton(
              isFront: _isFront,
              isLastPlayer: _currentPlayerIndex == widget.playerCount - 1,
              gameColors: gameColors,
              onPressed: _nextPlayer,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final GameScreenColors gameColors;

  const _HeaderSection({required this.gameColors});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      flex: GameScreenConstants.headerFlex,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Next Role',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: gameColors.headerText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to discover who you are?',
            style: textTheme.bodyMedium?.copyWith(
              color: gameColors.headerSubtext,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Animation<double> animation;
  final bool isFront;
  final String playerName;
  final String playerAvatar;
  final bool isImposter;
  final String secretWord;
  final String? decoyWord;
  final String? hint;
  final VoidCallback onFlip;

  const _RoleCard({
    required this.animation,
    required this.isFront,
    required this.playerName,
    required this.playerAvatar,
    required this.isImposter,
    required this.secretWord,
    this.decoyWord,
    this.hint,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isFront
          ? '$playerName card. Tap to reveal your role.'
          : 'Card revealed. View your role.',
      child: GestureDetector(
        onTap: onFlip,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final angle = animation.value * pi;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: animation.value < 0.5
                  ? _CardFront(playerName: playerName)
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _CardBack(
                        playerAvatar: playerAvatar,
                        isImposter: isImposter,
                        secretWord: secretWord,
                        decoyWord: decoyWord,
                        hint: hint,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isFront;
  final bool isLastPlayer;
  final GameScreenColors gameColors;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.isFront,
    required this.isLastPlayer,
    required this.gameColors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      flex: GameScreenConstants.buttonFlex,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GameScreenConstants.buttonPaddingHorizontal,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isFront ? 0.4 : 1.0,
            child: FilledButton(
              onPressed: isFront ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Color(0xFF307DE8),
                disabledBackgroundColor: Color(0xFF307DE8),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    GameScreenConstants.buttonBorderRadius,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLastPlayer
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                    size: GameScreenConstants.buttonIconSize,
                    color: gameColors.buttonText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLastPlayer ? 'START GAME' : 'NEXT PLAYER',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: gameColors.buttonText,
                      letterSpacing: 1,
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

class _CardFront extends StatefulWidget {
  final String playerName;

  const _CardFront({required this.playerName});

  @override
  State<_CardFront> createState() => _CardFrontState();
}

class _CardFrontState extends State<_CardFront>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: GameScreenConstants.pulseAnimationDuration,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;

    final primaryNavy = Color(0xFF307DE8);
    final cardBg = gameColors.cardFrontBackground;
    final textDark = gameColors.cardFrontTextDark;
    final textMuted = gameColors.cardFrontTextMuted;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseScale =
            1.0 +
            (_pulseAnimation.value < 0.5
                ? _pulseAnimation.value * GameScreenConstants.pulseScaleAmount
                : (1 - _pulseAnimation.value) *
                      GameScreenConstants.pulseScaleAmount);
        final glowOpacity =
            (_pulseAnimation.value < 0.5
                ? _pulseAnimation.value
                : (1 - _pulseAnimation.value)) *
            GameScreenConstants.maxGlowOpacity;

        return Transform.scale(
          scale: pulseScale,
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryNavy.withValues(alpha: 0.3),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryNavy.withValues(alpha: glowOpacity),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            primaryNavy.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.65,
                    heightFactor: 0.65,
                    child: _SecretCardContent(
                      playerName: widget.playerName,
                      primaryNavy: primaryNavy,
                      textDark: textDark,
                      textMuted: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SecretCardContent extends StatelessWidget {
  final String playerName;
  final Color primaryNavy;
  final Color textDark;
  final Color textMuted;

  const _SecretCardContent({
    required this.playerName,
    required this.primaryNavy,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: FittedBox(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryNavy.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.question_mark_rounded,
                size: GameScreenConstants.questionMarkIconSize,
                color: primaryNavy,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: FittedBox(
            child: Text(
              'SECRET',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 0,
          child: FittedBox(
            child: Text(
              'Pass the phone to',
              style: textTheme.labelSmall?.copyWith(
                color: textMuted,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: primaryNavy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.6,
              heightFactor: 0.6,
              child: FittedBox(
                child: Text(
                  playerName.toUpperCase(),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 1,
          child: FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  size: GameScreenConstants.touchIconSize,
                  color: textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'TAP TO REVEAL',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  final String playerAvatar;
  final bool isImposter;
  final String secretWord;
  final String? decoyWord;
  final String? hint;

  const _CardBack({
    required this.playerAvatar,
    required this.isImposter,
    required this.secretWord,
    this.decoyWord,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gameColors =
        Theme.of(context).extension<GameScreenColors>() ??
        GameScreenColors.light;

    final showingAsImposter = isImposter && decoyWord == null;

    final bgColor = showingAsImposter
        ? gameColors.imposterBackground
        : gameColors.innocentBackground;
    final accentColor = showingAsImposter
        ? gameColors.imposterAccent
        : gameColors.innocentAccent;
    final textColor = showingAsImposter
        ? gameColors.imposterText
        : gameColors.innocentText;
    final mutedColor = showingAsImposter
        ? gameColors.imposterMuted
        : gameColors.innocentMuted;

    return FractionallySizedBox(
      widthFactor: GameScreenConstants.cardWidthFactor,
      child: Container(
        padding: const EdgeInsets.all(GameScreenConstants.cardPadding),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(
            GameScreenConstants.cardBackBorderRadius,
          ),
          border: Border.all(
            color: Colors.white,
            width: GameScreenConstants.cardBackBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: GameScreenConstants.cardBackBlurRadius,
              offset: const Offset(0, 32),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FractionallySizedBox(
              heightFactor: 0.8,
              widthFactor: 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 6,
                    child: FittedBox(
                      child: Transform.scale(
                        scale: 1.5, // Zoom in to crop baked-in padding
                        child: Image.asset(playerAvatar, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      child: Text(
                        showingAsImposter ? 'IMPOSTER' : 'INNOCENT',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!showingAsImposter || hint != null)
                    Expanded(
                      flex: 4,
                      child: Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            GameScreenConstants.wordBoxBorderRadius,
                          ),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 0.7,
                          heightFactor: 0.8,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: showingAsImposter
                                    ? _InfoRow(
                                        label: 'CATEGORY',
                                        value: (hint ?? 'UNKNOWN')
                                            .toUpperCase(),
                                        isCategory: true,
                                        isVertical: true,
                                        labelStyle: textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: mutedColor.withValues(
                                                alpha: 0.6,
                                              ),
                                              letterSpacing: 4,
                                            ),
                                        valueStyle: textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: textColor,
                                              letterSpacing: -1,
                                            ),
                                      )
                                    : _InfoRow(
                                        label: 'SECRET WORD',
                                        value:
                                            (isImposter && decoyWord != null
                                                    ? decoyWord!
                                                    : secretWord)
                                                .toUpperCase(),
                                        isVertical: true,
                                        labelStyle: textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: mutedColor.withValues(
                                                alpha: 0.6,
                                              ),
                                              letterSpacing: 4,
                                            ),
                                        valueStyle: textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: textColor,
                                              letterSpacing: -1,
                                            ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  //else
                  //const Spacer(flex: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscussionView extends StatefulWidget {
  final int timeLimitSeconds;
  final Duration? timeLeft;
  final bool imposterRevealed;
  final List<int> imposterIndices;
  final List<String> imposterNames;
  final List<String> allPlayerNames;
  final List<String> playerAvatars;
  final String secretWord;
  final String? category;
  final String? decoyWord;
  final VoidCallback onReveal;
  final VoidCallback onEndGame;

  const _DiscussionView({
    required this.timeLimitSeconds,
    required this.timeLeft,
    required this.imposterRevealed,
    required this.imposterIndices,
    required this.imposterNames,
    required this.allPlayerNames,
    required this.playerAvatars,
    required this.secretWord,
    this.category,
    this.decoyWord,
    required this.onReveal,
    required this.onEndGame,
  });

  @override
  State<_DiscussionView> createState() => _DiscussionViewState();
}

class _DiscussionViewState extends State<_DiscussionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late String _startingPlayer;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );

    _startingPlayer =
        widget.allPlayerNames[Random().nextInt(widget.allPlayerNames.length)];

    if (widget.imposterRevealed) {
      _revealController.forward();
    }
  }

  @override
  void didUpdateWidget(_DiscussionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imposterRevealed && !oldWidget.imposterRevealed) {
      _revealController.forward(from: 0.0);
    } else if (!widget.imposterRevealed && oldWidget.imposterRevealed) {
      _revealController.reset();
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const timerAccent = Color(0xFFD4A017);
    final progress = widget.timeLimitSeconds > 0 && widget.timeLeft != null
        ? widget.timeLeft!.inSeconds / widget.timeLimitSeconds
        : 1.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!widget.imposterRevealed) ...[
                  Spacer(flex: 1),
                  _TimerSection(
                    text: widget.timeLeft != null
                        ? _formatTime(widget.timeLeft!)
                        : '--:--',
                    progress: progress,
                    timerAccent: timerAccent,
                  ),
                ],
                Expanded(
                  flex: widget.imposterRevealed ? 6 : 5,
                  child: widget.imposterRevealed
                      ? _ImposterRevealView(
                          animation: _revealController,
                          imposterNames: widget.imposterNames,
                          imposterIndices: widget.imposterIndices,
                          playerAvatars: widget.playerAvatars,
                          secretWord: widget.secretWord,
                          category: widget.category,
                          onEndGame: widget.onEndGame,
                        )
                      : _WhoIsTheImposterSection(
                          startingPlayer: _startingPlayer,
                        ),
                ),
                if (!widget.imposterRevealed) ...[
                  _RevealButton(onReveal: widget.onReveal),
                ] else ...[
                  _PlayAgainButton(onEndGame: widget.onEndGame),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _TimerSection extends StatelessWidget {
  final String text;
  final double progress;
  final Color timerAccent;

  const _TimerSection({
    required this.text,
    required this.progress,
    required this.timerAccent,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Expanded(
      flex: 1,
      child: FittedBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'DISCUSSION REMAINING',
              style: textTheme.labelSmall?.copyWith(
                color: onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: timerAccent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 6,
              width: 200,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [timerAccent, timerAccent.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImposterRevealView extends StatelessWidget {
  final Animation<double> animation;
  final List<String> imposterNames;
  final List<int> imposterIndices;
  final List<String> playerAvatars;
  final String secretWord;
  final String? category;
  final VoidCallback onEndGame;

  const _ImposterRevealView({
    required this.animation,
    required this.imposterNames,
    required this.imposterIndices,
    required this.playerAvatars,
    required this.secretWord,
    this.category,
    required this.onEndGame,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: imposterNames.length == 1
                    ? _SingleImposterLayout(
                        name: imposterNames.first,
                        avatar: playerAvatars[imposterIndices.first],
                        secretWord: secretWord,
                        category: category,
                        animation: animation,
                      )
                    : _MultiImposterLayout(
                        imposterNames: imposterNames,
                        imposterIndices: imposterIndices,
                        playerAvatars: playerAvatars,
                        secretWord: secretWord,
                        category: category,
                        animation: animation,
                      ),
              );
            },
          ),
        ),
        
      ],
    );
  }
}

class _SingleImposterLayout extends StatelessWidget {
  final String name;
  final String avatar;
  final String secretWord;
  final String? category;
  final Animation<double> animation;

  const _SingleImposterLayout({
    required this.name,
    required this.avatar,
    required this.secretWord,
    this.category,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 2,
          child: _RevealTitle(
            namesCount: 1,
            animation: animation,
            isExpanded: false,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 5,
          child: _SingleImposterCard(
            name: name,
            avatar: avatar,
            animation: animation,
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          flex: 2,
          child: _RevealSecretInfo(
            secretWord: secretWord,
            category: category,
            animation: animation,
            isExpanded: false,
          ),
        ),
      ],
    );
  }
}

class _MultiImposterLayout extends StatelessWidget {
  final List<String> imposterNames;
  final List<int> imposterIndices;
  final List<String> playerAvatars;
  final String secretWord;
  final String? category;
  final Animation<double> animation;

  const _MultiImposterLayout({
    required this.imposterNames,
    required this.imposterIndices,
    required this.playerAvatars,
    required this.secretWord,
    this.category,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              flex: 2,
              child: _RevealTitle(
                namesCount: imposterNames.length,
                animation: animation,
                isExpanded: false,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Colors.transparent],
                        stops: [0.8, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth - 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: imposterNames.asMap().entries.map((entry) {
                            final index = entry.key;
                            final delay = 0.2 + (index * 0.1);
                            final itemAnimation = CurvedAnimation(
                              parent: animation,
                              curve: Interval(
                                delay.clamp(0.0, 0.9),
                                (delay + 0.4).clamp(0.1, 1.0),
                                curve: Curves.easeOutBack,
                              ),
                            );

                            return AnimatedBuilder(
                              animation: itemAnimation,
                              builder: (context, child) {
                                final t = itemAnimation.value.clamp(0.0, 1.0);
                                return Opacity(
                                  opacity: t,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - t)),
                                    child: _ImposterNameCard(
                                      index: index,
                                      name: entry.value,
                                      avatar:
                                          playerAvatars[imposterIndices[index]],
                                      animation: animation,
                                      total: imposterNames.length,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              flex: 2,
              child: _RevealSecretInfo(
                secretWord: secretWord,
                category: category,
                animation: animation,
                isExpanded: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RevealTitle extends StatelessWidget {
  final int namesCount;
  final Animation<double> animation;
  final bool isExpanded;

  const _RevealTitle({
    required this.namesCount,
    required this.animation,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final opacityValue = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ).value;

    final slideValue = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ).value;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Opacity(
        opacity: opacityValue,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - slideValue)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                namesCount == 1 ? 'THE IMPOSTER' : 'THE IMPOSTERS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.6),
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  namesCount == 1 ? 'WAS REVEALED' : 'WERE REVEALED',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isExpanded) {
      return Expanded(flex: 3, child: content);
    }
    return content;
  }
}

class _SingleImposterCard extends StatelessWidget {
  final String name;
  final String avatar;
  final Animation<double> animation;

  const _SingleImposterCard({
    required this.name,
    required this.avatar,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final opacityValue = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ).value;

    final scaleValue = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ).value;

    return Opacity(
      opacity: opacityValue,
      child: Transform.scale(
        scale: scaleValue,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: 1.3,
                    child: Image.asset(avatar, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    name.toUpperCase(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImposterNameCard extends StatelessWidget {
  final int index;
  final String name;
  final String avatar;
  final Animation<double> animation;
  final int total;

  const _ImposterNameCard({
    required this.index,
    required this.name,
    required this.avatar,
    required this.animation,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: index < total - 1 ? 12 : 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Transform.scale(
              scale: 1.1,
              child: Image.asset(avatar, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AutoSizeText(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              minFontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealSecretInfo extends StatelessWidget {
  final String secretWord;
  final String? category;
  final Animation<double> animation;
  final bool isExpanded;

  const _RevealSecretInfo({
    required this.secretWord,
    this.category,
    required this.animation,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final opacityValue = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ).value;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Opacity(
        opacity: opacityValue,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: _InfoRow(
                  label: 'SECRET WORD',
                  value: secretWord,
                  valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (category != null) ...[
                const SizedBox(height: 16),
                Flexible(
                  child: _InfoRow(
                    label: 'CATEGORY',
                    value: category!,
                    isCategory: true,
                    valueStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isExpanded) {
      return Expanded(flex: 3, child: content);
    }
    return content;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCategory;
  final bool isVertical;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isCategory = false,
    this.isVertical = false,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final effectiveLabelStyle =
        labelStyle ??
        textTheme.labelSmall?.copyWith(
          color: Colors.grey.shade500,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
        );

    final effectiveValueStyle =
        valueStyle ??
        textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: onSurface,
        );

    Widget content;
    if (isCategory) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isVertical
            ? MainAxisAlignment.center
            : MainAxisAlignment.end,
        children: [
          Icon(Icons.bookmark_outline, size: 18, color: onSurface),
          const SizedBox(width: 4),
          Flexible(
            child: AutoSizeText(
              value,
              style: effectiveValueStyle,
              maxLines: 2,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
              textAlign: isVertical ? TextAlign.center : TextAlign.end,
            ),
          ),
        ],
      );
    } else {
      content = AutoSizeText(
        value,
        style: effectiveValueStyle,
        maxLines: 2,
        minFontSize: 6,
        overflow: TextOverflow.ellipsis,
        textAlign: isVertical ? TextAlign.center : TextAlign.end,
        wrapWords: false,
      );
    }

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: effectiveLabelStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(child: content),
        ],
      );
    }

    return Row(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: effectiveLabelStyle),
        ),
        const SizedBox(width: 16),
        Expanded(child: content),
      ],
    );
  }
}

class _PlayAgainButton extends StatelessWidget {
  final VoidCallback onEndGame;

  const _PlayAgainButton({required this.onEndGame});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: FilledButton(
        onPressed: onEndGame,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GameScreenConstants.buttonBorderRadius,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.refresh_rounded,
              size: GameScreenConstants.buttonIconSize,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Play Again',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhoIsTheImposterSection extends StatelessWidget {
  final String startingPlayer;

  const _WhoIsTheImposterSection({required this.startingPlayer});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Who is the',
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              Text(
                'Imposter?',
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$startingPlayer starts!',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Discuss with your group and\ntry to identify the imposter',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevealButton extends StatelessWidget {
  final VoidCallback onReveal;

  const _RevealButton({required this.onReveal});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: GameScreenConstants.buttonFlex,
      child: Center(
        child: FilledButton(
          onPressed: onReveal,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                GameScreenConstants.buttonBorderRadius,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.visibility_rounded,
                size: GameScreenConstants.buttonIconSize,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'REVEAL IMPOSTER',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
