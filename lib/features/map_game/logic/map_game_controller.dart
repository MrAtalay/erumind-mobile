import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/game/logic/game_controller.dart';
import '../data/continent_defs.dart';
import '../data/tiebreaker_questions.dart';
import 'map_game_state.dart';

final mapGameProvider =
    AsyncNotifierProvider<MapGameController, MapGameState>(MapGameController.new);

class MapGameController extends AsyncNotifier<MapGameState> {
  final _rng = Random();

  @override
  Future<MapGameState> build() async => MapGameState.initial();

  void restart() => state = AsyncData(MapGameState.initial());

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

    final aiTarget = _pickAiTarget(s);
    final question = await _fetchRandomQuestion();
    if (question == null) return;

    state = AsyncData(s.copyWith(
      playerTarget: continentId,
      aiTarget: aiTarget,
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

    final playerCorrect = result.isCorrect;
    final target = s.playerTarget!;
    final aiTarget = s.aiTarget;
    final contested = aiTarget == target;

    Map<String, Owner> ownership = Map.from(s.ownership);
    String msg;
    Owner? roundWinner;
    MapGamePhase nextPhase;

    if (playerCorrect) {
      if (contested) {
        // Both competing for same continent — does AI also answer correctly?
        if (_aiRolls()) {
          // Tiebreaker needed
          final tb = kTiebreakerQuestions[_rng.nextInt(kTiebreakerQuestions.length)];
          state = AsyncData(s.copyWith(
            tiebreaker: tb,
            lastCorrectIndex: result.correctIndex,
            lastPlayerChoice: selectedIndex,
            phase: MapGamePhase.tiebreakerQuestion,
            clearQuestion: false,
          ));
          return;
        } else {
          // AI wrong → player wins
          ownership[target] = Owner.player;
          roundWinner = Owner.player;
          msg = 'Rakip yanıldı — $target ele geçirildi!';
        }
      } else {
        // Uncontested: player wins their target
        ownership[target] = Owner.player;
        roundWinner = Owner.player;
        msg = 'Doğru! $target ele geçirildi.';
        // AI also resolves its own target
        ownership = _resolveAi(ownership, aiTarget);
      }
    } else {
      // Player wrong
      if (contested) {
        // AI auto-wins the contested continent
        ownership[target] = Owner.ai;
        roundWinner = Owner.ai;
        msg = 'Yanlış! Rakip $target\'ı ele geçirdi.';
      } else {
        msg = 'Yanlış! Tur geçildi.';
        ownership = _resolveAi(ownership, aiTarget);
      }
    }

    final gameWinner = _checkWin(ownership);
    nextPhase = gameWinner != null ? MapGamePhase.gameOver : MapGamePhase.result;

    state = AsyncData(s.copyWith(
      ownership: ownership,
      phase: nextPhase,
      lastCorrectIndex: result.correctIndex,
      lastPlayerChoice: selectedIndex,
      resultMessage: msg,
      roundWinner: roundWinner,
      winner: gameWinner,
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
    Map<String, Owner> ownership = Map.from(s.ownership);
    Owner? roundWinner;
    String msg;

    if (playerDist < aiDist) {
      ownership[target] = Owner.player;
      roundWinner = Owner.player;
      msg = '$target ele geçirildi! ($playerChoice ↔ $aiDist, doğru: $correct)';
    } else if (aiDist < playerDist) {
      ownership[target] = Owner.ai;
      roundWinner = Owner.ai;
      msg = 'Rakip kazandı! ($aiChoice ↔ $playerDist, doğru: $correct)';
    } else {
      msg = 'Beraberlik! ($playerChoice = $aiChoice, doğru: $correct) Sonraki turda tekrar!';
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

  // ── Phase: result → playerTurn ───────────────────────────────────────────

  void nextTurn() {
    final s = state.requireValue;
    if (s.phase != MapGamePhase.result) return;
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

  Map<String, Owner> _resolveAi(Map<String, Owner> ownership, String? aiTarget) {
    if (aiTarget == null) return ownership;
    final isPlayerTerritory = ownership[aiTarget] == Owner.player;
    final successRate = isPlayerTerritory ? 0.35 : 0.60;
    if (_rng.nextDouble() < successRate) {
      return Map.from(ownership)..[aiTarget] = Owner.ai;
    }
    return ownership;
  }

  bool _aiRolls({double rate = 0.55}) => _rng.nextDouble() < rate;

  Owner? _checkWin(Map<String, Owner> ownership) {
    final total = ownership.length;
    if (ownership.values.where((o) => o == Owner.player).length == total) return Owner.player;
    if (ownership.values.where((o) => o == Owner.ai).length == total) return Owner.ai;
    return null;
  }

  Future<dynamic> _fetchRandomQuestion() async {
    try {
      final all = await ref.read(questionRepositoryProvider).getQuestions();
      if (all.isEmpty) return null;
      return all[_rng.nextInt(all.length)];
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
