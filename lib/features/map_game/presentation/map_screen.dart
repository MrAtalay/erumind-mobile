import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/continent_defs.dart';
import '../logic/map_game_controller.dart';
import '../logic/map_game_state.dart';
import 'widgets/world_map_painter.dart';

/// The map game runs in landscape: a full-screen world map with a collapsible
/// side panel for questions/results. Orientation is locked on enter and
/// restored to portrait on exit (the rest of the app is portrait).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _hoveredContinent;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

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
            error: (e, _) => Center(
                child: Text('Hata: $e', style: const TextStyle(color: Colors.white))),
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

// ── Game content (landscape stack) ─────────────────────────────────────────────

class _GameContent extends ConsumerStatefulWidget {
  final MapGameState state;
  final String? hoveredContinent;
  final ValueChanged<String?> onHover;

  const _GameContent({
    required this.state,
    required this.hoveredContinent,
    required this.onHover,
  });

  @override
  ConsumerState<_GameContent> createState() => _GameContentState();
}

class _GameContentState extends ConsumerState<_GameContent> {
  /// Manual collapse of the side panel within the current phase.
  bool _collapsed = false;

  static const _panelPhases = {
    MapGamePhase.playerQuestion,
    MapGamePhase.tiebreakerQuestion,
    MapGamePhase.result,
    MapGamePhase.gameOver,
  };

  @override
  void didUpdateWidget(covariant _GameContent old) {
    super.didUpdateWidget(old);
    // A new phase starts fresh (re-open the panel if it was peeked closed).
    if (old.state.phase != widget.state.phase) _collapsed = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isPanelPhase = _panelPhases.contains(state.phase);
    final showPanel = isPanelPhase && !_collapsed;
    final isSelecting = state.phase == MapGamePhase.selectStart ||
        state.phase == MapGamePhase.playerTurn;

    return LayoutBuilder(
      builder: (context, c) {
        final panelW = (c.maxWidth * 0.40).clamp(280.0, 440.0);
        return Stack(
          children: [
            // Full-screen map.
            Positioned.fill(
              child: _MapArea(
                state: state,
                hoveredContinent: widget.hoveredContinent,
                onHover: widget.onHover,
              ),
            ),

            // Top header overlay.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _HeaderOverlay(state: state),
            ),

            // Bottom-centre instruction chip while choosing a continent.
            if (isSelecting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: Center(child: _InstructionChip(state: state)),
              ),

            // Right collapsible action panel.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              top: 0,
              bottom: 0,
              width: panelW,
              right: showPanel ? 0 : -panelW,
              child: _SidePanel(state: state),
            ),

            // Collapse / expand handle (only during panel phases).
            if (isPanelPhase)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                top: c.maxHeight / 2 - 28,
                right: showPanel ? panelW : 0,
                child: _PanelHandle(
                  collapsed: !showPanel,
                  onTap: () => setState(() => _collapsed = !_collapsed),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Header overlay ──────────────────────────────────────────────────────────────

class _HeaderOverlay extends StatelessWidget {
  final MapGameState state;
  const _HeaderOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(130), Colors.black.withAlpha(0)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: _CountChip(label: 'Sen', count: state.playerCount, color: const Color(0xFF4ADE80)),
              ),
              const Text('vs', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Expanded(
                child: _CountChip(label: 'Rakip', count: state.aiCount, color: const Color(0xFFF87171)),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 2),
          _WorldControlBar(state: state),
        ],
      ),
    );
  }
}

/// A 7-segment bar showing world control at a glance.
class _WorldControlBar extends StatelessWidget {
  final MapGameState state;
  const _WorldControlBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          for (var i = 0; i < kContinents.length; i++) ...[
            Expanded(
              child: Container(
                height: 7,
                color: switch (state.ownership[kContinents[i].id] ?? Owner.neutral) {
                  Owner.player => const Color(0xFF4ADE80),
                  Owner.ai => const Color(0xFFF87171),
                  Owner.neutral => Colors.white.withAlpha(40),
                },
              ),
            ),
            if (i != kContinents.length - 1) const SizedBox(width: 2),
          ],
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
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17)),
        Text('/7', style: TextStyle(color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

// ── Instruction chip (selection / turn) ─────────────────────────────────────────

class _InstructionChip extends StatelessWidget {
  final MapGameState state;
  const _InstructionChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final String text;
    if (state.phase == MapGamePhase.selectStart) {
      text = 'Başlangıç kıtanı seç — haritaya dokun';
    } else {
      final reachable = reachableContinentsFor(state);
      text = reachable.isEmpty
          ? 'Ulaşabileceğin kıta yok!'
          : 'Senin turun — altın çerçeveli komşu bir kıtaya dokun';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Collapse / expand handle ────────────────────────────────────────────────────

class _PanelHandle extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _PanelHandle({required this.collapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(170),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Icon(
          collapsed ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}

// ── Interactive map ─────────────────────────────────────────────────────────────

class _MapArea extends ConsumerWidget {
  final MapGameState state;
  final String? hoveredContinent;
  final ValueChanged<String?> onHover;

  const _MapArea({required this.state, required this.hoveredContinent, required this.onHover});

  bool get _isInteractive =>
      state.phase == MapGamePhase.selectStart || state.phase == MapGamePhase.playerTurn;

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
          onTapUp: !_isInteractive
              ? null
              : (details) {
                  final pos = details.localPosition;
                  final id = WorldMapPainter.continentAt(pos, size) ??
                      WorldMapPainter.nearestContinentAt(pos, size, candidates: candidates);
                  if (id == null) return;
                  _onTap(context, ref, id);
                },
          child: MouseRegion(
            onHover: !_isInteractive
                ? null
                : (event) {
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

// ── Side panel (phase-adaptive) ─────────────────────────────────────────────────

class _SidePanel extends StatelessWidget {
  final MapGameState state;
  const _SidePanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0008).withAlpha(235),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
        border: Border(left: BorderSide(color: Colors.white.withAlpha(25))),
      ),
      child: SafeArea(
        left: false,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  switch (state.phase) {
                    MapGamePhase.playerQuestion => _QuestionPanel(state: state),
                    MapGamePhase.tiebreakerQuestion => _TiebreakerPanel(state: state),
                    MapGamePhase.result => _ResultPanel(state: state),
                    MapGamePhase.gameOver => _GameOverPanel(state: state),
                    _ => const SizedBox.shrink(),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
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
            style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(q.text,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 14),
        ...List.generate(q.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
        const Text('KAPIŞMA! En yakın cevabı bul',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(tb.text,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 14),
        ...List.generate(tb.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
        Text(icon, style: const TextStyle(fontSize: 34)),
        const SizedBox(height: 8),
        Text(state.resultMessage ?? '',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => ref.read(mapGameProvider.notifier).nextTurn(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFCC1020),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
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
        Text(playerWon ? '🏆' : '💀', style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(
          playerWon ? 'Dünya Hakimiyeti!' : 'Yenildin!',
          style: TextStyle(
            color: playerWon ? const Color(0xFFFFD700) : const Color(0xFFFF6B6B),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => ref.read(mapGameProvider.notifier).restart(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFCC1020),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Tekrar Oyna'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white30),
          ),
          child: const Text('Menüye Dön'),
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
        backgroundColor: Colors.white.withAlpha(28),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white24),
        ),
      ),
      child: Text('$label', style: const TextStyle(fontSize: 14)),
    );
  }
}
