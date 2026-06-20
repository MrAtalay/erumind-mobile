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

  testWidgets('Settings is reachable from the menu', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const EruMindApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.textContaining('coming soon'), findsOneWidget);
  });
}
