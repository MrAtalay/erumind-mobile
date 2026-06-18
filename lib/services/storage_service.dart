import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Local persistence entry point (Phase 3 prep).
///
/// No boxes are opened and no data is read or written yet — this only sets
/// up the Hive CE runtime so the storage schema (lives/energy, settings,
/// round history) can be designed and wired in separately.
class StorageService {
  Future<void> init() => Hive.initFlutter();

  Future<void> close() => Hive.close();
}
