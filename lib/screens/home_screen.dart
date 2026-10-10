import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/verses.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'prayer_flow.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _left(DateTime until) {
    final d = until.difference(DateTime.now());
    if (d.inMinutes >= 60) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes + 1}m';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = verseOfDay();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: Text('Prayer Lock', style: serif(26))),
            const Icon(Icons.local_fire_department, color: AppColors.gold),
            const SizedBox(width: 4),
            Text('${s.streak}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(s.isUnlocked ? Icons.lock_open : Icons.lock,
                    size: 56, color: AppColors.gold),
                const SizedBox(height: 12),
                Text(
                  s.isUnlocked ? 'Your apps are open' : 'Your apps are locked',
                  style: serif(22),
                ),
                const SizedBox(height: 6),
                Text(
                  s.isUnlocked
                      ? 'Locks again in ${_left(s.unlockedUntil!)}'
                      : '${s.lockedApps.length} apps wait for your prayer',
                  style: const TextStyle(color: AppColors.soft),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PrayerFlow())),
                  icon: const Icon(Icons.favorite),
                  label: Text(s.isUnlocked ? 'Pray again' : 'Pray now'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _stat('Streak', '${s.streak} days', Icons.local_fire_department),
            const SizedBox(width: 12),
            _stat('Prayers', '${s.totalPrayers}', Icons.favorite),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VERSE OF THE DAY',
                    style: TextStyle(
                        letterSpacing: 1.5, fontSize: 12, color: AppColors.gold)),
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

  Widget _stat(String label, String value, IconData icon) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.gold),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: AppColors.soft)),
              ],
            ),
          ),
        ),
      );
}
