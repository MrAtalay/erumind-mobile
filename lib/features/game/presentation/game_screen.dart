import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/audio_service.dart';
import '../../lives/logic/lives_controller.dart';
import '../logic/game_controller.dart';
import '../logic/game_state.dart';
import 'widgets/category_wheel.dart';

// ── Palette (same as MenuScreen) ──────────────────────────────────────────
const _bgTop    = Color(0xFF7A0020);
const _bgBot    = Color(0xFF2A0008);
const _red      = Color(0xFFCC1020);
const _redLight = Color(0xFFFF3040);

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBot],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _GameTopBar(gameAsync: gameAsync),
              Expanded(
                child: gameAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (err, _) => Center(
                    child: Text('$err',
                        style: const TextStyle(color: Colors.white70)),
                  ),
                  data: (state) => switch (state.phase) {
                    RunPhase.lobby    => const _LobbyView(),
                    RunPhase.spinning => _SpinningView(state: state),
                    RunPhase.question ||
                    RunPhase.decision => _PlayfieldView(state: state),
                    RunPhase.finished => _ResultsView(state: state),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom top bar ─────────────────────────────────────────────────────────

class _GameTopBar extends ConsumerWidget {
  const _GameTopBar({required this.gameAsync});

  final AsyncValue<GameState> gameAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesControllerProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'EruMind',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded,
                    color: _redLight, size: 16),
                const SizedBox(width: 5),
                Text(
                  '${lives.lives}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

// ── Run HUD ────────────────────────────────────────────────────────────────

class _RunHud extends StatelessWidget {
  const _RunHud({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _HudChip(
            label: l10n.banked(state.banked),
            icon: Icons.savings_rounded,
            iconColor: const Color(0xFF4ADE80),
          ),
          const SizedBox(width: 8),
          _HudChip(
            label: l10n.pot(state.pot),
            icon: Icons.toll_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '×${_formatMultiplier(state.multiplier)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Lobby ──────────────────────────────────────────────────────────────────

class _LobbyView extends StatelessWidget {
  const _LobbyView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.lobbyReady,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
            const _HeartsRow(),
            const SizedBox(height: 40),
            _PlayButton(label: l10n.play),
          ],
        ),
      ),
    );
  }
}

class _HeartsRow extends ConsumerWidget {
  const _HeartsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesControllerProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < lives.max; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Icon(
              i < lives.lives ? Icons.favorite : Icons.favorite_border,
              color: i < lives.lives ? _redLight : Colors.white30,
              size: 34,
            ),
          ),
      ],
    );
  }
}

class _PlayButton extends ConsumerWidget {
  const _PlayButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (lives.canPlay) {
      return GestureDetector(
        onTap: () => ref.read(gameControllerProvider.notifier).start(),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            color: _red,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _red.withAlpha(120),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    ref.listen(tickerProvider, (_, _) {
      ref.read(livesControllerProvider.notifier).refresh();
    });
    ref.watch(tickerProvider);

    final interval = ref.read(livesConfigProvider).refillInterval;
    final remaining =
        lives.timeUntilNext(ref.read(clockProvider)(), interval) ??
            Duration.zero;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            l10n.outOfLives,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.nextLifeIn(_formatDuration(remaining)),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

// ── Spinning view ──────────────────────────────────────────────────────────

class _SpinningView extends ConsumerWidget {
  const _SpinningView({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(gameControllerProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        _RunHud(state: state),
        Expanded(
          child: categoriesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white)),
            error: (err, _) => Center(child: Text('$err')),
            data: (categories) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.spinPrompt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 300,
                      child: CategoryWheel(
                        categories: categories,
                        spinLabel: l10n.spin,
                        onSelected: controller.onCategorySelected,
                        onSpinStart: () => ref
                            .read(audioServiceProvider)
                            .play(SoundEffect.spin),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Playfield ──────────────────────────────────────────────────────────────

class _PlayfieldView extends ConsumerWidget {
  const _PlayfieldView({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(gameControllerProvider.notifier);
    final question = state.question!;
    final answered = state.isDecision;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunHud(state: state),
        if (!answered)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: _QuestionTimer(key: ValueKey(question.id)),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category chip
                if (state.category != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(state.category!.colorValue)
                            .withAlpha(220),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        state.category!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),

                // Question card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    question.text,
                    style: const TextStyle(
                      color: Color(0xFF1A0010),
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Answer options
                for (var i = 0; i < question.options.length; i++) ...[
                  _OptionTile(
                    label: question.options[i],
                    state: _optionStateFor(i),
                    onTap: answered ? null : () => controller.answer(i),
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: 8),
                if (answered)
                  _decisionControls(context, ref, l10n, controller),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _decisionControls(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    GameController controller,
  ) {
    final correct = state.lastResult?.isCorrect ?? false;
    if (!correct) {
      final livesLeft = ref.watch(livesControllerProvider).lives;
      final message = livesLeft > 0
          ? (state.selectedIndex == null ? l10n.timeUp : l10n.wrongAnswer)
          : l10n.gameOverNoLives;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 15,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          _ActionButton(
            label: livesLeft > 0 ? l10n.continuePlaying : l10n.seeResults,
            onTap: livesLeft > 0
                ? controller.continueAfterWrong
                : controller.endRun,
            filled: true,
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: l10n.bank,
                onTap: controller.bank,
                filled: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: l10n.riskIt,
                onTap: controller.risk,
                filled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: controller.endRun,
          child: Text(
            l10n.finish,
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  _OptionVisualState _optionStateFor(int i) {
    if (!state.isDecision) return _OptionVisualState.idle;
    final correctIndex = state.lastResult!.correctIndex;
    if (i == correctIndex) return _OptionVisualState.correct;
    if (i == state.selectedIndex) return _OptionVisualState.wrong;
    return _OptionVisualState.dimmed;
  }
}

// ── Timer ──────────────────────────────────────────────────────────────────

class _QuestionTimer extends ConsumerStatefulWidget {
  const _QuestionTimer({super.key});

  @override
  ConsumerState<_QuestionTimer> createState() => _QuestionTimerState();
}

class _QuestionTimerState extends ConsumerState<_QuestionTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ref.read(questionDurationProvider),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          unawaited(ref.read(gameControllerProvider.notifier).timeUp());
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds =
        ref.read(questionDurationProvider).inSeconds;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final remaining = 1 - _controller.value;
        final secsLeft = (remaining * totalSeconds).ceil();
        final isUrgent = remaining < 0.3;
        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: remaining,
                  minHeight: 10,
                  backgroundColor: Colors.white.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUrgent ? _redLight : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 36,
              child: Text(
                '${secsLeft}s',
                style: TextStyle(
                  color: isUrgent ? _redLight : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Option tile ────────────────────────────────────────────────────────────

enum _OptionVisualState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionVisualState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color border) = switch (state) {
      _OptionVisualState.idle    => (Colors.white, const Color(0xFF1A0010), Colors.transparent),
      _OptionVisualState.correct => (const Color(0xFF16A34A), Colors.white, Colors.transparent),
      _OptionVisualState.wrong   => (_red, Colors.white, Colors.transparent),
      _OptionVisualState.dimmed  => (Colors.white.withAlpha(30), Colors.white54, Colors.transparent),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
          boxShadow: state == _OptionVisualState.idle
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? _red : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(color: Colors.white30, width: 1.5),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: _red.withAlpha(100),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Results ────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFFD700), size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.roundComplete,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.points(state.banked),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.correctAnswers(state.correctCount),
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.bestPoints(state.bestScore),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            if (state.isNewBest) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withAlpha(80),
                      width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.newBest,
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
            for (final crown in state.newCrowns) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: Colors.amber.shade600, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.newCrown(crown),
                      style: TextStyle(
                          color: Colors.amber.shade300,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),
            _PlayButton(label: l10n.playAgain),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

String _formatMultiplier(double m) =>
    m == m.roundToDouble() ? m.toInt().toString() : m.toString();
