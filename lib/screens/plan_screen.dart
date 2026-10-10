import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../services/purchase_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _busy = false;
  String? _picked; // the plan the user tapped

  static const _order = ['monthly', 'yearly', 'lifetime'];
  static int _rank(String p) => _order.indexOf(p);

  static String _price(String p) => switch (p) {
        'yearly' => '${PurchaseService.yearlyPrice} / year',
        'monthly' => '${PurchaseService.monthlyPrice} / month',
        _ => '${PurchaseService.lifetimePrice} one time',
      };

  /// The plan we suggest: the next one up, or the lifetime plan.
  String _target(AppState s) {
    final t = _picked;
    if (t != null && t != s.plan) return t;
    return s.plan == 'monthly' ? 'yearly' : 'lifetime';
  }

  Future<void> _change(AppState s, String target) async {
    final up = _rank(target) > _rank(s.plan);
    final fmt = DateFormat('MMM d, yyyy');
    final title = switch (target) {
      'lifetime' => 'Get Lifetime?',
      'yearly' => 'Upgrade to Yearly?',
      _ => 'Switch to Monthly?',
    };
    final text = switch (target) {
      'lifetime' =>
        'Pay ${PurchaseService.lifetimePrice} one time and keep Prayer Lock for life. Your ${PurchaseService.nameOf(s.plan)} plan stops renewing. No more payments.',
      'yearly' =>
        'Yearly is ${PurchaseService.yearlyPrice} per year (${PurchaseService.yearlyPerMonth} a month). You save ${PurchaseService.savePercent}% compared with paying monthly.',
      _ =>
        'Monthly is ${PurchaseService.monthlyPrice} per month. The change starts at your next renewal on ${fmt.format(s.nextBilling)}.',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(up ? 'Continue' : 'Switch'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await s.logPaymentAttempt();
    await PurchaseService.buy(target);
    await s.changePlan(target);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _picked = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(target == 'lifetime'
            ? 'You have Lifetime now. Thank you 🙏'
            : target == 'yearly'
                ? 'You are on Yearly now 🎉'
                : 'Switched to Monthly')));
  }

  Future<void> _cancel(AppState s) async {
    final until = DateFormat('MMM d, yyyy').format(s.inTrial ? s.trialEnds! : s.nextBilling);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel your plan?'),
        content: Text(
            'You keep full access until $until. After that your plan will not renew, prayers will pause and your apps will stay as they are.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep my plan')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel plan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await s.cancelPlan();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final target = _target(s);
    final fmt = DateFormat('MMM d, yyyy');

    String status;
    if (s.isLifetime) {
      status = 'Lifetime. It never expires. Thank you 🙏';
    } else if (s.cancelled) {
      status = 'Cancelled. Access until ${fmt.format(s.accessUntil ?? s.nextBilling)}';
    } else if (s.inTrial) {
      status =
          'Free trial: ${s.trialDaysLeft} ${s.trialDaysLeft == 1 ? 'day' : 'days'} left. First payment ${fmt.format(s.trialEnds!)}';
    } else {
      status = 'Active. Renews ${fmt.format(s.nextBilling)}';
    }

    final up = _rank(target) > _rank(s.plan);

    return Scaffold(
      appBar: AppBar(title: Text('Your plan', style: h(20))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Current plan
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: AppColors.ink, borderRadius: BorderRadius.circular(28)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('CURRENT PLAN',
                        style: h(12, color: Colors.white54, w: FontWeight.w800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.cancelled ? Colors.redAccent : AppColors.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          s.isLifetime
                              ? 'Lifetime'
                              : s.cancelled
                                  ? 'Cancelled'
                                  : (s.inTrial ? 'Trial' : 'Active'),
                          style: h(12, color: AppColors.ink, w: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text('Prayer Lock ${PurchaseService.nameOf(s.plan)}',
                      style: h(28, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(_price(s.plan),
                      style: h(16, color: Colors.white70, w: FontWeight.w500)),
                  const SizedBox(height: 14),
                  Text(status, style: h(14, color: Colors.white, w: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (s.isLifetime)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: AppColors.yellow, borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  const Text('💎', style: TextStyle(fontSize: 34)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                        'You have the best plan. Nothing to renew, nothing to cancel.',
                        style: h(15, w: FontWeight.w700)),
                  ),
                ]),
              )
            else ...[
              Text('Change plan', style: h(20)),
              const SizedBox(height: 10),
              for (final p in ['yearly', 'monthly', 'lifetime']) ...[
                _planTile(s, p, target),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              FilledButton(
                onPressed: _busy ? null : () => _change(s, target),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(switch (target) {
                        'lifetime' => 'Get Lifetime 💎',
                        'yearly' => 'Upgrade to Yearly 🚀',
                        _ => 'Switch down to Monthly',
                      }),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                    target == 'lifetime'
                        ? 'One payment. No renewals.'
                        : up
                            ? 'Upgrades start right away.'
                            : 'Downgrades start at your next renewal.',
                    style: h(13, color: AppColors.soft, w: FontWeight.w500)),
              ),
              const SizedBox(height: 22),
              if (s.cancelled)
                FilledButton(
                  onPressed: s.resumePlan,
                  child: const Text('Resume my plan 🙏'),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => _cancel(s),
                  child: Text('Cancel plan', style: h(17, color: Colors.red)),
                ),
            ],
            const SizedBox(height: 16),
            if (kMockBuild)
              Center(
                child: Text('Test mode: no real payment is taken yet.',
                    style: h(12, color: AppColors.soft, w: FontWeight.w500)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _planTile(AppState s, String p, String target) {
    final current = s.plan == p;
    final picked = !current && target == p;
    final emoji = switch (p) {
      'yearly' => '👑',
      'monthly' => '🌙',
      _ => '💎',
    };
    final subtitle = switch (p) {
      'yearly' => 'Best value. Save ${PurchaseService.savePercent}%',
      'monthly' => 'Pay month by month',
      _ => 'Pay once. Yours forever.',
    };
    final price = switch (p) {
      'yearly' => '${PurchaseService.yearlyPerMonth}/mo',
      'monthly' => '${PurchaseService.monthlyPrice}/mo',
      _ => PurchaseService.lifetimePrice,
    };
    return GestureDetector(
      onTap: current ? null : () => setState(() => _picked = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: current ? Colors.white : AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: current
                  ? AppColors.ink
                  : picked
                      ? AppColors.gold
                      : Colors.transparent,
              width: 2.5),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(PurchaseService.nameOf(p), style: h(18)),
                if (current) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
                    child: Text('Current', style: h(11, color: Colors.white)),
                  ),
                ],
              ]),
              Text(subtitle, style: h(13, color: AppColors.soft, w: FontWeight.w500)),
            ]),
          ),
          Text(price, style: h(16, w: FontWeight.w800)),
        ]),
      ),
    );
  }
}
