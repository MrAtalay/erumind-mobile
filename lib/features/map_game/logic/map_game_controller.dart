import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/game/logic/game_controller.dart';
import '../../../services/audio_service.dart';
import '../data/continent_defs.dart';
import 'map_game_state.dart';

final mapGameProvider =
    AsyncNotifierProvider.autoDispose<MapGameController, MapGameState>(MapGameController.new);

class MapGameController extends AsyncNotifier<MapGameState> {
  final _rng = Random();

  /// Question ids already asked this game — used to avoid repeats.
  final Set<String> _asked = {};

  @override
  Future<MapGameState> build() async {
    _asked.clear();
    return MapGameState.initial();
  }

  void restart() {
    _asked.clear();
    state = AsyncData(MapGameState.initial());
  }

  void _sfx(SoundEffect effect) {
    try {
      ref.read(audioServiceProvider).play(effect);
    } catch (_) {
      // Audio is best-effort; never let a missing backend break the game.
    }
  }

  // ── Phase: selectStart ───────────────────────────────────────────────────

  void selectStart(String continentId) {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.selectStart) return;

    // AI picks a different random starting continent
    final others = kContinents.map((c) => c.id).where((id) => id != continentId).toList()
      ..shuffle(_rng);
    final aiStart = others.first;

    final newOwnership = Map<String, Owner>.from(s.ownership)
      ..[continentId] = Owner.player
      ..[aiStart] = Owner.ai;

    state = AsyncData(s.copyWith(
      ownership: newOwnership,
      phase: MapGamePhase.playerTurn,
    ));
  }

  // ── Phase: playerTurn → playerQuestion ──────────────────────────────────

  Future<void> selectTarget(String continentId) async {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.playerTurn) return;
    if (s.ownership[continentId] == Owner.player) return;
    if (!_reachableByPlayer(s, continentId)) return;

    final categoryId = continentById(continentId)?.categoryId;
    final question = await _fetchRandomQuestion(categoryId);
    if (question == null) return;

    state = AsyncData(s.copyWith(
      playerTarget: continentId,
      currentQuestion: question,
      phase: MapGamePhase.playerQuestion,
    ));
  }

  // ── Phase: playerQuestion → result / tiebreakerQuestion ─────────────────

  Future<void> answerQuestion(int selectedIndex) async {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.playerQuestion) return;

    final question = s.currentQuestion!;
    final result = await ref.read(questionRepositoryProvider).checkAnswer(
      questionId: question.id,
      selectedIndex: selectedIndex,
    );

    final target = s.playerTarget!;
    final targetName = continentById(target)?.name ?? target;
    final ownership = Map<String, Owner>.from(s.ownership);

    String msg;
    Owner? roundWinner;
    if (result.isCorrect) {
      ownership[target] = Owner.player;
      roundWinner = Owner.player;
      msg = 'Doğru! $targetName ele geçirildi.';
      _sfx(SoundEffect.crown);
    } else {
      msg = 'Yanlış! $targetName alınamadı.';
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

  // ── Phase: tiebreakerQuestion → result ──────────────────────────────────

  void answerTiebreaker(int optionIndex) {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.tiebreakerQuestion) return;

    final tb = s.tiebreaker!;
    final playerChoice = tb.options[optionIndex];
    final aiChoice = tb.options[_rng.nextInt(tb.options.length)];
    final correct = tb.answer;

    final playerDist = (playerChoice - correct).abs();
    final aiDist = (aiChoice - correct).abs();

    final target = s.playerTarget!;
    final targetName = continentById(target)?.name ?? target;
    Map<String, Owner> ownership = Map.from(s.ownership);
    Owner? roundWinner;
    String msg;

    if (playerDist < aiDist) {
      ownership[target] = Owner.player;
      roundWinner = Owner.player;
      msg = 'Doğru cevap $correct. Sen $playerChoice, rakip $aiChoice dedi — '
          '$targetName senin!';
    } else if (aiDist < playerDist) {
      ownership[target] = Owner.ai;
      roundWinner = Owner.ai;
      msg = 'Doğru cevap $correct. Rakip $aiChoice ile daha yakındı — '
          '$targetName rakibe gitti.';
    } else {
      msg = 'Beraberlik! İkiniz de $playerChoice dediniz (doğru: $correct). '
          'Sonraki turda tekrar!';
    }

    final gameWinner = _checkWin(ownership);
    state = AsyncData(s.copyWith(
      ownership: ownership,
      phase: gameWinner != null ? MapGamePhase.gameOver : MapGamePhase.result,
      resultMessage: msg,
      roundWinner: roundWinner,
      winner: gameWinner,
      clearTiebreaker: true,
      clearPlayerTarget: true,
      clearAiTarget: true,
      clearQuestion: true,
    ));
  }

  // ── Phase: result → aiTurn → aiResult → playerTurn ───────────────────────

  /// From the player's result: the rival now takes a *visible* turn — it lines
  /// up an attack (target highlighted on the map), pauses, then resolves.
  Future<void> startAiTurn() async {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.result) return;

    final aiTarget = _pickAiTarget(s);
    if (aiTarget == null) {
      _toPlayerTurn(s); // rival is boxed in — skip straight back to the player
      return;
    }
    final aiName = continentById(aiTarget)?.name ?? aiTarget;

    state = AsyncData(s.copyWith(
      phase: MapGamePhase.aiTurn,
      aiTarget: aiTarget,
      resultMessage: 'Rakip $aiName bölgesine saldırıyor…',
      clearRoundWinner: true,
      clearPlayerTarget: true,
    ));
    _sfx(SoundEffect.spin);

    await Future.delayed(const Duration(milliseconds: 1500));
    final cur = state.value;
    if (cur == null || cur.phase != MapGamePhase.aiTurn) return;

    final ownership = Map<String, Owner>.from(cur.ownership);
    final wasPlayer = ownership[aiTarget] == Owner.player;
    final success = _rng.nextDouble() < (wasPlayer ? 0.35 : 0.60);

    String msg;
    Owner? roundWinner;
    if (success) {
      ownership[aiTarget] = Owner.ai;
      roundWinner = Owner.ai;
      msg = wasPlayer
          ? 'Rakip senin $aiName bölgeni ele geçirdi!'
          : 'Rakip $aiName bölgesini ele geçirdi.';
      _sfx(SoundEffect.crown);
    } else {
      msg = 'Rakip $aiName saldırısında başarısız oldu.';
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _reachableByPlayer(MapGameState s, String id) {
    return s.playerContinents.any((ownedId) {
      final def = continentById(ownedId);
      return def?.adjacentIds.contains(id) ?? false;
    });
  }

  String? _pickAiTarget(MapGameState s) {
    final reachable = <String>{};
    for (final ownedId in s.aiContinents) {
      final def = continentById(ownedId);
      if (def == null) continue;
      for (final adjId in def.adjacentIds) {
        if (s.ownership[adjId] != Owner.ai) reachable.add(adjId);
      }
    }
    if (reachable.isEmpty) return null;
    // Prefer neutral continents; occasionally attack player
    final neutral = reachable.where((id) => s.ownership[id] == Owner.neutral).toList();
    final pool = neutral.isNotEmpty ? neutral : reachable.toList();
    return pool[_rng.nextInt(pool.length)];
  }

  Owner? _checkWin(Map<String, Owner> ownership) {
    final total = ownership.length;
    if (ownership.values.where((o) => o == Owner.player).length == total) return Owner.player;
    if (ownership.values.where((o) => o == Owner.ai).length == total) return Owner.ai;
    return null;
  }

  Future<dynamic> _fetchRandomQuestion(String? categoryId) async {
    try {
      final all = await ref.read(questionRepositoryProvider).getQuestions();
      if (all.isEmpty) return null;

      // Prefer the continent's category; fall back to all if it has none.
      var pool = categoryId == null
          ? all
          : all.where((q) => q.categoryId == categoryId).toList();
      if (pool.isEmpty) pool = all;

      // Avoid repeats within a game; if the pool is exhausted, allow repeats.
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

// Utility used by MapScreen to compute reachable continents for the player.
Set<String> reachableContinentsFor(MapGameState state) {
  final reachable = <String>{};
  for (final ownedId in state.playerContinents) {
    final def = continentById(ownedId);
    if (def == null) continue;
    for (final adjId in def.adjacentIds) {
      if (state.ownership[adjId] != Owner.player) reachable.add(adjId);
    }
  }
  return reachable;
}
