# CLAUDE.md — EruMind

Project context for Claude Code. Keep this updated as decisions are made.
Communicate with the team in **Turkish**; keep code, identifiers, comments, and docs in **English**.

---

## 1. Vision
**EruMind** is an original trivia/quiz game (category wheel, 4-option questions, crowns,
lives/energy) in the spirit of Trivia Crack. **Single-player first**, then **asynchronous
turn-based "duello" multiplayer**.

- **Original IP only.** Do NOT copy Trivia Crack / Erudite / Erudia text, characters, art,
  or branding. Placeholder dev content must be original too.
- Android first, iOS later. App id: `com.erumind.app`.

## 2. Team
- Two devs, strong general programming background, **new to Flutter and game dev**.
- Explain Flutter concepts as they are introduced.
- **Before any new dependency or large architectural change: propose options + trade-offs and
  wait for confirmation.** Work in small, reviewable steps.

## 3. Tech stack (decided + pinned this session)
- Flutter **3.44.2** (stable) / Dart **3.12.2**. VSCode.
- State: **Riverpod** (`flutter_riverpod ^3.3.2`, no codegen yet — manual providers).
- Routing: **go_router** `^17.3.0` (added; wired up in Phase 4).
- Models: **freezed** `^3.2.5` + **json_serializable** `^6.14.0`
  (`freezed_annotation ^3.1.0`, `json_annotation ^4.12.0`, `build_runner ^2.15.0`).
- Lint: `flutter_lints ^6.0.0` — keep `flutter analyze` clean.
- Tests: `flutter_test`. Prioritize unit tests for scoring & answer validation.
- **Deferred until needed (Phase 3):** local storage. Decision: use **`hive_ce`** (the
  maintained community fork) instead of the original `hive`. Not added yet.
- LATER (online): firebase_core/auth/firestore/functions/remote_config/crashlytics.
- LATER (money): google_mobile_ads, in_app_purchase. LATER (social): games_services.

> freezed 3.x requires `abstract class X with _$X` (not plain `class`).
> Riverpod 3.x: use `state.value` (nullable) — `valueOrNull` was removed.

## 4. Architecture (core principle)
**One mode-agnostic game core.** All question data sits behind the
**`QuestionRepository` interface** (`lib/data/repositories/question_repository.dart`):
- SP → `LocalQuestionRepository` (bundled `assets/questions.json`).
- MP → `FirestoreQuestionRepository` (later; **server-side answer validation**).

The game core depends only on the interface. Swapping SP↔MP is a one-line change in
`questionRepositoryProvider`. **Answer checking goes through `checkAnswer(...)`**, never by
reading `Question.correctIndex` directly — that's how MP stays un-cheatable (`correctIndex`
is null in MP, validated on the server).

### Folder structure (feature-first)
```
lib/
  main.dart            # ProviderScope + EruMindApp
  app.dart             # MaterialApp (go_router later)
  core/theme/          # AppTheme
  data/
    models/            # question, category, answer_result (+ .freezed/.g)
    repositories/      # question_repository (interface) + local_question_repository
    sources/           # local_question_source (reads assets/questions.json)
  features/
    game/
      logic/           # game_state, game_controller (Riverpod AsyncNotifier)
      presentation/    # game_screen
    menu/ settings/ duel/   # LATER
  services/            # storage, audio, firebase, ads (LATER)
```

## 5. Hard rules
1. **Server-authoritative answers in MP** (Cloud Functions). Never ship the correct answer
   to the client in a cheatable way. SP validates locally but through the same seam.
2. **Original content & branding only.**
3. **Build the core game loop (vertical slice) first**, before menus/settings.
4. **Committed to Flutter.** No engine switching.
5. **No secrets in the repo.** Firebase config/keys come later via proper config + .gitignore.

## 6. Roadmap & status
- **Phase 0 — Skeleton: DONE.** Models, repository interface + local impl, 15 original seed
  questions across 3 categories (science/history/geography).
- **Phase 1 — Vertical slice: DONE.** `GameScreen`: one question → 4 options → correct/wrong
  feedback → next → end-of-round score → play again. 10-question rounds, shuffled.
- Phase 2 — Wheel + 6 categories + crowns.
- Phase 3 — Lives/energy, scoring, local persistence (hive_ce), round summary.
- Phase 4 — Menu, settings (sound, TR/EN), go_router, audio, pause.
- Phase 5 — Polish/juice → SP MVP to Google Play closed testing.
- Phase 6 — Firebase foundation + server-side validation.
- Phase 7 — Async duello + leaderboard. Phase 8 — AdMob + IAP.

## 7. Coding conventions
- Riverpod for app state; avoid `setState` beyond trivial local state.
- Immutable domain models via freezed; JSON via json_serializable. Short-lived UI state may be
  a plain immutable class (see `GameState`).
- Small composable widgets; separate presentation from logic.
- Files snake_case, classes PascalCase.
- New feature flow: model → repository (if data) → controller → screen → test.
- Unit-test scoring and answer-checking from the start.

## 8. Dev workflow
- Daily dev on the Android emulator (`erumind_pixel`); validate on a real device regularly.
  (Google Play closed testing later requires real devices — emulators don't count.)
- Git from day 1, feature branches, small commits.
- **Two-person split:** Dev A owns game core + UI (`features/game`, `menu`, `settings`);
  Dev B owns data + services (`repositories`, `sources`, later Firebase/ads). The
  `QuestionRepository` interface is the contract between them.

## 9. Local environment (Windows — this machine)
- Flutter SDK: `C:\src\flutter` (on user PATH).
- Android SDK: `%LOCALAPPDATA%\Android\Sdk` (cmdline-tools installed; licenses accepted).
- JDK 17: Android Studio's bundled JBR. `JAVA_HOME` = `C:\Program Files\Android\Android Studio\jbr`.
- Emulator AVD: `erumind_pixel` (Pixel 7, Android 15 / API 35).
- System Java is 1.8 (too old) — always rely on `JAVA_HOME` (the JBR) for Gradle.

### Commands
```bash
flutter pub get
dart run build_runner build          # codegen (do NOT pass --delete-conflicting-outputs; removed in new build_runner)
dart run build_runner watch          # codegen on save
flutter analyze
flutter test
flutter run -d emulator-5554         # run on the emulator
flutter emulators --launch erumind_pixel
```
Run codegen after editing any freezed/json model.
