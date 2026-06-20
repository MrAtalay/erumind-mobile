# Duel mode — design draft (Phase 7)

**Status:** idea captured, NOT started. Belongs to Phase 7 (async duello +
leaderboard), which sits on top of Phase 6 (Firebase + server-side validation).
This is a living draft — refine before implementing.

> **Naming (important):** This duel "health" is a **different concept** from the
> single-player **lives/energy** (which gate *starting* a round). To avoid
> confusion, call the duel resource **HP / health** in code and UI, never "lives".

---

## Core idea (from the team, 2026-06-20)
- Each side starts a match with a health pool — proposal: **100 HP**.
- Both players face the **same set of questions**.
- A wrong answer costs HP.
- **Asymmetric damage:** if you miss a question **and your opponent got it
  right**, you lose *more* HP (you are punished harder for missing what they
  knew). If you miss but they also missed, the hit is smaller.
- The match ends when someone reaches 0 HP (or after a fixed number of
  questions — see open questions).

## Damage model (draft numbers — to tune)
Settle damage per shared question by comparing both answers:

| You | Opponent | You take |
|-----|----------|----------|
| correct | correct | 0 (or tiny chip damage) |
| correct | wrong   | 0 |
| wrong   | wrong   | base (e.g. 5) |
| wrong   | correct | base + bonus (e.g. 10–15) |

- Tune so 100 HP lasts a sensible match (~10–20 questions).
- Optional later: **speed factor** (a faster correct answer deals more damage),
  like Trivia Crack duels.

## Async flow (matches CLAUDE.md "asynchronous turn-based duello")
- Server holds the match: the shared question list + each player's answers + HP.
- Players answer on their own turn (not simultaneously).
- Damage for a question is **settled server-side once both players have answered
  it**, then HP is updated for both.
- Push/notification when it's your turn or the match resolves (later).

## Hard rules that apply
- **Server-authoritative answers (Hard rule #1):** `correctIndex` must NOT ship
  to clients in MP. Validation *and* damage settlement happen server-side
  (Cloud Functions). Clients only see results after settlement.
- Reuses the mode-agnostic game core via the `QuestionRepository` seam
  (`FirestoreQuestionRepository`).

## Open questions (need a team decision before building)
1. **End condition:** first to 0 HP, or fixed question count then lower-HP-loses
   (and both-alive → higher HP wins)?
2. **Exact damage numbers** (base / bonus / chip) and match length.
3. **Speed factor:** in v1 or deferred?
4. **Forfeit / timeout:** what happens if a player abandons a turn for too long?
5. **Leaderboard:** what's ranked — wins, win streak, total HP dealt?

## Not now
Phase 7 is far out. Current focus is Phase 3 finish → Phase 4 (menu/settings/
routing/audio). This doc just preserves the idea.
