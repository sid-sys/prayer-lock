import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/blocker_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Profile', style: serif(26)),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
                backgroundColor: AppColors.gold,
                child: Icon(Icons.person, color: Colors.black)),
            title: Text((user?.displayName?.isNotEmpty ?? false)
                ? user!.displayName!
                : ((user?.email?.isNotEmpty ?? false) ? user!.email! : 'Guest 🙏')),
            subtitle: Text('${s.streak} day streak'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            SwitchListTile(
              value: s.remindersOn,
              onChanged: s.setRemindersOn,
              title: const Text('Prayer reminders 🔔'),
              subtitle: const Text('A gentle message morning and night'),
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
        Card(
          child: SwitchListTile(
            value: s.blockingOn,
            onChanged: s.setBlockingOn,
            title: const Text('Blocking on'),
            subtitle: const Text('Turn off to use all apps freely'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text('Next block after prayer',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              for (final o in const [
                [0, 'Automatic'],
                [30, '30 minutes'],
                [50, '50 minutes'],
                [60, '1 hour'],
                [120, '2 hours'],
              ])
                RadioListTile<int>(
                  value: o[0] as int,
                  groupValue: s.scheduleMinutes,
                  onChanged: (v) => s.setSchedule(v!),
                  title: Text(o[1] as String),
                ),
            ],
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
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: AuthService.signOut,
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete account',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () => _confirmDelete(context),
            ),
          ]),
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService.deleteAccount();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please sign in again, then try delete.')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
