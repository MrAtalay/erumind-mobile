import '../../../data/models/question.dart';
import '../data/tiebreaker_questions.dart';

enum Owner { neutral, player, ai }

enum MapGamePhase {
  selectStart,        // player picks starting continent
  playerTurn,         // player picks a continent to attack
  playerQuestion,     // MC question is being shown
  tiebreakerQuestion, // numeric tiebreaker (both answered correctly)
  result,             // player's move resolved — shown over the map
  aiTurn,             // rival is attacking (target highlighted on the map)
  aiResult,           // rival's move resolved — shown over the map
  gameOver,
}

class MapGameState {
  final Map<String, Owner> ownership;
  final MapGamePhase phase;
  final String? playerTarget;
  final String? aiTarget;
  final Question? currentQuestion;
  final int? lastCorrectIndex;       // correct answer index from last MC question
  final int? lastPlayerChoice;       // player's MC choice
  final TiebreakerQuestion? tiebreaker;
  final String? resultMessage;
  final Owner? roundWinner;          // who won this round's combat (null = draw/skip)
  final Owner? winner;               // overall game winner

  const MapGameState({
    required this.ownership,
    required this.phase,
    this.playerTarget,
    this.aiTarget,
    this.currentQuestion,
    this.lastCorrectIndex,
    this.lastPlayerChoice,
    this.tiebreaker,
    this.resultMessage,
    this.roundWinner,
    this.winner,
  });

  factory MapGameState.initial() {
    const ids = [
      'north_america', 'south_america', 'europe',
      'africa', 'asia', 'australia', 'antarctica',
    ];
    return MapGameState(
      ownership: {for (final id in ids) id: Owner.neutral},
      phase: MapGamePhase.selectStart,
    );
  }

  List<String> get playerContinents => ownership.entries
      .where((e) => e.value == Owner.player)
      .map((e) => e.key)
      .toList();

  List<String> get aiContinents => ownership.entries
      .where((e) => e.value == Owner.ai)
      .map((e) => e.key)
      .toList();

  int get playerCount => playerContinents.length;
  int get aiCount => aiContinents.length;

  MapGameState copyWith({
    Map<String, Owner>? ownership,
    MapGamePhase? phase,
    String? playerTarget,
    String? aiTarget,
    Question? currentQuestion,
    int? lastCorrectIndex,
    int? lastPlayerChoice,
    TiebreakerQuestion? tiebreaker,
    String? resultMessage,
    Owner? roundWinner,
    Owner? winner,
    bool clearPlayerTarget = false,
    bool clearAiTarget = false,
    bool clearQuestion = false,
    bool clearTiebreaker = false,
    bool clearResult = false,
    bool clearRoundWinner = false,
  }) {
    return MapGameState(
      ownership: ownership ?? this.ownership,
      phase: phase ?? this.phase,
      playerTarget: clearPlayerTarget ? null : (playerTarget ?? this.playerTarget),
      aiTarget: clearAiTarget ? null : (aiTarget ?? this.aiTarget),
      currentQuestion: clearQuestion ? null : (currentQuestion ?? this.currentQuestion),
      lastCorrectIndex: clearQuestion ? null : (lastCorrectIndex ?? this.lastCorrectIndex),
      lastPlayerChoice: clearQuestion ? null : (lastPlayerChoice ?? this.lastPlayerChoice),
      tiebreaker: clearTiebreaker ? null : (tiebreaker ?? this.tiebreaker),
      resultMessage: clearResult ? null : (resultMessage ?? this.resultMessage),
      roundWinner: clearRoundWinner ? null : (roundWinner ?? this.roundWinner),
      winner: winner ?? this.winner,
    );
  }
}
