import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'legal_screen.dart';

/// Shown once, right before the paywall. A bell, a promise (a reminder before
/// the free trial ends), and the notification permission question.
class TrialReminderScreen extends StatefulWidget {
  const TrialReminderScreen({super.key});
  @override
  State<TrialReminderScreen> createState() => _TrialReminderScreenState();
}

class _TrialReminderScreenState extends State<TrialReminderScreen> {
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    await NotificationService.askPermission();
    if (mounted) await context.read<AppState>().markTrialReminderSeen();
  }

  void _legal(LegalDoc d) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LegalScreen(d)),
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(useMaterial3: true),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBC0CF),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // the bell picture is the whole screen
            Image.asset(
              'assets/img/bg_bell.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      "We'll send you a reminder before your trial ends",
                      textAlign: TextAlign.center,
                      style: h(32, color: Colors.black),
                    ),
                    const Spacer(), // the bell is in the picture behind
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 22, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'No commitment, cancel anytime',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(58),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _busy ? null : _continue,
                      child: const Text('Continue'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '7 days free, then ${PurchaseService.yearlyPrice} per year (${PurchaseService.yearlyPerMonth}/mo)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _link('Terms of Use', () => _legal(LegalDoc.terms)),
                        _link('Restore', _restore),
                        _link('Privacy Policy', () => _legal(LegalDoc.privacy)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore() async {
    final found = await PurchaseService.restore();
    if (!mounted) return;
    if (found != null) {
      await context.read<AppState>().startTrial(found);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No purchase found to restore.')),
      );
    }
  }

  Widget _link(String t, VoidCallback onTap) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: Colors.black87,
    ),
    onPressed: onTap,
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        decoration: TextDecoration.underline,
        color: Colors.black87,
      ),
    ),
  );
}
