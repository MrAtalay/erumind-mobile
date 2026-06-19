import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  // Needed because we touch platform channels (Hive's path) before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Open local storage once, up front, then inject the ready instance so the
  // rest of the app can read it synchronously through Riverpod.
  final storage = await StorageService.init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const EruMindApp(),
    ),
  );
}
