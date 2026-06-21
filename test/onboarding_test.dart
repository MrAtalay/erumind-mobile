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

  Widget app() => ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const EruMindApp(),
      );

  testWidgets('first launch shows onboarding before the menu',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Spin the wheel'), findsOneWidget);
    expect(find.text('EruMind'), findsNothing);
  });

  testWidgets('paging through and finishing reveals the menu and persists',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Answer to grow your pot'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Bank it or risk it'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('EruMind'), findsOneWidget);
    expect(storage.hasSeenOnboarding, isTrue);
  });

  testWidgets('skip jumps straight to the menu and persists', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('EruMind'), findsOneWidget);
    expect(storage.hasSeenOnboarding, isTrue);
  });

  testWidgets('onboarding is skipped on a later launch', (tester) async {
    await storage.saveOnboardingSeen(true);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('EruMind'), findsOneWidget);
    expect(find.text('Spin the wheel'), findsNothing);
  });
}
