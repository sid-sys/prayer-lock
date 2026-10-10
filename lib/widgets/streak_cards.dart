import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Seven day circles: which days you prayed.
class StreakWeekCard extends StatelessWidget {
  final AppState s;
  final VoidCallback? onTap;
  const StreakWeekCard(this.s, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final week = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));
    return GestureDetector(
      onTap: onTap,
      child: Card(
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
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
    );
  }
}

/// "Next milestone: 3 days" with a progress bar.
class MilestoneCard extends StatelessWidget {
  final AppState s;
  final VoidCallback? onTap;
  const MilestoneCard(this.s, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (target, left) = s.nextMilestone;
    final progress = target == 0 ? 0.0 : (s.streak / target).clamp(0.0, 1.0);
    return PastelCard(
      color: AppColors.yellow,
      onTap: onTap,
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
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 12,
                backgroundColor: Colors.white54,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
