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
- Audio: `audioplayers ^6.1.0` (Phase 5 audio slice). SFX assets at `assets/audio/*.wav`
  are placeholder silence — drop real clips in with the same filenames, no code change.
- App icon/splash: `flutter_launcher_icons ^0.14.3` + `flutter_native_splash ^2.4.6`
  (dev-only, Phase 5). Source logo at `assets/icon/icon.png`. After replacing the logo,
  re-run `dart run flutter_launcher_icons` then `dart run flutter_native_splash:create`.
- Online foundation (Phase 6, first slice): `firebase_core ^4.11.0` + `cloud_firestore
  ^6.6.0`. Firebase project **`erumind-app`** (console: console.firebase.google.com/project/erumind-app).
  Android app registered via `flutterfire configure`; `lib/firebase_options.dart` and
  `android/app/google-services.json` are committed — these are client config, not secrets
  (protected by Firestore rules, not by hiding them). `firebase.json` / `.firebaserc` /
  `firestore.rules` / `firestore.indexes.json` added at the repo root.
  `Firebase.initializeApp()` runs in `main()` but nothing reads from Firestore yet.
- LATER (online, continued): auth/functions/remote_config/crashlytics.
- LATER (money): google_mobile_ads, in_app_purchase. LATER (social): games_services.

> freezed 3.x requires `abstract class X with _$X` (not plain `class`).
> Riverpod 3.x: use `state.value` (nullable) — `valueOrNull` was removed.

## 4. Architecture (core principle)
**One mode-agnostic game core.** All question data sits behind the
**`QuestionRepository` interface** (`lib/data/repositories/question_repository.dart`):
- SP → `LocalQuestionRepository` (bundled `assets/questions.json`).
- MP → `FirestoreQuestionRepository` (`lib/data/repositories/firestore_question_repository.dart`,
  added Phase 6 — reads `categories`/`questions` collections, **not wired into
  `questionRepositoryProvider` yet**. `checkAnswer` deliberately throws
  `UnimplementedError`: the Cloud Function that validates MP answers server-side hasn't
  been built, and Firestore questions never carry `correctIndex` in the first place).

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
5. **No secrets in the repo.** `firebase_options.dart` / `google-services.json` are client
   config (not secrets) and are committed by design — protected by Firestore rules, not by
   hiding them. Actual secrets (service account keys, Functions env vars) still never go in
   the repo.

## 6. Roadmap & status
- **Phase 0 — Skeleton: DONE.** Models, repository interface + local impl, 15 original seed
  questions across 3 categories (science/history/geography).
- **Phase 1 — Vertical slice: DONE.** `GameScreen`: one question → 4 options → correct/wrong
  feedback → next → end-of-round score → play again. 10-question rounds, shuffled.
- Phase 2 — Wheel + 6 categories + crowns.
- Phase 3 — Lives/energy, scoring, local persistence (hive_ce), round summary.
- Phase 4 — Menu, settings (sound, TR/EN), go_router, audio, pause.
- **Phase 5 — Polish/juice: DONE** → next up is the SP MVP submission to Google Play closed
  testing. Shipped this phase:
  - Countdown timer per question.
  - Sound effects (correct/wrong/spin/crown) wired up with a settings toggle; placeholder
    SFX assets at `assets/audio/*.wav` pending real audio (drop in same filenames).
  - App icon + native splash (logo at `assets/icon/icon.png`, generated via
    `flutter_launcher_icons` / `flutter_native_splash`), verified on the Android emulator.
  - First-launch onboarding (3-page walkthrough of the Momentum loop), gating the '/' route
    until completed or skipped (`onboardingSeenProvider`, `StorageService.hasSeenOnboarding`).
  - **Lives reworked from a per-run cost to a per-mistake cost (2026-06-21 decision):** a
    wrong answer (or timeout) no longer ends the session — it costs one life, resets the
    streak multiplier, but leaves the pot and banked total untouched, and the player taps
    "Continue" to keep going. The session only ends (banking what's left) once lives hit 0,
    or the player voluntarily taps "Finish"/"See results". `GameController.start()` no longer
    spends a life; `answer()`/`timeUp()` do, via `livesControllerProvider.notifier.consumeLife()`.
    Note: the lives gate (and thus this cost) is disabled in debug builds (`kReleaseMode`
    check in `livesEnabledProvider`) — test the heart count on a release build or with
    `livesEnabledProvider` overridden, not a debug run.
- **Phase 6 — Firebase foundation + server-side validation: IN PROGRESS.** First slice done
  (2026-06-22): Firebase project `erumind-app` created, Android app registered via
  `flutterfire configure`, `firebase_core` + `cloud_firestore` added, `Firebase.initializeApp()`
  runs in `main()`. Firestore database created (region `eur3`) with rules deployed
  (`categories`/`questions` public-read/no-write, everything else denied).
  `FirestoreQuestionRepository` added but **not wired in** — `questionRepositoryProvider`
  still points at `LocalQuestionRepository`. Still open: seed real category/question data
  into Firestore (without `correctIndex` — that must live server-side once Functions exist),
  Cloud Function for server-side `checkAnswer`, Auth, switch the provider over.
- Phase 7 — Async duello + leaderboard. Phase 8 — AdMob + IAP.

## 6b. Lessons & pitfalls (read before persistence/services/widget tests)
See **`docs/lessons-and-pitfalls.md`** for the full log. The expensive ones so far:
- **New persistence/service → interface + in-memory fake from the start** (same
  seam as `QuestionRepository`). The game core depends only on the interface.
- **Never let real I/O reach a `testWidgets` body** — the fake-async zone never
  completes real-I/O Futures, so `pumpAndSettle` hangs to a 10-min timeout. Use an
  in-memory test double; or open I/O in `setUp()`; or wrap it in `tester.runAsync`.
- **Indeterminate spinners / `Stream.periodic` tickers also hang `pumpAndSettle`**
  — use bounded `pump(Duration)` instead, and keep tickers `autoDispose`.
- **Localize hangs with a single test file + `pump()` probes;** don't sit through
  the 10-min timeout. Don't reuse log filenames across concurrent runs.

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
- Firebase CLI (`npm i -g firebase-tools`) + FlutterFire CLI (`dart pub global activate
  flutterfire_cli`) installed (2026-06-22) for the Phase 6 setup. Logged in as
  umutefe.demir37@gmail.com via `firebase login` (needs a real interactive terminal —
  fails in non-TTY contexts; run it yourself if the login expires).

### Commands
```bash
flutter pub get
dart run build_runner build          # codegen (do NOT pass --delete-conflicting-outputs; removed in new build_runner)
dart run build_runner watch          # codegen on save
flutter analyze
flutter test
flutter run -d emulator-5554         # run on the emulator
flutter emulators --launch erumind_pixel
firebase deploy --only firestore:rules   # after editing firestore.rules
flutterfire configure                     # re-run after adding a new platform (iOS, etc.)
```
Run codegen after editing any freezed/json model.
