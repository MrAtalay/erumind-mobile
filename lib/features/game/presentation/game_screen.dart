import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/game_controller.dart';
import '../logic/game_state.dart';

/// The Phase 1 vertical slice: one question, four options, feedback, score.
///
/// No menu, no wheel yet — just enough to prove the core loop is fun and
/// runnable. A [ConsumerWidget] can read Riverpod providers via [ref].
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('EruMind')),
      body: SafeArea(
        child: gameAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Something went wrong:\n$err')),
          data: (state) => state.isFinished
              ? _ResultsView(state: state)
              : _QuestionView(state: state),
        ),
      ),
    );
  }
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

/// End-of-round summary with a play-again button.
class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(gameControllerProvider.notifier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Round complete!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(
              'You scored ${state.score} / ${state.total}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Best: ${state.bestScore} / ${state.total}',
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
            FilledButton(
              onPressed: controller.restart,
              child: const Text('Play again'),
            ),
          ],
        ),
      ),
    );
  }
}
