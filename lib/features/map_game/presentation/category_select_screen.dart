import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logic/map_game_controller.dart';

/// Lobby-lite: pick the single category the whole Bil ve Fethet match will draw
/// its questions from, then start the match. (Portrait; the match itself is
/// landscape.)
class CategorySelectScreen extends ConsumerWidget {
  const CategorySelectScreen({super.key});

  static const _categories = <_Cat>[
    _Cat('mixed', 'Karışık', Icons.shuffle_rounded, Color(0xFFB07A2E)),
    _Cat('science', 'Bilim', Icons.science_rounded, Color(0xFF1976D2)),
    _Cat('history', 'Tarih', Icons.history_edu_rounded, Color(0xFFF9A825)),
    _Cat('geography', 'Coğrafya', Icons.public_rounded, Color(0xFF388E3C)),
    _Cat('sports', 'Spor', Icons.sports_soccer_rounded, Color(0xFF0097A7)),
    _Cat('art', 'Sanat', Icons.palette_rounded, Color(0xFF7B1FA2)),
    _Cat('entertainment', 'Eğlence', Icons.movie_rounded, Color(0xFFC2185B)),
  ];

  void _start(BuildContext context, WidgetRef ref, String id) {
    ref.read(pendingMatchCategoryProvider.notifier).state = id;
    context.push('/map-game');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 6, 24, 18),
                child: Text(
                  'Kategori seç — bu maçın tüm soruları o kategoriden gelir.',
                  style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.3),
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.5,
                  children: [
                    for (final c in _categories)
                      _CategoryCard(cat: c, onTap: () => _start(context, ref, c.id)),
                  ],
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cat.color.withValues(alpha: 0.55), width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(14)),
                child: Icon(cat.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(cat.label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
