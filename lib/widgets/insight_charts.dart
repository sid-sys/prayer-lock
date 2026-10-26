import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../services/blocker_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'mood_face.dart';
import 'progress_report.dart' show fmtMinutes;

/// White rounded card with a title, used for every chart on the Insights tab.
class InsightCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const InsightCard({super.key, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: h(18)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!, style: h(12.5, color: AppColors.soft, w: FontWeight.w500)),
            ),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

/// Plays once when the chart appears: 0 -> 1 with a soft ease.
Widget _animate(Duration d, Widget Function(double t) build, {Curve curve = Curves.easeOutCubic}) =>
    TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: d,
      curve: curve,
      builder: (context, t, _) => build(t),
    );

const feelingColors = {
  'Grateful': Color(0xFFFFE27A),
  'Anxious': Color(0xFF9FA8FF),
  'Tired': Color(0xFF7FD9B8),
  'Hopeful': Color(0xFFFF9CC9),
  'Sad': Color(0xFFC9A6FF),
  'Stressed': Color(0xFFFF8A3D),
  'Peaceful': Color(0xFF8FD8FF),
  'Lost': Color(0xFFB8E986),
  'Private': Color(0xFFD9CFC4),
};

// ---------------------------------------------------------------------------
// Locked apps: how often each one paused you, opened, and for how long
// ---------------------------------------------------------------------------

class LockedAppsCard extends StatelessWidget {
  final List<AppLockStat> stats;
  const LockedAppsCard(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return InsightCard(
        title: 'Your locked apps',
        child: Text(
            'When you open a locked app, Prayer Lock pauses it. How often it was locked, opened and for how long will show here.',
            style: h(13.5, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.4)),
      );
    }
    final shown = stats.take(6).toList();
    final totalMin = stats.fold<int>(0, (a, s) => a + s.openMinutes);
    final totalBlocked = stats.fold<int>(0, (a, s) => a + s.blocked);
    final totalOpened = stats.fold<int>(0, (a, s) => a + s.unlocked);
    return InsightCard(
      title: 'Your locked apps',
      subtitle: 'Last 90 days. Locked = Prayer Lock paused it. Opened = you prayed first.',
      child: Column(children: [
        Row(children: [
          _pill('🔒 $totalBlocked', 'times locked', AppColors.blue),
          const SizedBox(width: 8),
          _pill('🙏 $totalOpened', 'times opened', AppColors.mint),
          const SizedBox(width: 8),
          _pill('⏱️ ${fmtMinutes(totalMin)}', 'open in total', AppColors.yellow),
        ]),
        const SizedBox(height: 16),
        for (var i = 0; i < shown.length; i++) _row(shown[i], i),
      ]),
    );
  }

  Widget _pill(String big, String small, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(big, style: h(17))),
            Text(small, style: h(10.5, w: FontWeight.w600)),
          ]),
        ),
      );

  Widget _row(AppLockStat s, int i) {
    final name = s.pkg == 'ios' ? 'Your locked apps' : BlockerService.nameOf(s.pkg);
    final rate = s.blocked == 0 ? 0.0 : (s.unlocked / s.blocked).clamp(0.0, 1.0);
    final avg = s.unlocked == 0 ? 0 : (s.openMinutes / s.unlocked).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: h(15), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('${fmtMinutes(s.openMinutes)} open',
              style: h(13, color: AppColors.soft, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        // opened out of locked, animated
        _animate(Duration(milliseconds: 700 + i * 120), (t) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Stack(children: [
                Container(color: const Color(0xFFF1E4D6)),
                FractionallySizedBox(
                  widthFactor: rate * t,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF7FD9B8), Color(0xFF3CC85F)]),
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 6),
        Text(
          'Locked ${s.blocked}×  ·  Opened ${s.unlocked}×  ·  Walked away ${s.skipped}×'
          '${s.unlocked > 0 ? '  ·  about ${fmtMinutes(avg)} each time' : ''}',
          style: h(12, color: AppColors.soft, w: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// How you felt: donut of the feeling you picked
// ---------------------------------------------------------------------------

class FeelingsDonut extends StatelessWidget {
  final List<PrayerEntry> history;
  const FeelingsDonut(this.history, {super.key});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final e in history) {
      counts[e.feeling] = (counts[e.feeling] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = history.length;
    return InsightCard(
      title: 'How you felt',
      subtitle: 'Your answers to "How are you feeling today?"',
      child: total == 0
          ? Text('Your feelings will show here after your first prayer.',
              style: h(13.5, color: AppColors.soft, w: FontWeight.w500))
          : Column(children: [
              SizedBox(
                height: 190,
                child: _animate(const Duration(milliseconds: 1100), (t) {
                  return CustomPaint(
                    painter: _DonutPainter(entries, total, t),
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${(total * t).round()}', style: h(34)),
                        Text('prayers', style: h(12, color: AppColors.soft, w: FontWeight.w600)),
                      ]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 14, runSpacing: 8, children: [
                for (final e in entries)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: feelingColors[e.key] ?? AppColors.peach, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('${e.key == 'Private' ? 'Kept private' : e.key} ${(e.value * 100 / total).round()}%',
                        style: h(12.5, w: FontWeight.w600)),
                  ]),
              ]),
            ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int total;
  final double t;
  _DonutPainter(this.entries, this.total, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side - 20, height: side - 20);
    const gap = 0.045;
    var start = -math.pi / 2;
    for (final e in entries) {
      final full = e.value / total * 2 * math.pi;
      final sweep = math.max(0.0, full * t - gap);
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..strokeCap = StrokeCap.butt
          ..color = feelingColors[e.key] ?? AppColors.peach,
      );
      start += full * t;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.t != t || old.total != total;
}

// ---------------------------------------------------------------------------
// Closeness to God over the last 30 days: a smooth line that draws itself
// ---------------------------------------------------------------------------

class ClosenessLine extends StatelessWidget {
  final List<PrayerEntry> history;
  const ClosenessLine(this.history, {super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [for (var i = 29; i >= 0; i--) today.subtract(Duration(days: i))];
    final pts = <Offset>[]; // x = day index 0..29, y = 0..1
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final list = history
          .where((e) => e.date.year == d.year && e.date.month == d.month && e.date.day == d.day)
          .toList();
      if (list.isEmpty) continue;
      final avg = list.map((e) => e.relationship).reduce((a, b) => a + b) / list.length;
      pts.add(Offset(i.toDouble(), (avg - 1) / 4));
    }
    // Smooth the ups and downs a little so the line shows the trend.
    if (pts.length > 2) {
      final raw = [for (final p in pts) p.dy];
      for (var i = 0; i < pts.length; i++) {
        final a = raw[math.max(0, i - 1)], b = raw[i], c = raw[math.min(raw.length - 1, i + 1)];
        pts[i] = Offset(pts[i].dx, (a + 2 * b + c) / 4);
      }
    }
    return InsightCard(
      title: 'Closeness over time',
      subtitle: 'Last 30 days. Higher means you felt closer to God.',
      child: pts.length < 2
          ? Text('Pray on a few different days and your line will appear here.',
              style: h(13.5, color: AppColors.soft, w: FontWeight.w500))
          : Column(children: [
              SizedBox(
                height: 170,
                child: _animate(const Duration(milliseconds: 1400), (t) {
                  return CustomPaint(
                    size: const Size.fromHeight(170),
                    painter: _LinePainter(pts, t),
                  );
                }, curve: Curves.easeInOutCubic),
              ),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(DateFormat('MMM d').format(days.first),
                    style: h(11, color: AppColors.soft, w: FontWeight.w600)),
                Text('Today', style: h(11, color: AppColors.soft, w: FontWeight.w600)),
              ]),
            ]),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<Offset> pts;
  final double t;
  _LinePainter(this.pts, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 58.0, topPad = 10.0, bottomPad = 10.0;
    final w = size.width - leftPad - 8;
    final h0 = size.height - topPad - bottomPad;
    Offset map(Offset p) => Offset(leftPad + p.dx / 29 * w, topPad + (1 - p.dy) * h0);

    // grid lines + labels
    final grid = Paint()
      ..color = const Color(0xFFF1E4D6)
      ..strokeWidth = 1.5;
    const labels = ['Very close', 'Close', 'Okay', 'Struggling', 'Distant'];
    for (var i = 0; i < 5; i++) {
      final y = topPad + i / 4 * h0;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - 4, y), grid);
      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: const TextStyle(fontSize: 9.5, color: AppColors.soft, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 6);
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    final p = pts.map(map).toList();
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final a = p[i], b = p[i + 1];
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    final drawn = Path();
    var left = total * t;
    for (final m in metrics) {
      if (left <= 0) break;
      drawn.addPath(m.extractPath(0, math.min(left, m.length)), Offset.zero);
      left -= m.length;
    }

    // soft fill under the drawn part
    final tip = drawn.computeMetrics().isEmpty
        ? p.first
        : (() {
            final ms = drawn.computeMetrics().toList();
            final last = ms.last;
            return last.getTangentForOffset(last.length)?.position ?? p.first;
          })();
    final fill = Path.from(drawn)
      ..lineTo(tip.dx, topPad + h0)
      ..lineTo(p.first.dx, topPad + h0)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gold.withValues(alpha: 0.35), AppColors.gold.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(leftPad, topPad, w, h0)),
    );
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.gold,
    );

    // dots appear as the line reaches them
    for (final o in p) {
      final reach = (o.dx - p.first.dx) / math.max(1, p.last.dx - p.first.dx);
      if (reach <= t) {
        canvas.drawCircle(o, 5.5, Paint()..color = Colors.white);
        canvas.drawCircle(o, 3.5, Paint()..color = AppColors.gold);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.t != t || old.pts != pts;
}

// ---------------------------------------------------------------------------
// When you pray: bars by time of day
// ---------------------------------------------------------------------------

class PrayerTimeBars extends StatelessWidget {
  final List<PrayerEntry> history;
  const PrayerTimeBars(this.history, {super.key});

  @override
  Widget build(BuildContext context) {
    const buckets = [
      ('🌅', 'Morning', 5, 12),
      ('☀️', 'Afternoon', 12, 17),
      ('🌆', 'Evening', 17, 21),
      ('🌙', 'Night', 21, 29), // 21:00 to 04:59 (hour+24 for after midnight)
    ];
    int count(int from, int to) => history.where((e) {
          final h = e.date.hour < 5 ? e.date.hour + 24 : e.date.hour;
          return h >= from && h < to;
        }).length;
    final counts = [for (final b in buckets) count(b.$3, b.$4)];
    final peak = counts.fold<int>(1, (a, b) => b > a ? b : a);
    const colors = [AppColors.yellow, AppColors.pink, AppColors.blue, Color(0xFFC9A6FF)];
    return InsightCard(
      title: 'When you pray',
      subtitle: 'Your prayers by time of day',
      child: history.isEmpty
          ? Text('This fills in as you pray.',
              style: h(13.5, color: AppColors.soft, w: FontWeight.w500))
          : SizedBox(
              height: 196,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < buckets.length; i++)
                  Expanded(
                    child: _animate(Duration(milliseconds: 800 + i * 150), (t) {
                      final hgt = 100 * counts[i] / peak * t;
                      return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text('${(counts[i] * t).round()}', style: h(15)),
                        const SizedBox(height: 4),
                        Container(
                          width: 46,
                          height: math.max(8, hgt),
                          decoration: BoxDecoration(
                            color: colors[i],
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(buckets[i].$1, style: const TextStyle(fontSize: 20)),
                        Text(buckets[i].$2,
                            style: h(11, color: AppColors.soft, w: FontWeight.w600)),
                      ]);
                    }),
                  ),
              ]),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Consistency: the last 5 weeks as a calendar of dots
// ---------------------------------------------------------------------------

class PrayerHeatmap extends StatelessWidget {
  final List<PrayerEntry> history;
  const PrayerHeatmap(this.history, {super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday of this week, then 4 weeks back.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final start = monday.subtract(const Duration(days: 28));
    final counts = <DateTime, int>{};
    for (final e in history) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final daysPrayed = counts.keys.where((d) => !d.isBefore(start) && !d.isAfter(today)).length;
    Color cell(int n) => n == 0
        ? const Color(0xFFF1E4D6)
        : n == 1
            ? const Color(0xFFFFC27A)
            : n == 2
                ? AppColors.gold
                : const Color(0xFFE5612A);
    return InsightCard(
      title: 'Your consistency',
      subtitle: 'You prayed on $daysPrayed of the last 35 days',
      child: Column(children: [
        Row(children: [
          for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
            Expanded(
                child: Center(
                    child: Text(l, style: h(11, color: AppColors.soft, w: FontWeight.w700)))),
        ]),
        const SizedBox(height: 6),
        for (var w = 0; w < 5; w++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              for (var d = 0; d < 7; d++)
                Expanded(child: Builder(builder: (context) {
                  final day = start.add(Duration(days: w * 7 + d));
                  final future = day.isAfter(today);
                  final n = counts[day] ?? 0;
                  return _animate(Duration(milliseconds: 500 + (w * 7 + d) * 28), (t) {
                    return Center(
                      child: Transform.scale(
                        scale: 0.4 + 0.6 * t,
                        child: Opacity(
                          opacity: future ? 0.25 * t : t,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: future ? const Color(0xFFF1E4D6) : cell(n),
                              borderRadius: BorderRadius.circular(10),
                              border: day == today
                                  ? Border.all(color: AppColors.ink, width: 2)
                                  : null,
                            ),
                            child: n >= 3
                                ? const Icon(Icons.local_fire_department_rounded,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }, curve: Curves.easeOutBack);
                })),
            ]),
          ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Less ', style: h(10.5, color: AppColors.soft, w: FontWeight.w600)),
          for (final n in [0, 1, 2, 3])
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(color: cell(n), borderRadius: BorderRadius.circular(4)),
            ),
          Text('  More', style: h(10.5, color: AppColors.soft, w: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

/// Small helper so Insights can show the mood face for an average closeness.
Widget closenessChip(double? avg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(14)),
      child: Text(avg == null ? '-' : moodWord(avg), style: h(13)),
    );

// ---------------------------------------------------------------------------
// With and without Prayer Lock: what your week would have looked like
// ---------------------------------------------------------------------------

class WithWithoutCard extends StatelessWidget {
  final AppState s;
  const WithWithoutCard(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final pauses = s.pausesThisWeek;
    final opened = s.countEvents('gate_prayed');
    final skipped = s.skippedSessionsThisWeek;
    const per = AppState.assumedSessionMinutes;
    final cmp = s.usageComparison;

    if (pauses == 0 && cmp == null) {
      return InsightCard(
        title: 'With and without Prayer Lock',
        child: Text(
            'When you open a locked app, Prayer Lock pauses you. This card will compare your week with and without that pause.',
            style: h(13.5, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.4)),
      );
    }

    final withoutMin = pauses * per;
    final withMin = opened * per;
    final savedMin = math.max(0, withoutMin - withMin);

    return InsightCard(
      title: 'With and without Prayer Lock',
      subtitle: 'This week: how your time would have gone, and how it went',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pair('Opens of locked apps', 'Without', pauses, 'With Prayer Lock', opened,
            unit: 'opens',
            note: 'Without Prayer Lock, every one of the $pauses opens goes through. With it, you walked away $skipped ${skipped == 1 ? 'time' : 'times'}.'),
        const SizedBox(height: 16),
        _pair('Time in those apps (estimate)', 'Without', withoutMin, 'With Prayer Lock', withMin,
            unit: 'min',
            minutes: true,
            note: 'We assume each open would last $per minutes. Nobody can know exactly.'),
        if (cmp != null) ...[
          const SizedBox(height: 16),
          _pair('Your daily time in locked apps (measured)', 'Before', cmp.before.round(), 'Now',
              cmp.now.round(),
              unit: 'min',
              minutes: true,
              note: 'First 7 days compared with your latest 7 days. A measured change, not proof of cause.'),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFE3F7EA), borderRadius: BorderRadius.circular(18)),
          child: Text(
            savedMin > 0
                ? '🌿 About ${fmtMinutes(savedMin)} stayed yours this week, and you gave ${s.prayersThisWeek} ${s.prayersThisWeek == 1 ? 'moment' : 'moments'} to prayer instead.'
                : '🌿 You gave ${s.prayersThisWeek} ${s.prayersThisWeek == 1 ? 'moment' : 'moments'} to prayer this week. Every pause is a choice.',
            style: h(14, w: FontWeight.w700).copyWith(height: 1.4),
          ),
        ),
      ]),
    );
  }

  Widget _pair(String title, String aLabel, int a, String bLabel, int b,
      {required String unit, bool minutes = false, required String note}) {
    final peak = math.max(1, math.max(a, b));
    String fmt(int v) => minutes ? fmtMinutes(v) : '$v';
    Widget bar(String label, int v, Color c, int delayMs) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            SizedBox(width: 124, child: Text(label, style: h(12.5, w: FontWeight.w700))),
            Expanded(
              child: _animate(Duration(milliseconds: 900 + delayMs), (t) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: v / peak * t,
                    minHeight: 18,
                    backgroundColor: const Color(0xFFF1E4D6),
                    color: c,
                  ),
                );
              }),
            ),
            SizedBox(
                width: 56,
                child: Text(fmt(v), textAlign: TextAlign.right, style: h(14))),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: h(14, color: AppColors.soft, w: FontWeight.w700)),
      const SizedBox(height: 8),
      bar(aLabel, a, const Color(0xFFD9CFC4), 0),
      bar(bLabel, b, const Color(0xFF3CC85F), 200),
      Text(note, style: h(11.5, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.35)),
    ]);
  }
}
