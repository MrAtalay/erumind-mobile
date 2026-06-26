import 'dart:ui' show ImageFilter;

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

class _GameContent extends ConsumerWidget {
  final MapGameState state;
  final String? hoveredContinent;
  final ValueChanged<String?> onHover;

  const _GameContent({
    required this.state,
    required this.hoveredContinent,
    required this.onHover,
  });

  static const _focusPhases = {
    MapGamePhase.playerQuestion,
    MapGamePhase.tiebreakerQuestion,
    MapGamePhase.result,
    MapGamePhase.gameOver,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelecting = state.phase == MapGamePhase.selectStart ||
        state.phase == MapGamePhase.playerTurn;
    final isFocus = _focusPhases.contains(state.phase);

    return Stack(
      children: [
        // Full-screen map (calm backdrop).
        Positioned.fill(
          child: _MapArea(
            state: state,
            hoveredContinent: hoveredContinent,
            onHover: onHover,
          ),
        ),

        // Focused question/result moment: the map dims & blurs behind a
        // centred panel so a single thing has attention at a time.
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: isFocus
                ? _FocusOverlay(key: ValueKey(state.phase), state: state)
                : const SizedBox.shrink(),
          ),
        ),

        // Bottom-centre instruction chip while choosing a continent.
        if (isSelecting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(child: _InstructionChip(state: state)),
          ),

        // Top header (above the dim so the score stays readable).
        Positioned(top: 0, left: 0, right: 0, child: _HeaderOverlay(state: state)),
      ],
    );
  }
}

/// Dim + blur backdrop with the phase content centred on top.
class _FocusOverlay extends StatelessWidget {
  final MapGameState state;
  const _FocusOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: const Color(0xFF0A0205).withAlpha(165)),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 58, 24, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  child: switch (state.phase) {
                    MapGamePhase.playerQuestion => _QuestionPanel(state: state),
                    MapGamePhase.tiebreakerQuestion => _TiebreakerPanel(state: state),
                    MapGamePhase.result => _ResultPanel(state: state),
                    MapGamePhase.gameOver => _GameOverPanel(state: state),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header overlay ──────────────────────────────────────────────────────────────

const _kPlayerColor = Color(0xFF4FB68A);
const _kAiColor = Color(0xFFC97A78);

class _HeaderOverlay extends StatelessWidget {
  final MapGameState state;
  const _HeaderOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        children: [
          _GlassButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
          const Spacer(),
          _ScorePill(state: state),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }
}

/// Frosted circular icon button.
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.black.withAlpha(70),
          shape: CircleBorder(side: BorderSide(color: Colors.white.withAlpha(28))),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white70, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass scoreboard pill: faction counts + a slim world-control bar.
class _ScorePill extends StatelessWidget {
  final MapGameState state;
  const _ScorePill({required this.state});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(64),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(26)),
          ),
          // One compact row: counts flank a slim world-control bar.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Side(label: 'Sen', count: state.playerCount, color: _kPlayerColor),
              const SizedBox(width: 11),
              SizedBox(width: 88, child: _WorldControlBar(state: state)),
              const SizedBox(width: 11),
              _Side(label: 'Rakip', count: state.aiCount, color: _kAiColor, mirrored: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool mirrored;
  const _Side({required this.label, required this.count, required this.color, this.mirrored = false});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final text = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: TextStyle(color: Colors.white.withAlpha(185), fontWeight: FontWeight.w600, fontSize: 12)),
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
        Text('/7', style: TextStyle(color: Colors.white.withAlpha(85), fontWeight: FontWeight.w600, fontSize: 10)),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: mirrored ? [text, const SizedBox(width: 6), dot] : [dot, const SizedBox(width: 6), text],
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
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          for (var i = 0; i < kContinents.length; i++) ...[
            Expanded(
              child: Container(
                height: 6,
                color: switch (state.ownership[kContinents[i].id] ?? Owner.neutral) {
                  Owner.player => _kPlayerColor,
                  Owner.ai => _kAiColor,
                  Owner.neutral => Colors.white.withAlpha(34),
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
        _TargetBadge(text: '$targetName için mücadele'),
        const SizedBox(height: 22),
        Text(q.text,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
            textAlign: TextAlign.center),
        const SizedBox(height: 22),
        _AnswerGrid(
          labels: q.options,
          onSelect: (i) => ref.read(mapGameProvider.notifier).answerQuestion(i),
        ),
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
        const _TargetBadge(text: 'KAPIŞMA! En yakın cevabı bul'),
        const SizedBox(height: 22),
        Text(tb.text,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
            textAlign: TextAlign.center),
        const SizedBox(height: 22),
        _AnswerGrid(
          labels: tb.options.map((o) => o.toString()).toList(),
          onSelect: (i) => ref.read(mapGameProvider.notifier).answerTiebreaker(i),
        ),
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
    final color = won ? _kPlayerColor : lost ? _kAiColor : Colors.white70;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        Text(state.resultMessage ?? '',
            style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w600, height: 1.35),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        SizedBox(
          width: 260,
          child: FilledButton(
            onPressed: () => ref.read(mapGameProvider.notifier).nextTurn(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFCC1020),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('Devam', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
        Text(playerWon ? '🏆' : '💀', style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 14),
        Text(
          playerWon ? 'Dünya Hakimiyeti!' : 'Yenildin!',
          style: TextStyle(
            color: playerWon ? const Color(0xFFE6C878) : _kAiColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              child: const Text('Menü'),
            ),
            const SizedBox(width: 14),
            FilledButton(
              onPressed: () => ref.read(mapGameProvider.notifier).restart(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCC1020),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: const Text('Tekrar Oyna', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small gold pill used as the focal-overlay heading.
class _TargetBadge extends StatelessWidget {
  final String text;
  const _TargetBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFE6C878).withAlpha(28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6C878).withAlpha(90)),
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFEBCF86),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

// ── Shared: answer grid + button ──────────────────────────────────────────────

/// Lays answer options out two-per-row so all four fit in landscape height.
class _AnswerGrid extends StatelessWidget {
  final List<String> labels;
  final void Function(int) onSelect;
  const _AnswerGrid({required this.labels, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    Widget cell(int i) =>
        Expanded(child: _AnswerButton(label: labels[i], onTap: () => onSelect(i)));

    final rows = <Widget>[];
    for (var i = 0; i < labels.length; i += 2) {
      // IntrinsicHeight bounds the row so the two cells can share an equal
      // height (CrossAxisAlignment.stretch is illegal in an unbounded scroll).
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(i),
            const SizedBox(width: 12),
            if (i + 1 < labels.length) cell(i + 1) else const Spacer(),
          ],
        ),
      ));
      if (i + 2 < labels.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _AnswerButton extends StatelessWidget {
  final Object label;
  final VoidCallback onTap;
  const _AnswerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF241419).withAlpha(235),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withAlpha(36)),
        ),
      ),
      child: Text('$label',
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
    );
  }
}
