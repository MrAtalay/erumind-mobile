import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../features/game/logic/game_controller.dart';
import '../../../services/audio_service.dart';
import '../data/continent_defs.dart';
import 'map_game_state.dart';

final mapGameProvider =
    AsyncNotifierProvider.autoDispose<MapGameController, MapGameState>(MapGameController.new);

/// Category chosen on the select screen for the next match ('mixed' = any).
/// Read by [MapGameController.build] when a fresh match starts.
final pendingMatchCategoryProvider = StateProvider<String>((ref) => 'mixed');

class MapGameController extends AsyncNotifier<MapGameState> {
  final _rng = Random();

  /// Question ids already asked this match — used to avoid repeats.
  final Set<String> _asked = {};

  @override
  Future<MapGameState> build() async {
    _asked.clear();
    return MapGameState.initial(categoryId: ref.read(pendingMatchCategoryProvider));
  }

  /// Starts a fresh match drawing questions from [categoryId] ('mixed' = any).
  void startMatch(String categoryId) {
    _asked.clear();
    state = AsyncData(MapGameState.initial(categoryId: categoryId));
  }

  void restart() {
    _asked.clear();
    state = AsyncData(MapGameState.initial(categoryId: state.requireValue.categoryId));
  }

  void _sfx(SoundEffect effect) {
    try {
      ref.read(audioServiceProvider).play(effect);
    } catch (_) {
      // Audio is best-effort; never let a missing backend break the game.
    }
  }

  // ── Player turn → question ────────────────────────────────────────────────

  Future<void> selectTarget(String continentId) async {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.playerTurn) return;
    if (!reachableContinentsFor(s).contains(continentId)) return;

    final question = await _fetchRandomQuestion(s.categoryId);
    if (question == null) return;

    state = AsyncData(s.copyWith(
      playerTarget: continentId,
      currentQuestion: question,
      phase: MapGamePhase.playerQuestion,
    ));
  }

  // ── Question → result (player only) ───────────────────────────────────────

  Future<void> answerQuestion(int selectedIndex) async {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.playerQuestion) return;

    final question = s.currentQuestion!;
    final result = await ref.read(questionRepositoryProvider).checkAnswer(
      questionId: question.id,
      selectedIndex: selectedIndex,
    );

    final target = s.playerTarget!;
    final name = continentById(target)?.name ?? target;
    final isWar = s.matchPhase == MatchPhase.war;
    final ownership = Map<String, Owner>.from(s.ownership);

    String msg;
    Owner? roundWinner;
    if (result.isCorrect) {
      ownership[target] = Owner.player;
      roundWinner = Owner.player;
      msg = isWar ? 'Doğru! $name ele geçirildi.' : 'Doğru! $name kapıldı.';
      _sfx(SoundEffect.crown);
    } else {
      msg = isWar ? 'Yanlış! $name alınamadı.' : 'Yanlış! $name kapılamadı.';
      _sfx(SoundEffect.wrong);
    }

    final gameWinner = _checkWin(ownership);
    state = AsyncData(s.copyWith(
      ownership: ownership,
      phase: gameWinner != null ? MapGamePhase.gameOver : MapGamePhase.result,
      resultMessage: msg,
      roundWinner: roundWinner,
      winner: gameWinner,
      clearQuestion: true,
    ));
  }

  // ── Result → aiTurn → aiResult → playerTurn ───────────────────────────────

  Future<void> startAiTurn() async {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.result) return;

    final aiTarget = _pickAiTarget(s);
    if (aiTarget == null) {
      _toPlayerTurn(s); // rival is boxed in — back to the player
      return;
    }
    final name = continentById(aiTarget)?.name ?? aiTarget;
    final isWar = s.matchPhase == MatchPhase.war;

    state = AsyncData(s.copyWith(
      phase: MapGamePhase.aiTurn,
      aiTarget: aiTarget,
      resultMessage: isWar
          ? 'Rakip $name bölgesine saldırıyor…'
          : 'Rakip $name bölgesini kapmaya çalışıyor…',
      clearRoundWinner: true,
      clearPlayerTarget: true,
    ));
    _sfx(SoundEffect.spin);

    await Future.delayed(const Duration(milliseconds: 1500));
    final cur = state.value;
    if (cur == null || cur.phase != MapGamePhase.aiTurn) return;

    final ownership = Map<String, Owner>.from(cur.ownership);
    final success = _rng.nextDouble() < (isWar ? 0.40 : 0.65);

    String msg;
    Owner? roundWinner;
    if (success) {
      ownership[aiTarget] = Owner.ai;
      roundWinner = Owner.ai;
      msg = isWar
          ? 'Rakip senin $name bölgeni ele geçirdi!'
          : 'Rakip $name bölgesini kaptı.';
      _sfx(SoundEffect.crown);
    } else {
      msg = isWar
          ? 'Rakip $name saldırısında başarısız oldu.'
          : 'Rakip $name bölgesini kapamadı.';
    }

    final gameWinner = _checkWin(ownership);
    state = AsyncData(cur.copyWith(
      ownership: ownership,
      phase: gameWinner != null ? MapGamePhase.gameOver : MapGamePhase.aiResult,
      resultMessage: msg,
      roundWinner: roundWinner,
      winner: gameWinner,
    ));
  }

  void endAiTurn() {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.aiResult) return;
    _toPlayerTurn(s);
  }

  void _toPlayerTurn(MapGameState s) {
    state = AsyncData(s.copyWith(
      phase: MapGamePhase.playerTurn,
      clearResult: true,
      clearRoundWinner: true,
      clearPlayerTarget: true,
      clearAiTarget: true,
      clearQuestion: true,
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _pickAiTarget(MapGameState s) {
    if (s.matchPhase == MatchPhase.expansion) {
      final neutral = s.ownership.entries
          .where((e) => e.value == Owner.neutral)
          .map((e) => e.key)
          .toList();
      if (neutral.isEmpty) return null;
      return neutral[_rng.nextInt(neutral.length)];
    }
    // War: attack a player region adjacent to AI territory.
    final targets = <String>{};
    for (final owned in s.aiContinents) {
      for (final adj in continentById(owned)?.adjacentIds ?? const []) {
        if (s.ownership[adj] == Owner.player) targets.add(adj);
      }
    }
    if (targets.isEmpty) return null;
    final list = targets.toList();
    return list[_rng.nextInt(list.length)];
  }

  Owner? _checkWin(Map<String, Owner> ownership) {
    final total = ownership.length;
    if (ownership.values.where((o) => o == Owner.player).length == total) return Owner.player;
    if (ownership.values.where((o) => o == Owner.ai).length == total) return Owner.ai;
    return null;
  }

  Future<dynamic> _fetchRandomQuestion(String categoryId) async {
    try {
      final all = await ref.read(questionRepositoryProvider).getQuestions();
      if (all.isEmpty) return null;

      // 'mixed' draws from every category; otherwise filter to the match category.
      var pool = categoryId == 'mixed'
          ? all
          : all.where((q) => q.categoryId == categoryId).toList();
      if (pool.isEmpty) pool = all;

      final fresh = pool.where((q) => !_asked.contains(q.id)).toList();
      final picks = fresh.isNotEmpty ? fresh : pool;

      final q = picks[_rng.nextInt(picks.length)];
      _asked.add(q.id);
      return q;
    } catch (_) {
      return null;
    }
  }
}

/// Regions the player may act on this turn:
/// - expansion → every neutral region (claim empty land),
/// - war → enemy regions adjacent to the player's territory.
Set<String> reachableContinentsFor(MapGameState s) {
  if (s.matchPhase == MatchPhase.expansion) {
    return s.ownership.entries
        .where((e) => e.value == Owner.neutral)
        .map((e) => e.key)
        .toSet();
  }
  final out = <String>{};
  for (final owned in s.playerContinents) {
    for (final adj in continentById(owned)?.adjacentIds ?? const []) {
      if (s.ownership[adj] == Owner.ai) out.add(adj);
    }
  }
  return out;
}
