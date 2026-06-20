# Lessons & Pitfalls — EruMind

A living log of mistakes that cost real time, with the root cause and a concrete
prevention. Read this before tackling persistence, services, or widget tests.
Add a new entry whenever something burns more than ~15 minutes.

---

## L1 — Put persistence/services behind an interface from the start

**What happened (2026-06-20):** `StorageService` was first written as a single
concrete class wrapping a Hive box. The game core depended on it directly. When
widget tests touched it, everything fell apart (see L2). Fixing it meant
retrofitting an interface mid-task.

**Root cause:** Didn't follow the pattern the codebase already establishes with
`QuestionRepository` — a mode-agnostic interface with swappable backends.

**Prevention:**
- Any new persistence or service (storage, audio, firebase, ads, …) gets an
  **interface** + a production impl + an in-memory/fake impl, from the first
  commit. The app core depends only on the interface.
- Production = real backend (`HiveStorageService`). Tests = `InMemoryStorageService`
  (a `Map`, no I/O).
- This is the same seam idea as `questionRepositoryProvider`. Swapping is a
  one-line provider override.

**Quick check before writing a class:** "Will the game core depend on this? Will
a test need to fake it?" If yes → interface first.

---

## L2 — Real I/O makes `testWidgets` hang for 10 minutes

**What happened:** Widget tests hung and only failed after the default
**10-minute** `pumpAndSettle` timeout — twice (~20 min of pure waiting).

**Root cause:** `testWidgets` runs the body in a **fake-async zone** where
`Timer` is virtualized but **real I/O is not pumped**. A `Future` from real file
I/O (Hive `openBox`/`put`, anything in `dart:io`) **never completes** inside that
zone, so:
- `await setUpTempStorage()` (which did `Hive.openBox`) hung *before* `pumpWidget`.
- `pumpAndSettle` waited forever for an in-flight write to settle.

**Prevention (in order of preference):**
1. **Use an in-memory test double** so writes complete on a *microtask*
   (`pump`/`pumpAndSettle` drain microtasks normally). This is why L1 matters.
2. If you must hit real I/O, open it in **`setUp()`** (runs outside the fake-async
   zone), not in the test body.
3. For real-I/O *during* a test, wrap the trigger in **`await tester.runAsync(...)`**.

**Quick check:** A widget test that hangs with no error = pending real-I/O Future
**or** an infinite animation/timer (see L3). Suspect these first.

---

## L3 — Indeterminate animations & periodic timers also hang `pumpAndSettle`

**Root cause:** `pumpAndSettle` pumps until no frame is scheduled. An indeterminate
`CircularProgressIndicator`, or a `Stream.periodic` / ticker, schedules frames or
timers **forever** → it never settles.

**Prevention:**
- Don't `pumpAndSettle` while a progress spinner or ticker is on screen; use a
  bounded `pump(Duration(...))` a fixed number of times.
- Keep tickers `autoDispose` and only active when actually needed (e.g. our
  `tickerProvider` only runs while the lobby shows an out-of-lives countdown).

---

## L4 — Diagnose hangs fast; never sit through the 10-minute timeout

**What happened:** Let the full suite run to the 10-min timeout instead of
localizing the hang.

**Prevention:**
- Run **one test file** while iterating: `flutter test test/foo_test.dart`. Run
  the full suite only at the end.
- To localize a hang, temporarily replace `pumpAndSettle()` with a couple of
  `pump()` calls, or add a tiny "probe" test that only renders + asserts. If the
  probe passes, the hang is in `pumpAndSettle` waiting on a timer/animation/I/O.
- Note: a fully blocked fake-async zone can't fire its own `--timeout`, so
  `--timeout 30s` may not help once it's already wedged — prevent the wedge with
  `pump()` probes instead.

---

## L5 — Don't reuse log filenames across concurrent/background runs

**What happened:** Multiple background test runs wrote the same `build/*.log`;
output interleaved and produced a *stale test name* in the results, which sent the
diagnosis down a wrong path.

**Prevention:**
- Unique log file per run (or just run in the foreground for short commands).
- Beware `cmd | tail`: the pipe reports **tail's** exit code (always 0) and
  buffers until the process ends — it hides both failures and progress. Redirect
  to a file and read that instead.
- When backgrounding, wait on an explicit `echo "EXIT=$?"` marker, not on partial
  output.
