import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  // Needed because we touch platform channels (Hive's path) before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase foundation (Phase 6, first slice): connects the app to the
  // erumind-app project. Nothing reads from it yet — FirestoreQuestionRepository
  // isn't wired into questionRepositoryProvider until MP lands.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
