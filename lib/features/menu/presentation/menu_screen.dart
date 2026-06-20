import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/game/logic/game_controller.dart';
import '../../../features/mastery/logic/crowns.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final storage = ref.watch(storageServiceProvider);
    final bestScore = storage.bestScore;

    // Crowns earned so far (rebuilt on every return to the menu).
    final threshold = ref.watch(crownThresholdProvider);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final crownsEarned =
        categories.where((c) => storage.masteryFor(c.id) >= threshold).length;

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
                  bestScore > 0 ? l10n.bestPoints(bestScore) : l10n.menuNoGames,
                  style: theme.textTheme.titleMedium,
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events,
                          size: 20,
                          color: crownsEarned > 0
                              ? Colors.amber.shade700
                              : theme.disabledColor),
                      const SizedBox(width: 6),
                      Text(l10n.crownsProgress(crownsEarned, categories.length),
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                ],
                const SizedBox(height: 48),
                FilledButton(
                  onPressed: () => context.push('/game'),
                  child: Text(l10n.play),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/settings'),
                  child: Text(l10n.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
