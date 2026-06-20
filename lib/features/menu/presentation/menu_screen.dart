import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/storage_service.dart';

/// App home: title, best score, and entry points into the game and settings.
///
/// The lives-gated lobby lives inside [GameScreen]; this menu just navigates
/// there. Rebuilt on every return (pop), so the best score stays current.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bestScore = ref.watch(storageServiceProvider).bestScore;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('EruMind', style: theme.textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  bestScore > 0 ? 'Best: $bestScore points' : 'No games yet',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 48),
                FilledButton(
                  onPressed: () => context.push('/game'),
                  child: const Text('Play'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/settings'),
                  child: const Text('Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
