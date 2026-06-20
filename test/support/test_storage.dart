import 'package:erumind/services/storage_service.dart';

/// A fresh, empty [StorageService] for tests, backed by memory (no file I/O).
///
/// Returns a Future to keep call sites uniform with how production storage is
/// created; the in-memory instance is ready immediately.
Future<StorageService> setUpTempStorage() async => InMemoryStorageService();
