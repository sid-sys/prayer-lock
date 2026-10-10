import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/prayer_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // last 7 days, oldest first
    final week = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    int count(DateTime d) => s.history
        .where((e) => e.date.year == d.year && e.date.month == d.month && e.date.day == d.day)
        .length;
    final maxCount = week.map(count).fold<int>(1, (a, b) => b > a ? b : a);

    final recent = s.history.reversed.take(10).toList();
    final avg = s.history.isEmpty
        ? 0.0
        : s.history.map((e) => e.relationship).reduce((a, b) => a + b) /
            s.history.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Insights', style: serif(26)),
        const SizedBox(height: 16),
        Row(children: [
          _tile('Streak', '${s.streak}', Icons.local_fire_department),
          const SizedBox(width: 12),
          _tile('Total', '${s.totalPrayers}', Icons.favorite),
          const SizedBox(width: 12),
          _tile('Closeness', avg == 0 ? '-' : avg.toStringAsFixed(1), Icons.volunteer_activism),
        ]),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This week', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final d in week)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                height: count(d) == 0 ? 6 : 80 * count(d) / maxCount,
                                decoration: BoxDecoration(
                                  color: count(d) == 0
                                      ? AppColors.soft.withValues(alpha: 0.3)
                                      : AppColors.gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(DateFormat.E().format(d).substring(0, 1),
                                  style: const TextStyle(color: AppColors.soft)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Recent prayers', style: serif(20)),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No prayers yet. Your first one will show here.',
                style: TextStyle(color: AppColors.soft)),
          ),
        for (final e in recent)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.favorite, color: AppColors.gold),
              title: Text('Felt ${e.feeling.toLowerCase()}'),
              subtitle: Text(
                  '${PrayerService.relationshipLabels[e.relationship - 1]} with God'),
              trailing: Text(DateFormat('MMM d').format(e.date),
                  style: const TextStyle(color: AppColors.soft)),
            ),
          ),
      ],
    );
  }

  Widget _tile(String label, String value, IconData icon) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(color: AppColors.soft, fontSize: 12)),
            ]),
          ),
        ),
      );
}
