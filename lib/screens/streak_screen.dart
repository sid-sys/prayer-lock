import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fire.dart';
import 'prayer_flow.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final today = DateTime.now();
    final week = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));
    final (target, left) = s.nextMilestone;
    final progress = target == 0 ? 0.0 : (s.streak / target).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text('Your streak', style: h(20))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: AnimatedFire(size: 120)),
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

          // week
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final d in week)
                    Column(children: [
                      Text(DateFormat.E().format(d).substring(0, 1),
                          style: h(13, color: AppColors.soft, w: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.prayedOn(d) ? AppColors.yellow : const Color(0xFFE8D2BC),
                        ),
                        child: s.prayedOn(d)
                            ? const Center(child: Text('🔥', style: TextStyle(fontSize: 18)))
                            : null,
                      ),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // next milestone
          PastelCard(
            color: AppColors.yellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next milestone: $target days 🎯', style: h(18, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('$left more ${left == 1 ? 'day' : 'days'} to go',
                    style: h(14, color: AppColors.ink, w: FontWeight.w500)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white54,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Badges 🏅', style: h(22)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              for (final b in s.badges)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: b.unlocked ? 1 : 0.25,
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
                        Text(b.title, textAlign: TextAlign.center, style: h(15)),
                        const SizedBox(height: 2),
                        Text(b.unlocked ? 'Unlocked 🎉' : b.how,
                            textAlign: TextAlign.center,
                            style: h(12, color: AppColors.soft, w: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrayerFlow(kind: 'gate'))),
            child: const Text('Pray now 🙏'),
          ),
        ],
      ),
    );
  }
}
