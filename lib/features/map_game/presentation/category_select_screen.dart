import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logic/map_game_controller.dart';

/// Lobby-lite: pick the single category the whole Bil ve Fethet match will draw
/// its questions from, then start the match.
///
/// This screen owns the landscape lock for the *whole* Bil ve Fethet flow:
/// it goes landscape on enter and restores portrait on exit, so the player
/// rotates once entering the mode (not mid-flow at match start) and the map
/// screen can stay landscape when popped back to.
class CategorySelectScreen extends ConsumerStatefulWidget {
  const CategorySelectScreen({super.key});

  @override
  ConsumerState<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends ConsumerState<CategorySelectScreen> {
  static const _categories = <_Cat>[
    _Cat('mixed', 'Karışık', Icons.shuffle_rounded, Color(0xFFB07A2E)),
    _Cat('science', 'Bilim', Icons.science_rounded, Color(0xFF1976D2)),
    _Cat('history', 'Tarih', Icons.history_edu_rounded, Color(0xFFF9A825)),
    _Cat('geography', 'Coğrafya', Icons.public_rounded, Color(0xFF388E3C)),
    _Cat('sports', 'Spor', Icons.sports_soccer_rounded, Color(0xFF0097A7)),
    _Cat('art', 'Sanat', Icons.palette_rounded, Color(0xFF7B1FA2)),
    _Cat('entertainment', 'Eğlence', Icons.movie_rounded, Color(0xFFC2185B)),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Leaving the Bil ve Fethet mode → back to the portrait app.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _start(String id) {
    ref.read(pendingMatchCategoryProvider.notifier).state = id;
    context.push('/map-game');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7A0020), Color(0xFF2A0008)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    const Text('Bil ve Fethet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Kategori seç — tüm sorular o kategoriden gelir.',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 700 ? 4 : 2;
                    return GridView.count(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        for (final c in _categories)
                          _CategoryCard(cat: c, onTap: () => _start(c.id)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cat {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.id, this.label, this.icon, this.color);
}

class _CategoryCard extends StatelessWidget {
  final _Cat cat;
  final VoidCallback onTap;
  const _CategoryCard({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cat.color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cat.color.withValues(alpha: 0.55), width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(12)),
                child: Icon(cat.icon, color: Colors.white, size: 25),
              ),
              const SizedBox(height: 8),
              Text(cat.label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
