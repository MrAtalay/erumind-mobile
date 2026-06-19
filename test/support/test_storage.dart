import 'dart:io';

import 'package:erumind/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Opens a fresh stats box in a temporary Hive directory and returns a
/// [StorageService] over it. Registers teardown to close Hive and delete the
/// directory, so each test starts from an empty store.
///
/// Uses `Hive.init(path)` (pure-Dart) rather than `initFlutter`, so it works in
/// plain unit tests without platform channels.
Future<StorageService> setUpTempStorage() async {
  final dir = await Directory.systemTemp.createTemp('erumind_test');
  Hive.init(dir.path);
  final box = await Hive.openBox(StorageService.boxName);
  addTearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  return StorageService.fromBox(box);
}
