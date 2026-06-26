import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/game/logic/game_controller.dart';
import '../../../features/lives/logic/lives_controller.dart';
import '../../../features/mastery/logic/crowns.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/storage_service.dart';

// ── EruMind Red Palette ────────────────────────────────────────────────────
const _bgTop    = Color(0xFF7A0020);
const _bgBot    = Color(0xFF2A0008);
const _red      = Color(0xFFCC1020);
const _redLight = Color(0xFFFF3040);

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final bestScore = storage.bestScore;
    final threshold = ref.watch(crownThresholdProvider);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final crownsEarned =
        categories.where((c) => storage.masteryFor(c.id) >= threshold).length;
    final livesState = ref.watch(livesControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBot],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar
              _TopBar(
                bestScore: bestScore,
                lives: livesState.lives,
                maxLives: livesState.max,
              ),

              const Spacer(flex: 1),

              // ── Logo
              const _Logo(),

              const Spacer(flex: 2),

              // ── Mode cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        label: l10n.menuSinglePlayer,
                        icons: const [
                          Icons.science_rounded,
                          Icons.history_edu_rounded,
                          Icons.public_rounded,
                          Icons.emoji_events_rounded,
                          Icons.palette_rounded,
                          Icons.movie_rounded,
                        ],
                        colors: const [
                          Color(0xFF1976D2), // Bilim
                          Color(0xFFF9A825), // Tarih
                          Color(0xFF388E3C), // Coğrafya
                          Color(0xFF0097A7), // Spor
                          Color(0xFF7B1FA2), // Sanat
                          Color(0xFFC2185B), // Eğlence
                        ],
                        onTap: () => context.push('/game'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ModeCard(
                        label: l10n.menuMultiplayer,
                        icons: const [
                          Icons.science_rounded,
                          Icons.history_edu_rounded,
                          Icons.public_rounded,
                          Icons.emoji_events_rounded,
                          Icons.palette_rounded,
                          Icons.movie_rounded,
                        ],
                        colors: const [
                          Color(0xFF1976D2),
                          Color(0xFFF9A825),
                          Color(0xFF388E3C),
                          Color(0xFF0097A7),
                          Color(0xFF7B1FA2),
                          Color(0xFFC2185B),
                        ],
                        onTap: null,
                        locked: true,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Bottom bar
              _BottomBar(
                crownsEarned: crownsEarned,
                total: categories.length,
                onSettings: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.bestScore,
    required this.lives,
    required this.maxLives,
  });

  final int bestScore;
  final int lives;
  final int maxLives;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Player chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _red,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.menuPlayer,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      AppLocalizations.of(context)!.bestPoints(bestScore),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Hearts
          Row(
            children: [
              Icon(Icons.favorite_rounded,
                  color: _redLight, size: 18),
              const SizedBox(width: 4),
              Text(
                '$lives/$maxLives',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Logo ───────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6060), Color(0xFFFF2020)],
          ).createShader(bounds),
          child: const Text(
            'ERU',
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFDDDDDD)],
          ).createShader(bounds),
          child: const Text(
            'MİND',
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AppLocalizations.of(context)!.menuTagline,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mode card ──────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.label,
    required this.icons,
    required this.colors,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final List<IconData> icons;
  final List<Color> colors;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Card thumbnail
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(locked ? 15 : 25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha(locked ? 20 : 50),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // 3×2 icon grid (6 categories), vertically centred
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          for (int i = 0; i < icons.length; i++)
                            Container(
                              decoration: BoxDecoration(
                                color: colors[i].withAlpha(locked ? 50 : 200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icons[i],
                                color: Colors.white
                                    .withAlpha(locked ? 100 : 255),
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Lock overlay
                  if (locked)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.menuComingSoon,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: locked ? Colors.white38 : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.crownsEarned,
    required this.total,
    required this.onSettings,
  });

  final int crownsEarned;
  final int total;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Trophy / crowns
          GestureDetector(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.white60, size: 28),
                const SizedBox(height: 2),
                Text(
                  '$crownsEarned/$total',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          // Settings
          GestureDetector(
            onTap: onSettings,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_rounded,
                    color: Colors.white60, size: 28),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.settings,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
