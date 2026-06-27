import '../../../data/models/question.dart';

enum Owner { neutral, player, ai }

/// The two stages of a match (Bil ve Fethet v2):
/// - [expansion]: the map has empty land; players claim neutral regions.
/// - [war]: the map is full; players take each other's regions (world conquest).
enum MatchPhase { expansion, war }

enum MapGamePhase {
  playerTurn,     // player picks a region (expansion: empty / war: enemy)
  playerQuestion, // question is being shown
  result,         // player's move resolved — shown over the map
  aiTurn,         // rival is acting (target highlighted on the map)
  aiResult,       // rival's move resolved — shown over the map
  gameOver,
}

class MapGameState {
  final Map<String, Owner> ownership;
  final MapGamePhase phase;

  /// The single quiz category this whole match draws questions from.
  final String categoryId;

  final String? playerTarget;
  final String? aiTarget;
  final Question? currentQuestion;
  final String? resultMessage;
  final Owner? roundWinner;
  final Owner? winner;

  const MapGameState({
    required this.ownership,
    required this.phase,
    required this.categoryId,
    this.playerTarget,
    this.aiTarget,
    this.currentQuestion,
    this.resultMessage,
    this.roundWinner,
    this.winner,
  });

  factory MapGameState.initial({String categoryId = 'mixed'}) {
    const ids = [
      'north_america', 'south_america', 'europe',
      'africa', 'asia', 'australia', 'antarctica',
    ];
    return MapGameState(
      ownership: {for (final id in ids) id: Owner.neutral},
      phase: MapGamePhase.playerTurn,
      categoryId: categoryId,
    );
  }

  /// Expansion while any land is still neutral; war once the map is full.
  MatchPhase get matchPhase =>
      ownership.values.any((o) => o == Owner.neutral)
          ? MatchPhase.expansion
          : MatchPhase.war;

  List<String> get playerContinents => ownership.entries
      .where((e) => e.value == Owner.player)
      .map((e) => e.key)
      .toList();

  List<String> get aiContinents => ownership.entries
      .where((e) => e.value == Owner.ai)
      .map((e) => e.key)
      .toList();

  int get neutralCount =>
      ownership.values.where((o) => o == Owner.neutral).length;

  int get playerCount => playerContinents.length;
  int get aiCount => aiContinents.length;

  MapGameState copyWith({
    Map<String, Owner>? ownership,
    MapGamePhase? phase,
    String? categoryId,
    String? playerTarget,
    String? aiTarget,
    Question? currentQuestion,
    String? resultMessage,
    Owner? roundWinner,
    Owner? winner,
    bool clearPlayerTarget = false,
    bool clearAiTarget = false,
    bool clearQuestion = false,
    bool clearResult = false,
    bool clearRoundWinner = false,
  }) {
    return MapGameState(
      ownership: ownership ?? this.ownership,
      phase: phase ?? this.phase,
      categoryId: categoryId ?? this.categoryId,
      playerTarget: clearPlayerTarget ? null : (playerTarget ?? this.playerTarget),
      aiTarget: clearAiTarget ? null : (aiTarget ?? this.aiTarget),
      currentQuestion: clearQuestion ? null : (currentQuestion ?? this.currentQuestion),
      resultMessage: clearResult ? null : (resultMessage ?? this.resultMessage),
      roundWinner: clearRoundWinner ? null : (roundWinner ?? this.roundWinner),
      winner: winner ?? this.winner,
    );
  }
}
