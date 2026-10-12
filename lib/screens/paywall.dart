import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../services/purchase_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'legal_screen.dart';

/// Hard paywall: no close button. Style follows the reference screens.
/// The whole page scrolls, so nothing is ever cut off on small phones.
class Paywall extends StatefulWidget {
  const Paywall({super.key});
  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  String _plan = 'yearly';
  bool _busy = false;

  static const _orange = Color(0xFFFF9500);
  static const _ink = Color(0xFF1C1B22);

  bool get _lifetime => _plan == 'lifetime';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().logPaywallView();
    });
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    await context.read<AppState>().logPaymentAttempt();
    final ok = await PurchaseService.buy(_plan);
    if (!mounted) return;
    if (ok) {
      await context.read<AppState>().startTrial(_plan);
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final ok = await PurchaseService.restore();
    if (!mounted) return;
    if (ok) {
      await context.read<AppState>().startTrial(_plan);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No purchase found to restore.')));
    }
  }

  void _legal(LegalDoc d) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => LegalScreen(d)));

  @override
  Widget build(BuildContext context) {
    final bill = DateTime.now().add(const Duration(days: 7));
    final billText = DateFormat('MMM dd, yyyy').format(bill);
    return Theme(
      data: ThemeData.light(useMaterial3: true),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - 20),
                  // On a tall phone the extra space is shared around the timeline,
                  // so the page has no empty block at the bottom.
                  child: IntrinsicHeight(
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    _lifetime
                        ? 'Own Prayer Lock for life 🙏'
                        : 'Start your 7-day FREE trial to continue 🙏',
                    textAlign: TextAlign.center,
                    style: h(27, color: Colors.black)),
                const Spacer(flex: 2),

                // Timeline (kept compact so it is always visible)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _lifetime
                      ? Column(
                          key: const ValueKey('life'),
                          children: [
                            _step(Icons.all_inclusive, _orange, 'Today',
                                'Pay once and unlock morning and night prayer, pray-before-you-scroll, streaks and everything new we add.'),
                            _step(Icons.verified_outlined, Colors.black, 'Forever',
                                'No free trial. No renewals. No surprise charges.',
                                last: true),
                          ],
                        )
                      : Column(
                          key: const ValueKey('trial'),
                          children: [
                            _step(Icons.lock_open, _orange, 'Today',
                                'Unlock morning and night prayer, pray-before-you-scroll, streaks and more.'),
                            _step(Icons.notifications_active_outlined, _orange,
                                'In 5 Days - Reminder',
                                "We'll remind you that your trial is ending soon, if you've allowed notifications."),
                            _step(Icons.workspace_premium, Colors.black,
                                'In 7 Days - Billing Starts',
                                "You'll be charged on $billText unless you cancel anytime.",
                                last: true),
                          ],
                        ),
                ),
                const Spacer(flex: 3),

                // Plans (compact)
                _planCard(
                  id: 'yearly',
                  banner: '7 DAYS FREE',
                  title: 'Yearly · save ${PurchaseService.savePercent}%',
                  price: '${PurchaseService.yearlyPerMonth}/mo',
                  sub: '${PurchaseService.yearlyPrice} billed annually',
                ),
                const SizedBox(height: 10),
                _planCard(
                  id: 'monthly',
                  title: 'Monthly',
                  price: '${PurchaseService.monthlyPrice}/mo',
                ),
                const SizedBox(height: 10),
                _planCard(
                  id: 'lifetime',
                  title: '💎 Lifetime',
                  price: PurchaseService.lifetimePrice,
                  sub: 'Pay once. Yours forever.',
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, size: 20, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(_lifetime ? 'One payment. No renewals.' : 'No Payment Due Now',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _busy ? null : _start,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_lifetime ? 'Get Lifetime Access' : 'Start My 7-Day Free Trial'),
                ),
                const SizedBox(height: 8),
                Text(
                  switch (_plan) {
                    'yearly' =>
                      '7 days free, then ${PurchaseService.yearlyPrice} per year. Auto-renews unless you cancel. Cancel in the app store.',
                    'monthly' =>
                      '7 days free, then ${PurchaseService.monthlyPrice} per month. Auto-renews unless you cancel. Cancel in the app store.',
                    _ =>
                      'One-time payment of ${PurchaseService.lifetimePrice}. No free trial, no renewals. Refunds follow the app store rules.',
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _link('Terms', () => _legal(LegalDoc.terms)),
                    _link('Privacy', () => _legal(LegalDoc.privacy)),
                    _link('Restore', _restore),
                    if (kMockBuild && !kShotMode)
                      _link('Skip (test)', () => context.read<AppState>().testSkipPaywall(),
                          color: const Color(0xFFE53935)),
                  ],
                ),
              ],
            ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(String t, VoidCallback onTap, {Color color = Colors.black45}) => TextButton(
        style: TextButton.styleFrom(
            minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 10)),
        onPressed: onTap,
        child: Text(t, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _step(IconData icon, Color color, String title, String body, {bool last = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
                if (!last)
                  Expanded(child: Container(width: 8, color: const Color(0xFFFFD39C))),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: h(18, color: Colors.black, w: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(body,
                      style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.25)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required String id,
    String? banner,
    required String title,
    required String price,
    String? sub,
  }) {
    final on = _plan == id;
    return GestureDetector(
      onTap: () => setState(() => _plan = id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? Colors.black : Colors.black26, width: on ? 3 : 2.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (banner != null)
              Container(
                width: double.infinity,
                color: on ? Colors.black : Colors.black26,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(banner,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: on ? Colors.black : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: on ? Colors.black : Colors.black26, width: 2.5),
                    ),
                    child: on ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: h(17, color: Colors.black)),
                        if (sub != null)
                          Text(sub, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text(price, style: h(16, color: Colors.black54, w: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
