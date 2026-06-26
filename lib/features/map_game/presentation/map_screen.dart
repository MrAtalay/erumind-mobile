import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/continent_defs.dart';
import '../data/world_shapes.dart';
import '../logic/map_game_controller.dart';
import '../logic/map_game_state.dart';
import 'widgets/world_map_painter.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _hoveredContinent;

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(mapGameProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7A0020), Color(0xFF2A0008)],
          ),
        ),
        child: SafeArea(
          child: gameAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.white))),
            data: (state) => _GameContent(
              state: state,
              hoveredContinent: _hoveredContinent,
              onHover: (id) => setState(() => _hoveredContinent = id),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Game Content ──────────────────────────────────────────────────────────────

class _GameContent extends ConsumerWidget {
  final MapGameState state;
  final String? hoveredContinent;
  final ValueChanged<String?> onHover;

  const _GameContent({
    required this.state,
    required this.hoveredContinent,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _TopBar(state: state),
        _WorldControlBar(state: state),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AspectRatio(
                          aspectRatio: kMapAspect,
                          child: _MapArea(
                            state: state,
                            hoveredContinent: hoveredContinent,
                            onHover: onHover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _BottomPanel(state: state),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A 7-segment bar showing world control at a glance — each continent coloured
/// by its owner (green = you, red = rival, muted = unclaimed).
class _WorldControlBar extends StatelessWidget {
  final MapGameState state;
  const _WorldControlBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            for (var i = 0; i < kContinents.length; i++) ...[
              Expanded(
                child: Container(
                  height: 8,
                  color: switch (state.ownership[kContinents[i].id] ?? Owner.neutral) {
                    Owner.player  => const Color(0xFF4ADE80),
                    Owner.ai      => const Color(0xFFF87171),
                    Owner.neutral => Colors.white.withAlpha(36),
                  },
                ),
              ),
              if (i != kContinents.length - 1) const SizedBox(width: 2),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final MapGameState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: _CountChip(
              label: 'Sen',
              count: state.playerCount,
              color: const Color(0xFF4ADE80),
            ),
          ),
          const Text('vs', style: TextStyle(color: Colors.white54, fontSize: 12)),
          Expanded(
            child: _CountChip(
              label: 'Rakip',
              count: state.aiCount,
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17)),
        Text('/7', style: TextStyle(color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

// ── Interactive map ───────────────────────────────────────────────────────────

class _MapArea extends ConsumerWidget {
  final MapGameState state;
  final String? hoveredContinent;
  final ValueChanged<String?> onHover;

  const _MapArea({required this.state, required this.hoveredContinent, required this.onHover});

  bool get _isInteractive =>
      state.phase == MapGamePhase.selectStart ||
      state.phase == MapGamePhase.playerTurn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reachable = _isInteractive ? reachableContinentsFor(state) : const <String>{};
    final highlighted = state.phase == MapGamePhase.playerTurn ? hoveredContinent : null;

    final candidates = state.phase == MapGamePhase.selectStart
        ? kContinents.map((c) => c.id).toSet()
        : reachable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
            onTapUp: !_isInteractive ? null : (details) {
              final pos = details.localPosition;
              final id = WorldMapPainter.continentAt(pos, size) ??
                  WorldMapPainter.nearestContinentAt(pos, size, candidates: candidates);
              if (id == null) return;
              _onTap(context, ref, id);
            },
            child: MouseRegion(
              onHover: !_isInteractive ? null : (event) {
                final id = WorldMapPainter.continentAt(event.localPosition, size);
                onHover(id);
              },
              onExit: (_) => onHover(null),
              child: CustomPaint(
                size: size,
                painter: WorldMapPainter(
                  ownership: state.ownership,
                  reachable: reachable,
                  highlighted: highlighted,
                  dimUnreachable: state.phase == MapGamePhase.playerTurn,
                ),
              ),
            ),
          );
        },
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, String id) {
    final ctrl = ref.read(mapGameProvider.notifier);
    if (state.phase == MapGamePhase.selectStart) {
      ctrl.selectStart(id);
    } else if (state.phase == MapGamePhase.playerTurn) {
      ctrl.selectTarget(id);
    }
  }
}

// ── Bottom panel (phase-adaptive) ────────────────────────────────────────────

class _BottomPanel extends ConsumerWidget {
  final MapGameState state;
  const _BottomPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(110),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: switch (state.phase) {
        MapGamePhase.selectStart       => _StartInstruction(),
        MapGamePhase.playerTurn        => _TurnInstruction(state: state),
        MapGamePhase.playerQuestion    => _QuestionPanel(state: state),
        MapGamePhase.tiebreakerQuestion => _TiebreakerPanel(state: state),
        MapGamePhase.result            => _ResultPanel(state: state),
        MapGamePhase.gameOver          => _GameOverPanel(state: state),
      },
    );
  }
}

// ── Panel: selectStart ────────────────────────────────────────────────────────

class _StartInstruction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Başlangıç kıtanı seç',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('Haritaya dokunarak kıtanı seç. Rakibin rastgele bir kıta seçecek.',
            style: TextStyle(color: Colors.white60, fontSize: 13), textAlign: TextAlign.center),
      ],
    );
  }
}

// ── Panel: playerTurn ─────────────────────────────────────────────────────────

class _TurnInstruction extends StatelessWidget {
  final MapGameState state;
  const _TurnInstruction({required this.state});

  @override
  Widget build(BuildContext context) {
    final reachable = reachableContinentsFor(state);
    final hint = reachable.isEmpty
        ? 'Ulaşabileceğin kıta yok!'
        : 'Saldırmak için altın çerçeveli komşu bir kıtaya dokun';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Senin turun',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(hint, style: const TextStyle(color: Colors.white60, fontSize: 13),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ── Panel: playerQuestion ─────────────────────────────────────────────────────

class _QuestionPanel extends ConsumerWidget {
  final MapGameState state;
  const _QuestionPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = state.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    final targetDef = state.playerTarget != null ? continentById(state.playerTarget!) : null;
    final targetName = targetDef?.name.replaceAll('\n', ' ') ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$targetName için mücadele!',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(q.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        ...List.generate(q.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _AnswerButton(
              label: q.options[i],
              onTap: () => ref.read(mapGameProvider.notifier).answerQuestion(i),
            ),
          );
        }),
      ],
    );
  }
}

// ── Panel: tiebreakerQuestion ─────────────────────────────────────────────────

class _TiebreakerPanel extends ConsumerWidget {
  final MapGameState state;
  const _TiebreakerPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tb = state.tiebreaker;
    if (tb == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('KAPIŞMA! En yakın cevabı bul →',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(tb.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        ...List.generate(tb.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _AnswerButton(
              label: tb.options[i].toString(),
              onTap: () => ref.read(mapGameProvider.notifier).answerTiebreaker(i),
            ),
          );
        }),
      ],
    );
  }
}

// ── Panel: result ─────────────────────────────────────────────────────────────

class _ResultPanel extends ConsumerWidget {
  final MapGameState state;
  const _ResultPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final won = state.roundWinner == Owner.player;
    final lost = state.roundWinner == Owner.ai;
    final isDraw = (state.resultMessage ?? '').startsWith('Beraberlik');
    final icon = won ? '🌍' : lost ? '😬' : isDraw ? '🤝' : '😐';
    final color = won ? const Color(0xFF4ADE80) : lost ? const Color(0xFFFF6B6B) : Colors.white70;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(state.resultMessage ?? '',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => ref.read(mapGameProvider.notifier).nextTurn(),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFCC1020)),
            child: const Text('Devam'),
          ),
        ),
      ],
    );
  }
}

// ── Panel: gameOver ───────────────────────────────────────────────────────────

class _GameOverPanel extends ConsumerWidget {
  final MapGameState state;
  const _GameOverPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerWon = state.winner == Owner.player;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          playerWon ? '🏆 Dünya Hakimiyeti!' : '💀 Yenildin!',
          style: TextStyle(
            color: playerWon ? const Color(0xFFFFD700) : const Color(0xFFFF6B6B),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30)),
                child: const Text('Menü'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => ref.read(mapGameProvider.notifier).restart(),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFCC1020)),
                child: const Text('Tekrar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Shared: AnswerButton ──────────────────────────────────────────────────────

class _AnswerButton extends StatelessWidget {
  final Object label;
  final VoidCallback onTap;
  const _AnswerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withAlpha(30),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white24),
        ),
      ),
      child: Text('$label', style: const TextStyle(fontSize: 13)),
    );
  }
}
