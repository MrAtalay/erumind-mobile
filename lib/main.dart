import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  // Needed because we touch platform channels (Hive's path) before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // The app is portrait-first; only the map game (Bil ve Fethet) flips to
  // landscape, then restores portrait on exit. Locking here keeps every other
  // screen upright regardless of the device's physical rotation.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase foundation (Phase 6): connects the app to the erumind-app
  // project. Nothing reads from Firestore yet — FirestoreQuestionRepository
  // isn't wired into questionRepositoryProvider until MP lands.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Anonymous auth gives every device a stable Firebase UID (needed by the
  // checkAnswer Cloud Function, and later by duello/leaderboard) without a
  // sign-in screen. Skipped if a session already exists.
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // Open local storage once, up front, then inject the ready instance so the
  // rest of the app can read it synchronously through Riverpod.
  final storage = await HiveStorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        audioServiceProvider.overrideWith(createAudioService),
      ],
      child: const EruMindApp(),
    ),
  );
}
