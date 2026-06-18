/// Coarse difficulty rating for a [Question].
///
/// Pure metadata for now (filtering/scoring weight comes later) — adding it
/// here keeps the schema future-proof without touching the game core yet.
enum QuestionDifficulty {
  easy,
  medium,
  hard,
}
