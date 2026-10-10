import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin/admin_dashboard.dart';
import '../config.dart';
import '../services/auth_service.dart';
import '../services/blocker_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'legal_screen.dart';
import 'plan_screen.dart';

int _badgePreview = 0;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : ((user?.email?.isNotEmpty ?? false) ? user!.email! : 'Guest 🙏');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Profile', style: h(26)),
        const SizedBox(height: 16),

        // Who you are
        Card(
          child: ListTile(
            leading: const CircleAvatar(
                backgroundColor: AppColors.gold,
                child: Icon(Icons.person, color: Colors.black)),
            title: Text(name, style: h(17)),
            subtitle: Text('${s.streak} day streak 🔥'),
          ),
        ),
        const SizedBox(height: 12),

        // Plan
        Card(
          child: ListTile(
            leading: const Text('👑', style: TextStyle(fontSize: 26)),
            title: const Text('Your plan'),
            subtitle: Text(s.cancelled
                ? '${s.plan == 'yearly' ? 'Yearly' : 'Monthly'} · Cancelled'
                : s.inTrial
                    ? '${s.plan == 'yearly' ? 'Yearly' : 'Monthly'} · Free trial, ${s.trialDaysLeft} days left'
                    : '${s.plan == 'yearly' ? 'Yearly' : 'Monthly'} · Active'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PlanScreen())),
          ),
        ),
        const SizedBox(height: 12),

        // Reminders
        Card(
          child: Column(children: [
            ListTile(
              title: const Text('Prayer reminders 🔔'),
              subtitle: const Text('A gentle message morning and night'),
              trailing: SmoothSwitch(value: s.remindersOn, onChanged: s.setRemindersOn),
              onTap: () => s.setRemindersOn(!s.remindersOn),
            ),
            ListTile(
              leading: const Pic('sun', size: 34),
              title: const Text('Morning prayer'),
              trailing: Text(_fmt(context, s.morningMin)),
              onTap: () => _pickTime(context, s.morningMin, (m) => s.setTimes(morning: m)),
            ),
            ListTile(
              leading: const Pic('moon', size: 34),
              title: const Text('Night prayer'),
              trailing: Text(_fmt(context, s.nightMin)),
              onTap: () => _pickTime(context, s.nightMin, (m) => s.setTimes(night: m)),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Blocking
        Card(
          child: ListTile(
            title: const Text('Blocking on'),
            subtitle: const Text('Turn off to use all apps freely'),
            trailing: SmoothSwitch(value: s.blockingOn, onChanged: s.setBlockingOn),
            onTap: () => s.setBlockingOn(!s.blockingOn),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next block after prayer', style: h(16)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final o in const [
                    (0, 'Automatic'),
                    (30, '30 min'),
                    (50, '50 min'),
                    (60, '1 hour'),
                    (120, '2 hours'),
                  ])
                    ChoiceChip(
                      label: Text(o.$2),
                      selected: s.scheduleMinutes == o.$1,
                      showCheckmark: false,
                      selectedColor: AppColors.ink,
                      labelStyle: TextStyle(
                          color: s.scheduleMinutes == o.$1 ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w700),
                      onSelected: (_) => s.setSchedule(o.$1),
                    ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Text('🔒', style: TextStyle(fontSize: 24)),
            title: const Text('Lock my apps now'),
            subtitle: Text(s.isUnlocked
                ? 'Your apps are open. Tap to lock them again.'
                : 'Your apps are already locked.'),
            onTap: s.isUnlocked ? s.lockNow : null,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Allow app blocking'),
            subtitle: const Text('Open the phone setting that lets us block apps'),
            onTap: BlockerService.requestPermission,
          ),
        ),
        const SizedBox(height: 12),

        // Legal and support
        Card(
          child: Column(children: [
            ListTile(
              leading: const Text('🔐', style: TextStyle(fontSize: 22)),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LegalScreen(LegalDoc.privacy))),
            ),
            ListTile(
              leading: const Text('📄', style: TextStyle(fontSize: 22)),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LegalScreen(LegalDoc.terms))),
            ),
            ListTile(
              leading: const Text('✉️', style: TextStyle(fontSize: 22)),
              title: const Text('Contact us'),
              subtitle: const Text(kDeveloperName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SupportScreen())),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Admin (admin account only; everyone in the mock build)
        if (isAdminUser())
          Card(
            color: AppColors.yellow,
            child: ListTile(
              leading: const Text('🛠️', style: TextStyle(fontSize: 24)),
              title: Text('Admin panel', style: h(16)),
              subtitle: Text(kMockBuild ? 'Mock data for now' : 'Users, revenue and activity'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
            ),
          ),
        if (isAdminUser()) const SizedBox(height: 12),

        // Test tools (mock build only)
        if (kMockBuild)
          Card(
            color: const Color(0xFFFFE0E0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🧪 Test tools (temporary)', style: h(16)),
                  const SizedBox(height: 4),
                  Text('Only in the test build. Removed before release.',
                      style: h(12, color: AppColors.soft, w: FontWeight.w500)),
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Text('🔁', style: TextStyle(fontSize: 22)),
                    title: const Text('Redo onboarding'),
                    subtitle: const Text('See onboarding, commit and paywall again'),
                    onTap: () => _redo(context, s),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Text('🏅', style: TextStyle(fontSize: 22)),
                    title: const Text('Preview a badge toast'),
                    subtitle: const Text('Each tap shows the next badge'),
                    onTap: () {
                      final all = s.badges;
                      s.queueBadge(all[_badgePreview++ % all.length]);
                    },
                  ),
                ],
              ),
            ),
          ),
        if (kMockBuild) const SizedBox(height: 12),

        // Delete account
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          onPressed: () => _confirmDelete(context, s),
          child: Text('Delete account', style: h(16, color: Colors.red)),
        ),
        const SizedBox(height: 12),

        // Log out (red)
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
          onPressed: () => _confirmLogout(context),
          child: const Text('Log out'),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('Prayer Lock · by $kDeveloperName',
              style: h(12, color: AppColors.soft, w: FontWeight.w500)),
        ),
      ],
    );
  }

  String _fmt(BuildContext c, int m) =>
      TimeOfDay(hour: m ~/ 60, minute: m % 60).format(c);

  Future<void> _pickTime(BuildContext c, int cur, void Function(int) save) async {
    final t = await showTimePicker(
        context: c, initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60));
    if (t != null) save(t.hour * 60 + t.minute);
  }

  Future<void> _redo(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redo onboarding?'),
        content: const Text(
            'You will see onboarding, the commit screen and the paywall again. Your prayers and locked apps stay. On the paywall use "Skip paywall" to come back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start')),
        ],
      ),
    );
    if (ok == true) await s.redoOnboarding();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign in again any time. Your plan stays with your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await AuthService.signOut();
  }

  Future<void> _confirmDelete(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This deletes your account and everything saved on this phone: prayers, streak and badges. It cannot be undone. If you have a plan, cancel it in the store too.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete everything', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.deleteAccount();
      await s.resetAll();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.code == 'requires-recent-login'
              ? 'For safety, please log out, sign in again, then delete.'
              : 'Could not delete the account. Try again.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not delete the account. Try again.')));
    }
  }
}
