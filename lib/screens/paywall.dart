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
class Paywall extends StatefulWidget {
  const Paywall({super.key});
  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  String _plan = 'yearly';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().logPaywallView();
    });
  }

  static const _orange = Color(0xFFFF9500);
  static const _ink = Color(0xFF1C1B22);

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
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  children: [
                    Text('Start your 7-day FREE trial to continue 🙏',
                        textAlign: TextAlign.center,
                        style: h(32, color: Colors.black)),
                    const SizedBox(height: 28),
                    _step(Icons.lock_open, _orange, 'Today',
                        'Unlock morning and night prayer, pray-before-you-scroll, streaks and more.',
                        first: true),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Column(
                  children: [
                    
                    _planCard(
                      id: 'yearly',
                      banner: '7 DAYS FREE',
                      title: 'Save 75% yearly',
                      price: '${PurchaseService.yearlyPerMonth}/mo',
                      sub: '${PurchaseService.yearlyPrice} billed annually',
                    ),
                    const SizedBox(height: 12),
                    _planCard(
                      id: 'monthly',
                      title: 'Monthly',
                      price: '${PurchaseService.monthlyPrice}/mo',
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 22, color: Colors.black),
                        SizedBox(width: 8),
                        Text('No Payment Due Now',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(60),
                      ),
                      onPressed: _busy ? null : _start,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Start My 7-Day Free Trial'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _plan == 'yearly'
                          ? '7 days free, then ${PurchaseService.yearlyPrice} per year. Billed annually. Plan auto-renews unless you cancel. Cancel in the app store.'
                          : '7 days free, then ${PurchaseService.monthlyPrice} per month. Plan auto-renews unless you cancel. Cancel in the app store.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const LegalScreen(LegalDoc.terms))),
                            child: const Text('Terms', style: TextStyle(color: Colors.black45))),
                        TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const LegalScreen(LegalDoc.privacy))),
                            child: const Text('Privacy', style: TextStyle(color: Colors.black45))),
                        TextButton(onPressed: _restore, child: const Text('Restore', style: TextStyle(color: Colors.black45))),
                      ],
                    ),
                    if (kMockBuild)
                      TextButton(
                        onPressed: () => context.read<AppState>().testSkipPaywall(),
                        child: const Text('Skip paywall (test build only)',
                            style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _step(IconData icon, Color color, String title, String body,
      {bool first = false, bool last = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 12,
                      color: const Color(0xFFFFD39C),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: h(22, color: Colors.black, w: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(body,
                      style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.3)),
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
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: on ? Colors.black : Colors.black26, width: on ? 3 : 2.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (banner != null)
              Container(
                width: double.infinity,
                color: on ? Colors.black : Colors.black26,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(banner,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: on ? Colors.black : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: on ? Colors.black : Colors.black26, width: 3),
                    ),
                    child: on ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: h(20, color: Colors.black)),
                        if (sub != null)
                          Text(sub, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text(price, style: h(18, color: Colors.black54, w: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
