import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../theme.dart';
import 'admin_data.dart';
import 'admin_users.dart';

final _money0 = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

/// Who may open the admin panel.
bool isAdminUser() {
  if (kMockBuild) return true; // mock build: everyone can look
  final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
  return email == kAdminEmail.toLowerCase();
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminRepository _repo = MockAdminRepository();
  List<AdminUser>? _users;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _repo.loadUsers();
    if (mounted) setState(() => _users = u);
  }

  @override
  Widget build(BuildContext context) {
    final users = _users;
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin panel', style: h(20)),
        actions: [
          if (kMockBuild)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.yellow, borderRadius: BorderRadius.circular(12)),
              child: Text('MOCK DATA', style: h(11, w: FontWeight.w800)),
            ),
          IconButton(
              onPressed: () {
                setState(() => _users = null);
                _load();
              },
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: users == null
          ? const Center(child: CircularProgressIndicator())
          : _body(context, users),
    );
  }

  Widget _body(BuildContext context, List<AdminUser> users) {
    final st = AdminStats.from(users);
    final email = FirebaseAuth.instance.currentUser?.email;
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Signed in as ${email != null && email.isNotEmpty ? email : kAdminEmail}',
              style: h(13, color: AppColors.soft, w: FontWeight.w500),
            ),
          ),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 128),
            children: [
              _Metric('Total users', '${st.totalUsers}', '+${st.newUsers7d} this week', '👥', AppColors.blue),
              _Metric('Subscribed', '${st.subscribedUsers}',
                  '${(st.conversion * 100).toStringAsFixed(0)}% of users · ${st.payingUsers} paying · ${st.lifetimeUsers} lifetime', '👑', AppColors.mint),
              _Metric('Active today', '${st.dauToday}', '${st.wau} active this week', '🔥', AppColors.yellow),
              _Metric('Revenue', _money0.format(st.revenueTotal),
                  '${_money0.format(st.revenue30d)} last 30 days', '💰', AppColors.pink),
              _Metric('Profit', _money0.format(st.profit),
                  'Before store cut · costs ${_money0.format(st.costs)}', '📈', const Color(0xFFC9A6FF)),
              _Metric('After store cut', _money0.format(st.profit - st.storeCutEstimate),
                  'If stores take ~15%', '🏦', Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          _dauCard(st),
          const SizedBox(height: 14),
          _funnelCard(st),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => AdminUsersScreen(users: users))),
            child: Text('See all ${users.length} users →'),
          ),
        ],
      ),
    );
  }

  Widget _dauCard(AdminStats st) {
    final maxV = st.dauSeries.map((e) => e.$2).fold<int>(1, (a, b) => b > a ? b : a);
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily active users', style: h(17)),
          Text('Last 14 days', style: h(12, color: AppColors.soft, w: FontWeight.w500)),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final p in st.dauSeries)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${p.$2}', style: h(10, w: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          height: 6 + 100.0 * p.$2 / maxV,
                          decoration: BoxDecoration(
                            color: p.$1.day == today.day ? AppColors.ink : AppColors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(DateFormat('d').format(p.$1),
                            style: h(10, color: AppColors.soft, w: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _funnelCard(AdminStats st) {
    final top = st.funnel.first.$2 == 0 ? 1 : st.funnel.first.$2;
    const colors = [AppColors.blue, AppColors.blue, AppColors.mint, AppColors.yellow, AppColors.pink, AppColors.mint];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From joining to subscribing', style: h(17)),
          const SizedBox(height: 12),
          for (var i = 0; i < st.funnel.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(st.funnel[i].$1, style: h(13, w: FontWeight.w600))),
                    Text('${st.funnel[i].$2}', style: h(13, w: FontWeight.w800)),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 40,
                      child: Text('${(100 * st.funnel[i].$2 / top).round()}%',
                          textAlign: TextAlign.right,
                          style: h(12, color: AppColors.soft, w: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: st.funnel[i].$2 / top,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFF1E4D6),
                      color: colors[i],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final String emoji;
  final Color color;
  const _Metric(this.title, this.value, this.sub, this.emoji, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: h(13, w: FontWeight.w700))),
            Text(emoji, style: const TextStyle(fontSize: 18)),
          ]),
          const Spacer(),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: h(30, w: FontWeight.w800))),
          const SizedBox(height: 2),
          Text(sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: h(11, color: AppColors.ink.withValues(alpha: 0.7), w: FontWeight.w500)),
        ],
      ),
    );
  }
}
