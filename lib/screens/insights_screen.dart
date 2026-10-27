import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/insight_charts.dart';
import 'prayer_history.dart';
import '../widgets/mood_face.dart';
import '../widgets/progress_report.dart';

class InsightsScreen extends StatelessWidget {
  /// Start this far down the page (used by screenshot mode).
  final double scrollTo;
  const InsightsScreen({super.key, this.scrollTo = 0});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final user = FirebaseAuth.instance.currentUser;
    final name = s.userName.isNotEmpty
        ? s.userName
        : (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : ((user?.email?.isNotEmpty ?? false) ? user!.email! : 'Friend 🙏');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    /// Average closeness (0..1) for a day, or null if no prayer.
    double? dayMood(DateTime d) {
      final list = s.history
          .where((e) => e.date.year == d.year && e.date.month == d.month && e.date.day == d.day)
          .toList();
      if (list.isEmpty) return null;
      final avg = list.map((e) => e.relationship).reduce((a, b) => a + b) / list.length;
      return (avg - 1) / 4;
    }

    final recent = s.history.reversed.take(10).toList();
    final avgAll = s.history.isEmpty
        ? null
        : (s.history.map((e) => e.relationship).reduce((a, b) => a + b) / s.history.length - 1) / 4;

    return ListView(
      controller: scrollTo > 0 ? ScrollController(initialScrollOffset: scrollTo) : null,
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: const Pic('logo', size: 96),
        ),
        const SizedBox(height: 10),
        Center(child: Text(name, style: h(20))),
        const SizedBox(height: 18),

        // Digital wellbeing and spiritual growth
        const ProgressReport(),
        const SizedBox(height: 22),
        WithWithoutCard(s),
        const SizedBox(height: 14),
        LockedAppsCard(s.lockStats()),
        const SizedBox(height: 22),
        Text('Closeness to God', style: h(20)),
        const SizedBox(height: 10),

        // Vertical mood bars, like the reference.
        Container(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 14),
                child: Text('How close you felt this week',
                    style: h(15, color: AppColors.soft, w: FontWeight.w600)),
              ),
              SizedBox(
                height: 190,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in week) Expanded(child: _bar(d, dayMood(d), d == today)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(children: [
          _tile('Streak', '${s.streak}', '🔥'),
          const SizedBox(width: 10),
          _tile('Prayers', '${s.totalPrayers}', '🙏'),
          const SizedBox(width: 10),
          _tile('Avg closeness', avgAll == null ? '-' : moodWord(avgAll), '💛'),
        ]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
              'Closeness is your answer to "How is your relationship with God today?" It goes from Distant to Very close. This is the average of all your answers.',
              style: h(12, color: AppColors.soft, w: FontWeight.w500)),
        ),
        const SizedBox(height: 22),

        Text('Your heart and habits', style: h(20)),
        const SizedBox(height: 10),
        ClosenessLine(s.history),
        const SizedBox(height: 14),
        FeelingsDonut(s.history),
        const SizedBox(height: 14),
        PrayerTimeBars(s.history),
        const SizedBox(height: 14),
        PrayerHeatmap(s.history),
        const SizedBox(height: 22),

        Text('Recent prayers', style: h(20)),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No prayers yet. Your first one will show here.',
                style: h(14, color: AppColors.soft, w: FontWeight.w500)),
          ),
        for (final e in recent) PrayerTile(e),
        if (s.history.length > recent.length)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.ink, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PrayerHistoryScreen())),
              child: Text('Show more (${s.history.length - recent.length} older)', style: h(16)),
            ),
          ),
      ],
    );
  }

  Widget _bar(DateTime d, double? mood, bool isToday) {
    const maxH = 135.0;
    final prayed = mood != null;
    final barH = prayed ? 50 + (maxH - 50) * mood : 34.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 36,
          height: barH + 18,
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: prayed
                ? levelColor(mood).withValues(alpha: 0.5)
                : const Color(0xFFF1E4D6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: prayed
              ? Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: _MiniFace(mood),
                )
              : const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Text('·', style: TextStyle(color: Color(0xFFBFA68E), fontSize: 18)),
                ),
        ),
        const SizedBox(height: 8),
        Text(DateFormat.E().format(d),
            style: h(12,
                color: isToday ? AppColors.ink : AppColors.soft,
                w: isToday ? FontWeight.w800 : FontWeight.w500)),
      ],
    );
  }

  Widget _tile(String label, String value, String emoji) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              FittedBox(child: Text(value, style: h(20))),
              Text(label, style: h(12, color: AppColors.soft, w: FontWeight.w500)),
            ]),
          ),
        ),
      );
}

/// Small round face for the top of each bar. Mouth and color follow the mood.
class _MiniFace extends StatelessWidget {
  final double t;
  const _MiniFace(this.t);
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(28, 28), painter: _MiniFacePainter(t));
}

class _MiniFacePainter extends CustomPainter {
  final double t;
  _MiniFacePainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2;
    c.drawCircle(Offset(r, r), r, Paint()..color = levelColor(t));
    final ink = Paint()..color = const Color(0xFF14141C);
    c.drawOval(Rect.fromCenter(center: Offset(r * 0.68, r * 0.82), width: r * 0.26, height: r * 0.38), ink);
    c.drawOval(Rect.fromCenter(center: Offset(r * 1.32, r * 0.82), width: r * 0.26, height: r * 0.38), ink);
    final bend = (t - 0.5) * 2;
    final path = Path()
      ..moveTo(r * 0.62, r * 1.38)
      ..quadraticBezierTo(r, r * 1.38 + bend * r * 0.42, r * 1.38, r * 1.38);
    c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.8
          ..color = const Color(0xFF14141C));
  }

  @override
  bool shouldRepaint(_MiniFacePainter o) => o.t != t;
}
