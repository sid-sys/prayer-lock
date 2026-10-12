import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../services/blocker_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

String fmtMinutes(int m) {
  if (m < 60) return '${m}m';
  final h = m ~/ 60;
  final r = m % 60;
  return r == 0 ? '${h}h' : '${h}h ${r}m';
}

/// "Your progress" report: spiritual consistency + digital wellbeing.
/// Every number says whether it was MEASURED or is an ESTIMATE.
class ProgressReport extends StatefulWidget {
  const ProgressReport({super.key});
  @override
  State<ProgressReport> createState() => _ProgressReportState();
}

class _ProgressReportState extends State<ProgressReport> with WidgetsBindingObserver {
  bool get _android => defaultTargetPlatform == TargetPlatform.android && !kShotMode && !kDemoData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone settings: look again.
    if (state == AppLifecycleState.resumed) _load();
  }

  void _load() {
    if (_android) context.read<AppState>().refreshUsage();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final apps = s.usageWeekByApp();
    final cmp = s.usageComparison;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your progress', style: h(24)),
        Text('This week', style: h(14, color: AppColors.soft, w: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
            'A clearer picture of your time, your habits, and the moments you made for God.',
            style: h(14, color: AppColors.soft, w: FontWeight.w500)),
        const SizedBox(height: 14),

        // four numbers
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 120),
          children: [
            _metric('Prayers completed', '${s.prayersThisWeek}', '🙏', AppColors.yellow, measured: true),
            _metric('App pauses', '${s.pausesThisWeek}', '⏸️', AppColors.blue, measured: true),
            _metric('Time potentially reclaimed',
                s.reclaimedMinutesThisWeek == 0 ? '0m' : '≈ ${fmtMinutes(s.reclaimedMinutesThisWeek)}',
                '⏳', AppColors.mint, measured: false),
            _metric('Prayer streak', '${s.streak} ${s.streak == 1 ? 'day' : 'days'}', '🔥', AppColors.pink,
                measured: true),
          ],
        ),
        const SizedBox(height: 16),

        _whereTimeWent(s, apps),
        const SizedBox(height: 14),
        _beforeAfter(s, cmp),
        const SizedBox(height: 14),
        _reflect(s),
        const SizedBox(height: 12),

        // how to read the numbers
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('How to read these numbers', style: h(13)),
            const SizedBox(height: 4),
            Text(
                'Measured: counted by the app on your phone.\nEstimated: our best guess. We assume a skipped session would have lasted ${AppState.assumedSessionMinutes} minutes, and we never count the time you spend praying. Nobody can know exactly what you would have done without the pause.\nYour activity numbers stay on your phone.',
                style: h(12, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.4)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                onPressed: () => _confirmClear(context, s),
                child: const Text('Delete my activity history',
                    style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _tag(bool measured) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: measured ? 0.85 : 0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Text(measured ? 'MEASURED' : 'ESTIMATE',
            style: h(8.5, color: measured ? Colors.white : AppColors.ink, w: FontWeight.w800)),
      );

  Widget _metric(String title, String value, String emoji, Color color, {required bool measured}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: h(12, w: FontWeight.w700), maxLines: 2)),
            Text(emoji, style: const TextStyle(fontSize: 18)),
          ]),
          const Spacer(),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: h(28, w: FontWeight.w800))),
          const SizedBox(height: 4),
          _tag(measured),
        ]),
      );

  Widget _card({required String title, required Widget child, bool? measured}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: h(17))),
            if (measured != null) _tag(measured),
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      );

  // ---- where your time went ----
  Widget _whereTimeWent(AppState s, List<MapEntry<String, int>> apps) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS && !kShotMode;

    if (ios) {
      return _card(
        title: 'Where your time went',
        child: Text(
            'Apple does not share time per app with other apps, so Prayer Lock cannot show it on iPhone. You can see it in iPhone Settings > Screen Time. Here we show your pauses and prayers instead.',
            style: h(13, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.4)),
      );
    }

    if (!s.hasUsageAccess) {
      return _card(
        title: 'Where your time went',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              'To show how long you spend in your locked apps, Android needs your OK ("usage access"). We only read time spent per app, on this phone. Nothing is sent anywhere.',
              style: h(13, color: AppColors.soft, w: FontWeight.w500).copyWith(height: 1.4)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: BlockerService.requestUsageAccess,
            child: const Text('Turn on usage access'),
          ),
        ]),
      );
    }

    if (apps.isEmpty) {
      return _card(
        title: 'Where your time went',
        measured: true,
        child: Text(
            s.lockedApps.isEmpty
                ? 'Lock some apps in the Locked apps tab, and their time will show here.'
                : 'No time recorded yet for your locked apps. Check back tomorrow.',
            style: h(13, color: AppColors.soft, w: FontWeight.w500)),
      );
    }

    final top = apps.take(5).toList();
    final max = top.first.value == 0 ? 1 : top.first.value;
    const colors = [AppColors.pink, AppColors.blue, AppColors.yellow, AppColors.mint, AppColors.peach];
    return _card(
      title: 'Where your time went',
      measured: true,
      child: Column(children: [
        for (var i = 0; i < top.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(BlockerService.nameOf(top[i].key), style: h(14, w: FontWeight.w600))),
                Text(fmtMinutes(top[i].value), style: h(14, w: FontWeight.w800)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: top[i].value / max),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF1E4D6),
                    color: colors[i % colors.length],
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  // ---- before and after ----
  Widget _beforeAfter(AppState s, ({double before, double now, int days})? cmp) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS && !kShotMode;
    if (ios) return const SizedBox.shrink();
    if (!s.hasUsageAccess) return const SizedBox.shrink();

    if (cmp == null) {
      final n = s.usageDaysRecorded.clamp(0, 10);
      return _card(
        title: 'Before and after',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Collecting your baseline: $n of 10 days.',
              style: h(14, w: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: n / 10,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1E4D6),
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
              'We compare your first 7 days with your latest 7 days. It needs about 10 days of numbers.',
              style: h(12, color: AppColors.soft, w: FontWeight.w500)),
        ]),
      );
    }

    final change = cmp.before == 0 ? 0.0 : (cmp.now - cmp.before) / cmp.before * 100;
    final down = change < 0;
    return _card(
      title: 'Before and after',
      measured: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _avg('First 7 days', cmp.before, const Color(0xFFF1E4D6))),
          const SizedBox(width: 10),
          Expanded(child: _avg('Latest 7 days', cmp.now, down ? AppColors.mint : AppColors.pink)),
        ]),
        const SizedBox(height: 10),
        Text(
            change.abs() < 1
                ? 'Your daily time in locked apps has stayed about the same.'
                : '${down ? '↓' : '↑'} ${change.abs().round()}% ${down ? 'less' : 'more'} time per day in your locked apps.',
            style: h(14, w: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
            'This is a measured change in your usage. It does not prove why it changed.',
            style: h(12, color: AppColors.soft, w: FontWeight.w500)),
      ]),
    );
  }

  Widget _avg(String label, double minutes, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: h(12, w: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${fmtMinutes(minutes.round())} / day', style: h(18, w: FontWeight.w800)),
        ]),
      );

  // ---- reflect ----
  Widget _reflect(AppState s) {
    final n = s.pausesThisWeek;
    final text = n == 0
        ? 'When you open a locked app, Prayer Lock will pause you first. Your pauses will show up here.'
        : 'You paused before opening distracting apps $n ${n == 1 ? 'time' : 'times'} this week. Each pause was a chance to choose how you wanted to spend your time.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('A moment to reflect 🕊️', style: h(17)),
        const SizedBox(height: 8),
        Text(text, style: serif(16).copyWith(height: 1.45)),
      ]),
    );
  }

  Future<void> _confirmClear(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete activity history?'),
        content: const Text(
            'This removes your pause counts and time-per-app numbers from this phone. Your prayers and streak stay.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await s.clearActivity();
  }
}
