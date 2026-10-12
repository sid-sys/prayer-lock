import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fire.dart';
import '../widgets/streak_cards.dart';
import 'prayer_flow.dart';

class StreakScreen extends StatelessWidget {
  /// Start scrolled down by this much (used by screenshot mode).
  final double? scrollTo;
  const StreakScreen({super.key, this.scrollTo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // Earned badges first, then the ones still to earn.
    final all = s.badges;
    final badges = [...all.where((b) => b.unlocked), ...all.where((b) => !b.unlocked)];
    final earned = all.where((b) => b.unlocked).length;

    return Scaffold(
      appBar: AppBar(title: Text('Your streak', style: h(20))),
      body: SafeArea(
        top: false,
        child: ListView(
          controller: scrollTo == null ? null : ScrollController(initialScrollOffset: scrollTo!),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const Center(child: AnimatedFire(size: 110)),
            const SizedBox(height: 4),
            Center(child: Text('${s.streak}', style: h(72))),
            Center(
              child: Text(s.streak == 1 ? 'day in a row' : 'days in a row',
                  style: h(18, color: AppColors.soft, w: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('One prayer at a time. Keep growing closer to Him 🙏',
                  textAlign: TextAlign.center,
                  style: h(14, color: AppColors.soft, w: FontWeight.w500)),
            ),
            const SizedBox(height: 24),
            StreakWeekCard(s),
            const SizedBox(height: 14),
            MilestoneCard(s),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Badges 🏅', style: h(22)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
                  child: Text('$earned / ${all.length}',
                      style: h(14, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 222,
              ),
              children: [for (final b in badges) _BadgeCard(b)],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrayerFlow(kind: 'gate'))),
              child: const Text('Pray now 🙏'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final PrayerBadge b;
  const _BadgeCard(this.b);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Opacity(
              opacity: b.unlocked ? 1 : 0.28,
              child: ColorFiltered(
                colorFilter: b.unlocked
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(<double>[
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                child: Pic(b.image, size: 84),
              ),
            ),
            const SizedBox(height: 8),
            Text(b.title, textAlign: TextAlign.center, style: h(15), maxLines: 2),
            const SizedBox(height: 3),
            Text(
              b.unlocked ? b.quip : '🔒 ${b.how}',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: h(12,
                  color: b.unlocked ? AppColors.ink : AppColors.soft, w: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
