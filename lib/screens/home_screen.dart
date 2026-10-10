import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/verses.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'prayer_flow.dart';
import 'streak_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _left(DateTime until) {
    final d = until.difference(DateTime.now());
    if (d.inMinutes >= 60) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes + 1}m';
  }

  String _time(BuildContext c, int mins) =>
      TimeOfDay(hour: mins ~/ 60, minute: mins % 60).format(c);

  void _pray(BuildContext c, String kind) => Navigator.push(
      c, MaterialPageRoute(builder: (_) => PrayerFlow(kind: kind)));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = verseOfDay();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning ☀️'
        : hour < 18
            ? 'Good afternoon 🌤️'
            : 'Good evening 🌙';
    final due = s.dueSession;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: h(26)),
                  Text('Walk with Jesus today.',
                      style: h(15, color: AppColors.soft, w: FontWeight.w500)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StreakScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.card, borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text('${s.streak}', style: h(20)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Prayer waiting now
        if (due != null)
          PastelCard(
            color: due == 'morning' ? AppColors.yellow : AppColors.blue,
            onTap: () => _pray(context, due),
            child: Row(children: [
              Pic(due == 'morning' ? 'sun' : 'moon', size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(due == 'morning' ? 'Morning prayer is waiting' : 'Night prayer is waiting',
                      style: h(20, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(
                      due == 'morning'
                          ? 'Start your day in His presence 🙏'
                          : 'Leave your worries with Him 💛',
                      style: h(14, color: AppColors.ink, w: FontWeight.w500)),
                ]),
              ),
              const ArrowDot(),
            ]),
          ),
        if (due != null) const SizedBox(height: 14),

        Row(children: [
          Expanded(child: _session(context, s, 'morning', 'Morning', 'sun', AppColors.yellow, s.morningMin)),
          const SizedBox(width: 12),
          Expanded(child: _session(context, s, 'night', 'Night', 'moon', AppColors.blue, s.nightMin)),
        ]),
        const SizedBox(height: 14),

        // Distractions
        PastelCard(
          color: s.isUnlocked ? AppColors.mint : AppColors.pink,
          onTap: () => _pray(context, 'gate'),
          child: Row(children: [
            Pic(s.isUnlocked ? 'unlock' : 'lock', size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.isUnlocked ? 'Your apps are open' : 'Your apps are locked',
                    style: h(20, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                    s.isUnlocked
                        ? 'Locks again in ${_left(s.unlockedUntil!)}'
                        : '${s.lockedApps.length} apps wait for your prayer',
                    style: h(14, color: AppColors.ink, w: FontWeight.w500)),
              ]),
            ),
            const ArrowDot(),
          ]),
        ),
        const SizedBox(height: 14),

        // Verse
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📖  VERSE OF THE DAY',
                    style: h(12, color: AppColors.yellow, w: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('"${v.text}"', style: serif(19)),
                const SizedBox(height: 10),
                Text(v.ref, style: const TextStyle(color: AppColors.soft)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _session(BuildContext c, AppState s, String kind, String label, String pic,
      Color color, int mins) {
    final done = s.doneToday(kind);
    return PastelCard(
      color: done ? color.withValues(alpha: 0.55) : color,
      onTap: () => _pray(c, kind),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Pic(pic, size: 46),
            const Spacer(),
            if (done) const Icon(Icons.check_circle, color: AppColors.ink),
          ]),
          const SizedBox(height: 10),
          Text('$label prayer', style: h(17, color: AppColors.ink)),
          Text(done ? 'Done today 🙌' : _time(c, mins),
              style: h(14, color: AppColors.ink, w: FontWeight.w500)),
        ],
      ),
    );
  }
}
