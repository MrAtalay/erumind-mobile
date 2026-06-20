import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lives/logic/lives_controller.dart';
import '../logic/game_controller.dart';
import '../logic/game_state.dart';

/// The single-player game screen: a lives-gated lobby, an active round, and an
/// end-of-round summary. No menu or wheel yet — just the core loop.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EruMind'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: _LivesBadge()),
        ],
      ),
      body: SafeArea(
        child: gameAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Something went wrong:\n$err')),
          data: (state) => switch (state.phase) {
            GamePhase.lobby => const _LobbyView(),
            GamePhase.playing => _QuestionView(state: state),
            GamePhase.finished => _ResultsView(state: state),
          },
        ),
      ),
    );
  }
}

/// Compact lives count for the app bar, e.g. ♥ 4.
class _LivesBadge extends ConsumerWidget {
  const _LivesBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesControllerProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite, color: Colors.red, size: 20),
        const SizedBox(width: 4),
        Text('${lives.lives}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// The pre-round gate: shows hearts and a Play button (or a countdown when out
/// of lives).
class _LobbyView extends StatelessWidget {
  const _LobbyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ready to play?', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            const _HeartsRow(),
            const SizedBox(height: 32),
            const _PlayButton(label: 'Play'),
          ],
        ),
      ),
    );
  }
}

/// A full row of hearts: filled for current lives, outlined for the rest.
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < lives.lives ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
              size: 32,
            ),
          ),
      ],
    );
  }
}

/// Lives-gated play control shared by the lobby and the results screen.
///
/// When a life is available it starts a round; otherwise it disables itself and
/// shows a live countdown to the next life.
class _PlayButton extends ConsumerWidget {
  const _PlayButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesControllerProvider);

    if (lives.canPlay) {
      return FilledButton(
        onPressed: () => ref.read(gameControllerProvider.notifier).start(),
        child: Text(label),
      );
    }

    // Out of lives: tick once a second to update the countdown, and re-apply
    // regeneration so the button re-enables the moment a life is earned.
    ref.listen(tickerProvider, (_, _) {
      ref.read(livesControllerProvider.notifier).refresh();
    });
    ref.watch(tickerProvider);

    final interval = ref.read(livesConfigProvider).refillInterval;
    final remaining =
        lives.timeUntilNext(ref.read(clockProvider)(), interval) ?? Duration.zero;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FilledButton(onPressed: null, child: Text('Out of lives')),
        const SizedBox(height: 12),
        Text('Next life in ${_formatDuration(remaining)}',
            style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

/// Shows the current question, the four options, and post-answer feedback.
class _QuestionView extends ConsumerWidget {
  const _QuestionView({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    final question = state.currentQuestion;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress + score header.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${state.questionNumber} / ${state.total}',
                  style: theme.textTheme.titleMedium),
              Text('Score: ${state.score}',
                  style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 24),

          // Question text.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                question.text,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // The four options.
          for (var i = 0; i < question.options.length; i++) ...[
            _OptionTile(
              label: question.options[i],
              state: _optionStateFor(i),
              onTap: state.isAnswered ? null : () => controller.answer(i),
            ),
            const SizedBox(height: 12),
          ],

          const Spacer(),

          // Next / Finish button appears only after answering.
          if (state.isAnswered)
            FilledButton(
              onPressed: controller.next,
              child: Text(state.isLastQuestion ? 'See results' : 'Next'),
            ),
        ],
      ),
    );
  }

  /// Decide how option [i] should look given the current answer state.
  _OptionVisualState _optionStateFor(int i) {
    if (!state.isAnswered) return _OptionVisualState.idle;
    final correctIndex = state.lastResult!.correctIndex;
    if (i == correctIndex) return _OptionVisualState.correct;
    if (i == state.selectedIndex) return _OptionVisualState.wrong;
    return _OptionVisualState.dimmed;
  }
}

enum _OptionVisualState { idle, correct, wrong, dimmed }

/// A single tappable answer option whose colour reflects the result.
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
    final scheme = Theme.of(context).colorScheme;

    final (Color bg, Color fg) = switch (state) {
      _OptionVisualState.idle => (scheme.surfaceContainerHighest, scheme.onSurface),
      _OptionVisualState.correct => (Colors.green.shade600, Colors.white),
      _OptionVisualState.wrong => (Colors.red.shade600, Colors.white),
      _OptionVisualState.dimmed => (
          scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          scheme.onSurface.withValues(alpha: 0.4),
        ),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Text(
            label,
            style: TextStyle(
                color: fg, fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// End-of-round summary with a lives-gated play-again button.
class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Round complete!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(
              '${state.score} points',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Correct: ${state.correctCount} / ${state.total}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Best: ${state.bestScore} points',
              style: theme.textTheme.titleMedium,
            ),
            if (state.isNewBest) ...[
              const SizedBox(height: 12),
              Chip(
                avatar: const Icon(Icons.emoji_events, size: 18),
                label: const Text('New best!'),
                backgroundColor: Colors.amber.shade100,
              ),
            ],
            const SizedBox(height: 32),
            const _PlayButton(label: 'Play again'),
          ],
        ),
      ),
    );
  }
}
