import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../lives/logic/lives_controller.dart';
import '../logic/game_controller.dart';
import '../logic/game_state.dart';
import 'widgets/category_wheel.dart';

/// The single-player game screen: a lives-gated lobby and the "Momentum" run
/// (spin the wheel, answer, then bank or risk the pot).
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
            RunPhase.lobby => const _LobbyView(),
            RunPhase.spinning => _SpinningView(state: state),
            RunPhase.question || RunPhase.decision => _PlayfieldView(state: state),
            RunPhase.finished => _ResultsView(state: state),
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

/// The pre-run gate: hearts and a Play button (or a countdown when out of
/// lives).
class _LobbyView extends StatelessWidget {
  const _LobbyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.lobbyReady, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            const _HeartsRow(),
            const SizedBox(height: 32),
            _PlayButton(label: l10n.play),
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
class _PlayButton extends ConsumerWidget {
  const _PlayButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(livesControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (lives.canPlay) {
      return FilledButton(
        onPressed: () => ref.read(gameControllerProvider.notifier).start(),
        child: Text(label),
      );
    }

    // Out of lives: tick to update the countdown and re-apply regeneration.
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
        FilledButton(onPressed: null, child: Text(l10n.outOfLives)),
        const SizedBox(height: 12),
        Text(l10n.nextLifeIn(_formatDuration(remaining)),
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

String _formatMultiplier(double m) =>
    m == m.roundToDouble() ? m.toInt().toString() : m.toString();

/// A compact run status bar: banked points, the at-risk pot, and the
/// multiplier.
class _RunHud extends StatelessWidget {
  const _RunHud({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.banked(state.banked), style: theme.textTheme.titleMedium),
          Text(l10n.pot(state.pot), style: theme.textTheme.titleMedium),
          Text(
            l10n.multiplier(_formatMultiplier(state.multiplier)),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// The wheel step: spin to pick a category for the next question.
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('$err')),
            data: (categories) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.spinPrompt,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 300,
                      child: CategoryWheel(
                        categories: categories,
                        spinLabel: l10n.spin,
                        onSelected: controller.onCategorySelected,
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

/// Shows the current question and its four options, plus the post-answer
/// decision controls (bank / risk / finish, or end the run on a wrong answer).
class _PlayfieldView extends ConsumerWidget {
  const _PlayfieldView({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(gameControllerProvider.notifier);
    final theme = Theme.of(context);
    final question = state.question!;
    final answered = state.isDecision;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunHud(state: state),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.category != null)
                    Text(state.category!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Color(state.category!.colorValue),
                            fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(question.text,
                          style: theme.textTheme.headlineSmall),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < question.options.length; i++) ...[
                    _OptionTile(
                      label: question.options[i],
                      state: _optionStateFor(i),
                      onTap: answered ? null : () => controller.answer(i),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  if (answered) _decisionControls(context, l10n, controller),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _decisionControls(
    BuildContext context,
    AppLocalizations l10n,
    GameController controller,
  ) {
    final correct = state.lastResult?.isCorrect ?? false;
    if (!correct) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.runOver,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.red.shade700)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: controller.endRun,
            child: Text(l10n.seeResults),
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
              child: FilledButton(
                onPressed: controller.bank,
                child: Text(l10n.bank),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonal(
                onPressed: controller.risk,
                child: Text(l10n.riskIt),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: controller.endRun, child: Text(l10n.finish)),
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

/// End-of-run summary with a lives-gated play-again button.
class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.roundComplete, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(l10n.points(state.banked), style: theme.textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(l10n.correctAnswers(state.correctCount),
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.bestPoints(state.bestScore),
                style: theme.textTheme.titleMedium),
            if (state.isNewBest) ...[
              const SizedBox(height: 12),
              Chip(
                avatar: const Icon(Icons.emoji_events, size: 18),
                label: Text(l10n.newBest),
                backgroundColor: Colors.amber.shade100,
              ),
            ],
            const SizedBox(height: 32),
            _PlayButton(label: l10n.playAgain),
          ],
        ),
      ),
    );
  }
}
