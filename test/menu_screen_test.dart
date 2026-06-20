import 'package:flutter/material.dart';

import 'package:erumind/app.dart';
import 'package:erumind/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_storage.dart';

void main() {
  late StorageService storage;
  setUp(() async {
    storage = await setUpTempStorage();
  });

  testWidgets('menu opens first and Play navigates to the game lobby',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const EruMindApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The app opens on the menu.
    expect(find.text('EruMind'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    // Navigated into the game, which shows the lives-gated lobby.
    expect(find.text('Ready to play?'), findsOneWidget);
  });

  testWidgets('Settings shows the language options', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const EruMindApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
  });

  testWidgets('switching to Turkish relocalizes the UI', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const EruMindApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();

    // The settings screen itself relocalizes.
    expect(find.text('Ayarlar'), findsOneWidget);

    // Back on the menu, the buttons are Turkish too. (Use BackButton directly:
    // pageBack() looks up the English "Back" tooltip, which is now localized.)
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Oyna'), findsOneWidget);
  });
}
