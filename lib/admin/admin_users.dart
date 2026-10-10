import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import 'admin_data.dart';

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return DateFormat('MMM d').format(t);
}

String initials(String name) =>
    name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();

Color planColor(String plan) => switch (plan) {
      'yearly' => AppColors.yellow,
      'monthly' => AppColors.mint,
      _ => const Color(0xFFE8D2BC),
    };

String planLabel(String plan) => switch (plan) {
      'yearly' => 'Yearly',
      'monthly' => 'Monthly',
      _ => 'Free',
    };

class AdminUsersScreen extends StatefulWidget {
  final List<AdminUser> users;
  const AdminUsersScreen({super.key, required this.users});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _q = '';
  String _filter = 'All';
  static const _filters = ['All', 'Subscribed', 'Free', 'Active today'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final list = widget.users.where((u) {
      if (_q.isNotEmpty &&
          !u.name.toLowerCase().contains(_q.toLowerCase()) &&
          !u.email.toLowerCase().contains(_q.toLowerCase())) {
        return false;
      }
      return switch (_filter) {
        'Subscribed' => u.subscribed,
        'Free' => !u.subscribed,
        'Active today' => u.activeOn(today),
        _ => true,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Users (${list.length})', style: h(20))),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Search name or email',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        showCheckmark: false,
                        selectedColor: AppColors.ink,
                        labelStyle: TextStyle(
                            color: _filter == f ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w700),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                itemBuilder: (_, i) => _tile(context, list[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, AdminUser u) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => AdminUserDetail(user: u))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: AppColors.blue,
                child: Text(initials(u.name), style: h(14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name, style: h(15)),
                  Text(u.email,
                      overflow: TextOverflow.ellipsis,
                      style: h(12, color: AppColors.soft, w: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('Joined ${DateFormat('MMM d').format(u.joinedAt)} · Seen ${ago(u.lastSeen)}',
                      style: h(11, color: AppColors.soft, w: FontWeight.w500)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: planColor(u.plan), borderRadius: BorderRadius.circular(12)),
                child: Text(planLabel(u.plan), style: h(12, w: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class AdminUserDetail extends StatelessWidget {
  final AdminUser user;
  const AdminUserDetail({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final u = user;
    final today = DateTime.now();
    final todays = u.eventsOn(today);
    final recent = u.events.where((e) => !todays.contains(e)).take(25).toList();
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(u.name, style: h(20))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(26)),
              child: Column(children: [
                CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.blue,
                    child: Text(initials(u.name), style: h(24))),
                const SizedBox(height: 10),
                Text(u.name, style: h(20)),
                Text(u.email, style: h(13, color: AppColors.soft, w: FontWeight.w500)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
                  _chip(planLabel(u.plan), planColor(u.plan)),
                  _chip('🌍 ${u.country}', AppColors.card),
                  _chip('🔥 ${u.streak} day streak', AppColors.card),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _kv('Joined', fmt.format(u.joinedAt))),
                  Expanded(child: _kv('Last seen', ago(u.lastSeen))),
                  Expanded(child: _kv('Prayers', '${u.prayerCount}')),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // Journey
            Text('Journey', style: h(18)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(children: [
                _step('Onboarding complete', u.onboardingComplete),
                _step('Committed devotion to Jesus', u.committed),
                _step('Reached the paywall', u.paywallViews > 0,
                    trailing: '${u.paywallViews} ${u.paywallViews == 1 ? 'time' : 'times'}'),
                _step('Tried to pay', u.paymentAttempts > 0,
                    trailing: '${u.paymentAttempts} ${u.paymentAttempts == 1 ? 'attempt' : 'attempts'}'),
                _step('Subscribed', u.subscribed,
                    trailing: u.subscribed
                        ? '${planLabel(u.plan)} · ${fmt.format(u.subscribedAt!)}'
                        : null,
                    last: true),
              ]),
            ),
            if (u.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Paid so far: \$${u.paid.toStringAsFixed(2)} in ${u.payments.length} ${u.payments.length == 1 ? 'payment' : 'payments'}',
                  style: h(13, color: AppColors.soft, w: FontWeight.w600)),
            ],
            const SizedBox(height: 18),

            // Today
            Text('Today', style: h(18)),
            const SizedBox(height: 8),
            if (todays.isEmpty)
              _empty('No activity today')
            else
              _list(todays, time: true),
            const SizedBox(height: 18),

            // Earlier
            Text('Earlier activity', style: h(18)),
            const SizedBox(height: 8),
            if (recent.isEmpty) _empty('Nothing earlier') else _list(recent),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
        child: Text(t, style: h(12, w: FontWeight.w800)),
      );

  Widget _kv(String k, String v) => Column(children: [
        Text(v, style: h(15)),
        Text(k, style: h(11, color: AppColors.soft, w: FontWeight.w500)),
      ]);

  Widget _step(String label, bool ok, {String? trailing, bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF1E4D6))),
        ),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: ok ? AppColors.mint : const Color(0xFFF1E4D6)),
            child: Icon(ok ? Icons.check : Icons.close,
                size: 16, color: ok ? AppColors.ink : AppColors.soft),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: h(14, w: FontWeight.w600))),
          if (trailing != null)
            Flexible(
              child: Text(trailing,
                  textAlign: TextAlign.right,
                  style: h(12, color: AppColors.soft, w: FontWeight.w600)),
            ),
        ]),
      );

  Widget _empty(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: h(14, color: AppColors.soft, w: FontWeight.w500)),
      );

  Widget _list(List<AdminEvent> events, {bool time = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          for (final e in events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title, style: h(14)),
                    if (e.detail.isNotEmpty)
                      Text(e.detail, style: h(12, color: AppColors.soft, w: FontWeight.w500)),
                  ]),
                ),
                Text(
                    time
                        ? DateFormat('h:mm a').format(e.at)
                        : DateFormat('MMM d').format(e.at),
                    style: h(12, color: AppColors.soft, w: FontWeight.w600)),
              ]),
            ),
        ]),
      );
}
