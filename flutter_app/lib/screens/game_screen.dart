import 'package:flutter/material.dart';
import 'dart:math';

/// The main game screen where players view their roles.
class GameScreen extends StatefulWidget {
  final int playerCount;
  final List<String> playerNames;
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
  bool _useDecoyWord = false;

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
      // Random: pick any number from 0 to playerCount
      numImposters = Random().nextInt(widget.playerCount + 1);
    }
    // Safety cap: at minimum 0, at maximum playerCount
    numImposters = numImposters.clamp(0, widget.playerCount);

    // Assign roles
    final random = Random();
    while (_imposterIndices.length < numImposters) {
      int index = random.nextInt(widget.playerCount);
      if (!_imposterIndices.contains(index)) {
        _imposterIndices.add(index);
        _playerRoles[index] = 1;
      }
    }

    // Select secret word
    _secretWord = widget.words[random.nextInt(widget.words.length)];

    // Select decoy word (must be different from secret word)
    if (_useDecoyWord) {
      List<String> remainingWords = List.from(widget.words)
        ..remove(_secretWord);

      if (remainingWords.isNotEmpty) {
        _decoyWord = remainingWords[random.nextInt(remainingWords.length)];
      } else {
        // Fallback if category has only 1 word (unlikely but safe)
        _decoyWord = _secretWord;
        _useDecoyWord = false; // Disable if we can't find a different word
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
        secretWord: _secretWord,
        decoyWord: _useDecoyWord ? _decoyWord : null,
        onReveal: _revealImposter,
        onEndGame: () => Navigator.pop(context),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = (min(screenWidth, screenHeight) / 375.0).clamp(
      0.8,
      10.0,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Header section
                  SizedBox(height: 24 * scaleFactor),
                  Text(
                    'Next Role',
                    style: TextStyle(
                      fontSize: 28 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF181811),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    'Ready to discover who you are?',
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      color: const Color(0xFF898961),
                    ),
                  ),
                  SizedBox(height: 24 * scaleFactor),
                  Center(
                    child: Semantics(
                      button: true,
                      label: _isFront
                          ? '${widget.playerNames[_currentPlayerIndex]} card. Tap to reveal your role.'
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
                                  ? _CardFront(
                                      playerName: widget
                                          .playerNames[_currentPlayerIndex],
                                    )
                                  : Transform(
                                      transform: Matrix4.identity()
                                        ..rotateY(pi),
                                      alignment: Alignment.center,
                                      child: _CardBack(
                                        isImposter:
                                            _playerRoles[_currentPlayerIndex] ==
                                            1,
                                        secretWord: _secretWord,
                                        decoyWord: _useDecoyWord
                                            ? _decoyWord
                                            : null,
                                        hint: widget.showImposterHints
                                            ? widget.categoryMap[_secretWord]
                                            : null,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Next Player button styled like yellow pill
                  Padding(
                    padding: EdgeInsets.all(24.0 * scaleFactor),
                    child: GestureDetector(
                      onTap: _isFront ? null : _nextPlayer,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isFront ? 0.4 : 1.0,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: 18 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F042),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: _isFront
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFF0F042,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 12 * scaleFactor,
                                      offset: Offset(0, 4 * scaleFactor),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _currentPlayerIndex == widget.playerCount - 1
                                    ? Icons.play_arrow_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 24 * scaleFactor,
                                color: const Color(0xFF181811),
                              ),
                              SizedBox(width: 8 * scaleFactor),
                              Text(
                                _currentPlayerIndex == widget.playerCount - 1
                                    ? 'START GAME'
                                    : 'NEXT PLAYER',
                                style: TextStyle(
                                  fontSize: 16 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF181811),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
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
      duration: const Duration(milliseconds: 2500),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = (screenWidth) / 375.0;
    final vScale = scaleFactor;

    // Natural card size based on content scaling
    final naturalWidth = 320.0 * scaleFactor;
    final naturalHeight = 420.0 * vScale;

    // Constrain to not exceed screen with some margin
    final cardWidth = min(naturalWidth, screenWidth * 0.9);
    final cardHeight = min(naturalHeight, screenHeight * 0.75);

    // Pastel yellow/cream theme colors
    const primaryYellow = Color(0xFFF0F042);
    const cardBg = Color(0xFFFFFFF8);
    const textDark = Color(0xFF181811);
    const textMuted = Color(0xFF898961);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseScale =
            1.0 +
            (_pulseAnimation.value < 0.5
                ? _pulseAnimation.value * 0.04
                : (1 - _pulseAnimation.value) * 0.04);
        final glowOpacity =
            (_pulseAnimation.value < 0.5
                ? _pulseAnimation.value
                : (1 - _pulseAnimation.value)) *
            0.4;

        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24 * scaleFactor),
              border: Border.all(
                color: primaryYellow.withValues(alpha: 0.3),
                width: 8 * scaleFactor,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryYellow.withValues(alpha: glowOpacity),
                  blurRadius: 30 * scaleFactor,
                  spreadRadius: 5 * scaleFactor,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20 * scaleFactor,
                  offset: Offset(0, 10 * vScale),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative radial gradient background
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          primaryYellow.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: EdgeInsets.all(24 * scaleFactor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Question mark icon in circular container
                      Container(
                        padding: EdgeInsets.all(24 * scaleFactor),
                        decoration: BoxDecoration(
                          color: primaryYellow.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.question_mark_rounded,
                          size: 80 * scaleFactor,
                          color: primaryYellow,
                        ),
                      ),
                      SizedBox(height: 16 * vScale),
                      // "SECRET" text
                      Text(
                        'SECRET',
                        style: TextStyle(
                          fontSize: 24 * scaleFactor,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                          letterSpacing: 8,
                        ),
                      ),
                      SizedBox(height: 24 * vScale),
                      // Instruction text
                      Text(
                        'Pass the phone to',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          color: textMuted,
                        ),
                      ),
                      SizedBox(height: 8 * vScale),
                      // Player name badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24 * scaleFactor,
                          vertical: 10 * vScale,
                        ),
                        decoration: BoxDecoration(
                          color: primaryYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.playerName,
                            style: TextStyle(
                              fontSize: 20 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24 * vScale),
                      // "TAP TO REVEAL ROLE" text (not a button)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 20 * scaleFactor,
                            color: textMuted,
                          ),
                          SizedBox(width: 8 * scaleFactor),
                          Text(
                            'TAP TO REVEAL',
                            style: TextStyle(
                              fontSize: 12 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              color: textMuted,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The back of the role card showing role and secret word.
class _CardBack extends StatelessWidget {
  final bool isImposter;
  final String secretWord;
  final String? decoyWord;
  final String? hint;

  const _CardBack({
    required this.isImposter,
    required this.secretWord,
    this.decoyWord,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final scaleFactor = screenWidth / 375.0;
    final vScale = scaleFactor;

    final naturalWidth = 320.0 * scaleFactor;
    final naturalHeight = 420.0 * vScale;

    final cardWidth = min(naturalWidth, screenWidth * 0.9);
    final cardHeight = min(naturalHeight, screenHeight * 0.75);

    // Determine if showing imposter (without decoy word = true imposter)
    final showingAsImposter = isImposter && decoyWord == null;

    // Color themes
    const imposterBg = Color(0xFFFEE2E2);
    const imposterAccent = Color(0xFFEF4444);
    const imposterText = Color(0xFF7F1D1D);
    const imposterMuted = Color(0xFF991B1B);

    const innocentBg = Color(0xFFFFFFFF);
    const innocentAccent = Color(0xFF10B981);
    const innocentText = Color(0xFF064E3B);
    const innocentMuted = Color(0xFF3B6E58);

    final bgColor = showingAsImposter ? imposterBg : innocentBg;
    final accentColor = showingAsImposter ? imposterAccent : innocentAccent;
    final textColor = showingAsImposter ? imposterText : innocentText;
    final mutedColor = showingAsImposter ? imposterMuted : innocentMuted;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(40 * scaleFactor),
        border: Border.all(color: Colors.white, width: 4 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 64 * scaleFactor,
            offset: Offset(0, 32 * vScale),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background icon
          Positioned.fill(
            child: Center(
              child: Transform.rotate(
                angle: showingAsImposter ? -0.2 : 0.2,
                child: Icon(
                  showingAsImposter ? Icons.masks : Icons.verified_user,
                  size: 280 * scaleFactor,
                  color: accentColor.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: EdgeInsets.all(24 * scaleFactor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon in circle
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showingAsImposter
                        ? Icons.sentiment_very_dissatisfied
                        : Icons.sentiment_very_satisfied,
                    size: 56 * scaleFactor,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: 16 * vScale),
                // Role title
                Text(
                  showingAsImposter ? 'IMPOSTER' : 'INNOCENT',
                  style: TextStyle(
                    fontSize: 36 * scaleFactor,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4 * vScale),
                // Subtitle
                Text(
                  showingAsImposter
                      ? 'YOU ARE THE DECEIVER'
                      : 'You belong here',
                  style: TextStyle(
                    fontSize: 11 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: mutedColor,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 24 * vScale),
                // Word/Category box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scaleFactor,
                    vertical: 20 * vScale,
                  ),
                  decoration: BoxDecoration(
                    color: showingAsImposter
                        ? Colors.white.withValues(alpha: 0.4)
                        : innocentAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24 * scaleFactor),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        showingAsImposter ? 'CATEGORY' : 'SECRET WORD',
                        style: TextStyle(
                          fontSize: 10 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: mutedColor.withValues(alpha: 0.6),
                          letterSpacing: 4,
                        ),
                      ),
                      SizedBox(height: 8 * vScale),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          showingAsImposter
                              ? (hint ?? 'UNKNOWN').toUpperCase()
                              : ((isImposter && decoyWord != null)
                                        ? decoyWord!
                                        : secretWord)
                                    .toUpperCase(),
                          style: TextStyle(
                            fontSize: 32 * scaleFactor,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom decoration icons
        ],
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
  final String secretWord;
  final String? decoyWord;
  final VoidCallback onReveal;
  final VoidCallback onEndGame;

  const _DiscussionView({
    required this.timeLimitSeconds,
    required this.timeLeft,
    required this.imposterRevealed,
    required this.imposterIndices,
    required this.imposterNames,
    required this.secretWord,
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

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );

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
    final screenWidth = MediaQuery.of(context).size.width;

    // Simplified linear scale for phones
    final scaleFactor = screenWidth / 375.0;
    final vScale = scaleFactor;

    // Responsive heights and widths - based on scaleFactor to grow with content
    final contentAreaHeight = 310.0 * vScale;
    final buttonAreaHeight = 80.0 * vScale;
    final cardMaxWidth = 340.0 * scaleFactor;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 20 * vScale,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardMaxWidth),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24 * scaleFactor,
                  vertical: 24 * vScale,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(32 * scaleFactor),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 40 * scaleFactor,
                      offset: Offset(0, 20 * vScale),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20 * scaleFactor,
                      offset: Offset(0, 10 * vScale),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon and title
                    Container(
                      padding: EdgeInsets.all(12 * vScale),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.1),
                            colorScheme.secondary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.groups_rounded,
                        size: 32 * vScale,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 12 * vScale),
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 80 * vScale),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Discussion Time!',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  fontSize: 24 * vScale,
                                ),
                          ),
                          SizedBox(height: 4 * vScale),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              widget.imposterRevealed
                                  ? 'The imposter has been revealed!'
                                  : 'Find the imposter among you',
                              key: ValueKey(widget.imposterRevealed),
                              style: TextStyle(
                                fontSize: 14 * vScale,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20 * vScale),

                    // Responsive height container for Timer or Imposter Identity
                    SizedBox(
                      height: contentAreaHeight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                        child: widget.imposterRevealed
                            ? AnimatedBuilder(
                                animation: _revealAnimation,
                                builder: (context, child) {
                                  return Column(
                                    key: const ValueKey('imposter_reveal'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Opacity(
                                        opacity: Interval(
                                          0.0,
                                          0.4,
                                          curve: Curves.easeOut,
                                        ).transform(_revealController.value),
                                        child: Transform.scale(
                                          scale: Interval(
                                            0.0,
                                            0.5,
                                            curve: Curves.elasticOut,
                                          ).transform(_revealController.value),
                                          child: Icon(
                                            Icons.person_off_rounded,
                                            color: Colors.red.shade600,
                                            size: 56 * vScale,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8 * vScale),
                                      Opacity(
                                        opacity: Interval(
                                          0.2,
                                          0.6,
                                          curve: Curves.easeOut,
                                        ).transform(_revealController.value),
                                        child: Transform.translate(
                                          offset: Offset(
                                            0,
                                            20 *
                                                (1 -
                                                    Interval(
                                                      0.2,
                                                      0.6,
                                                      curve: Curves.easeOut,
                                                    ).transform(
                                                      _revealController.value,
                                                    )),
                                          ),
                                          child: Text(
                                            'IMPOSTER',
                                            style: TextStyle(
                                              fontSize: 14 * vScale,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.red.shade400,
                                              letterSpacing: 3.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Opacity(
                                        opacity: Interval(
                                          0.3,
                                          0.7,
                                          curve: Curves.easeOut,
                                        ).transform(_revealController.value),
                                        child: Transform.scale(
                                          scale: Interval(
                                            0.3,
                                            0.8,
                                            curve: Curves.elasticOut,
                                          ).transform(_revealController.value),
                                          child: Column(
                                            children: [
                                              for (final name
                                                  in widget.imposterNames)
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontSize: 32 * vScale,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red.shade700,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16 * vScale),
                                      Opacity(
                                        opacity: Interval(
                                          0.5,
                                          0.9,
                                          curve: Curves.easeOut,
                                        ).transform(_revealController.value),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Secret Word:',
                                              style: TextStyle(
                                                fontSize: 12 * vScale,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            Text(
                                              widget.secretWord,
                                              style: TextStyle(
                                                fontSize: 32 * vScale,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            if (widget.decoyWord != null) ...[
                                              SizedBox(height: 12 * vScale),
                                              Text(
                                                'Odd One Out:',
                                                style: TextStyle(
                                                  fontSize: 12 * vScale,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              Text(
                                                widget.decoyWord!,
                                                style: TextStyle(
                                                  fontSize: 24 * vScale,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : (widget.timeLimitSeconds > 0 &&
                                      widget.timeLeft != null
                                  ? _CircularTimer(
                                      key: const ValueKey('timer'),
                                      timeLeft: widget.timeLeft!,
                                      totalSeconds: widget.timeLimitSeconds,
                                      size: contentAreaHeight * 0.8,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('empty'),
                                    )),
                      ),
                    ),
                    SizedBox(height: 20 * vScale),

                    // Action buttons
                    // Responsive height container for Primary Action (Reveal or End Game)
                    SizedBox(
                      height: buttonAreaHeight,
                      child: widget.imposterRevealed
                          ? Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.error.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: widget.onEndGame,
                                icon: Icon(
                                  Icons.exit_to_app_rounded,
                                  size: 20 * vScale,
                                ),
                                label: const Text('End Game'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: colorScheme.onError,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14 * vScale,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 16 * vScale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: widget.onReveal,
                                icon: Icon(
                                  Icons.visibility_rounded,
                                  size: 18 * vScale,
                                ),
                                label: const Text('Reveal Imposter'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: colorScheme.onPrimary,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14 * vScale,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 14 * vScale,
                                    fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

/// Circular timer with animated progress ring.
class _CircularTimer extends StatelessWidget {
  final Duration timeLeft;
  final int totalSeconds;
  final double size;

  const _CircularTimer({
    super.key,
    required this.timeLeft,
    required this.totalSeconds,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = timeLeft.inSeconds / totalSeconds;
    final isLow = timeLeft.inSeconds <= 30;
    final isTimeUp = timeLeft == Duration.zero;

    // Responsive scaling inside timer
    final timerScale = size / 160.0;

    // Color transitions based on time remaining
    Color timerColor;
    if (isTimeUp) {
      timerColor = Colors.red;
    } else if (isLow) {
      timerColor = Colors.orange;
    } else {
      timerColor = colorScheme.primary;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6 * timerScale,
              backgroundColor: timerColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                timerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Foreground progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6 * timerScale,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(timerColor),
            ),
          ),
          // Timer text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTimeUp
                    ? "TIME'S UP"
                    : '${timeLeft.inMinutes}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: (isTimeUp ? 18 : 34) * timerScale,
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!isTimeUp)
                Text(
                  'remaining',
                  style: TextStyle(
                    fontSize: 11 * timerScale,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
