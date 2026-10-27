import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../theme.dart';
import 'admin_config.dart';
import 'admin_data.dart';
import 'admin_users.dart';

final _money0 = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

const _green = Color(0xFF2FB36A);
const _red = Color(0xFFE5484D);

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
  List<AdminUser>? _all;
  bool _realOnly = true;
  bool _showInstalls = false; // chart toggle: false = Active users
  bool _howCounted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _repo.loadUsers();
    if (mounted) setState(() => _all = u);
  }

  List<AdminUser> get _users =>
      _realOnly ? _all!.where((u) => hiddenReason(u) == null).toList() : _all!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Admin panel', style: h(20)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _all = null);
              _load();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _all == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
          : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final users = _users;
    final st = AdminStats.from(users);
    final email = FirebaseAuth.instance.currentUser?.email;
    final hidden = _all!.where((u) => hiddenReason(u) != null).toList();

    final left = <Widget>[
      _realOnlyCard(hidden),
      const SizedBox(height: 12),
      _numbers(st, users),
      const SizedBox(height: 12),
      _chartCard(users),
    ];
    final right = <Widget>[
      _funnelCard(st, users),
      const SizedBox(height: 12),
      _payFailCard(users),
      const SizedBox(height: 12),
      _sourceCard(users),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminUsersScreen(
              users: users,
              repo: _repo,
              realOnly: _realOnly,
            ),
          ),
        ),
        child: Text('See all ${users.length} users'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminFeedbackScreen(repo: _repo)),
        ),
        child: const Text('Feedback and bug reports'),
      ),
    ];

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 900;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Signed in as ${email != null && email.isNotEmpty ? email : kAdminEmail}',
                        style: h(13, color: AppColors.soft, w: FontWeight.w500),
                      ),
                    ),
                    if (kMockBuild)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('MOCK DATA', style: h(11, w: FontWeight.w800)),
                      ),
                  ],
                ),
              ),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: left)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(children: right)),
                  ],
                )
              else ...[
                ...left,
                const SizedBox(height: 12),
                ...right,
              ],
            ],
          );
        },
      ),
    );
  }

  // ---- Real users only ----

  Widget _realOnlyCard(List<AdminUser> hidden) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Real users only', style: h(17))),
              SmoothSwitch(
                value: _realOnly,
                onChanged: (v) => setState(() => _realOnly = v),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: hidden.isEmpty ? null : () => _showHidden(hidden),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _realOnly
                    ? 'Hiding ${hidden.length} test, review and my own accounts  ›'
                    : 'Showing everyone, including ${hidden.length} test, review and my own accounts  ›',
                style: h(
                  13,
                  color: AppColors.soft,
                  w: FontWeight.w600,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHidden(List<AdminUser> hidden) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Text('Hidden accounts', style: h(22)),
            const SizedBox(height: 4),
            Text(
              'Check that nobody real is hidden. Edit the rules in admin_config.dart.',
              style: h(13, color: AppColors.soft, w: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            for (final u in hidden)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PersonRow(
                  user: u,
                  trailing: _Pill(hiddenReason(u)!, AppColors.yellow),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminUserScreen(user: u)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- Number cards ----

  Widget _numbers(AdminStats st, List<AdminUser> users) {
    final paying = users.where((u) => u.payments.isNotEmpty).toList();
    final cards = <(String, String, String, Color, List<AdminUser>, String)>[
      (
        'Total users',
        '${st.totalUsers}',
        'Real people who installed',
        AppColors.blue,
        users,
        'All users',
      ),
      (
        'Subscribed',
        '${st.subscribedUsers}',
        '${st.totalUsers == 0 ? 0 : (st.subscribedUsers * 100 / st.totalUsers).round()}% of users',
        AppColors.mint,
        users.where((u) => u.subscribed).toList(),
        'Subscribed users',
      ),
      (
        'Active today',
        '${st.activeToday}',
        'Opened the app today',
        AppColors.yellow,
        users.where((u) => u.activeOn(DateTime.now())).toList(),
        'Active today',
      ),
      (
        'Revenue',
        _money0.format(st.revenue30d),
        'Last 30 days',
        AppColors.pink,
        paying,
        'People who paid',
      ),
      (
        'Profit before store cut',
        _money0.format(st.profitBefore),
        'Revenue minus our costs',
        const Color(0xFFC9A6FF),
        paying,
        'People who paid',
      ),
      (
        'Profit after store cut',
        _money0.format(st.profitAfter),
        'If stores keep ${(AdminConfig.storeCut * 100).round()}% (estimate)',
        Colors.white,
        paying,
        'People who paid',
      ),
    ];
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 124,
      ),
      children: [
        for (final c in cards)
          PastelCard(
            color: c.$4,
            padding: const EdgeInsets.all(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdminPeopleScreen(title: c.$6, users: c.$5, repo: _repo),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.$1, style: h(13, w: FontWeight.w700)),
                const Spacer(),
                Text(c.$2, style: h(28)),
                Text(
                  c.$3,
                  style: h(11, color: AppColors.soft, w: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---- One chart with a toggle ----

  Widget _chartCard(List<AdminUser> users) {
    final today = DateTime.now();
    final days = [
      for (var i = 29; i >= 0; i--)
        DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: i)),
    ];
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final active = [
      for (final d in days) users.where((u) => u.activeOn(d)).toList(),
    ];
    final installed = [
      for (final d in days) users.where((u) => same(u.installedAt, d)).toList(),
    ];
    final removed = [
      for (final d in days)
        users
            .where((u) => u.uninstalledAt != null && same(u.uninstalledAt!, d))
            .toList(),
    ];

    final peak = _showInstalls
        ? [
            for (var i = 0; i < days.length; i++) installed[i].length,
            for (var i = 0; i < days.length; i++) removed[i].length,
          ].fold<int>(1, (a, b) => b > a ? b : a)
        : active.map((e) => e.length).fold<int>(1, (a, b) => b > a ? b : a);

    void open(
      String title,
      List<AdminUser> people,
      String empty,
      String Function(AdminUser) timeOf,
    ) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPeopleScreen(
          title: title,
          users: people,
          repo: _repo,
          emptyText: empty,
          timeOf: timeOf,
        ),
      ),
    );

    final fmt = DateFormat('EEE d MMM');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // the toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                for (final o in const [
                  (false, 'Active users'),
                  (true, 'Installs and uninstalls'),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showInstalls = o.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _showInstalls == o.$1
                              ? AppColors.ink
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          o.$2,
                          textAlign: TextAlign.center,
                          style: h(
                            13,
                            color: _showInstalls == o.$1
                                ? Colors.white
                                : AppColors.ink,
                            w: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _showInstalls
                ? 'Installs and uninstalls'
                : 'People who opened the app',
            style: h(17),
          ),
          Text(
            'Last 30 days. Tap a bar to see the people.',
            style: h(12, color: AppColors.soft, w: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _showInstalls ? 196 : 176,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true, // newest day is in view first
              itemCount: days.length,
              itemBuilder: (context, r) {
                final i = days.length - 1 - r;
                final d = days[i];
                final label = DateFormat('d MMM').format(d);
                if (!_showInstalls) {
                  final n = active[i].length;
                  return _DayColumn(
                    width: 42,
                    label: label,
                    bars: [
                      _Bar(
                        n,
                        peak,
                        AppColors.ink,
                        () => open(
                          'Active on ${fmt.format(d)}',
                          active[i],
                          'Nobody was active that day',
                          (u) =>
                              'Last active ' +
                              DateFormat('h:mm a')
                                  .format(u.eventsOn(d).first.at),
                        ),
                      ),
                    ],
                  );
                }
                final ins = installed[i].length;
                final out = removed[i].length;
                final net = ins - out;
                return _DayColumn(
                  width: 62,
                  label: label,
                  net: net == 0
                      ? 'No change'
                      : (net > 0 ? 'Net gain +$net' : 'Net loss $net'),
                  netColor: net == 0
                      ? AppColors.soft
                      : (net > 0 ? _green : _red),
                  bars: [
                    _Bar(
                      ins,
                      peak,
                      _green,
                      () => open(
                        'Installed on ${fmt.format(d)}',
                        installed[i],
                        'Nobody installed that day',
                        (u) => DateFormat('h:mm a').format(u.installedAt),
                      ),
                    ),
                    _Bar(
                      out,
                      peak,
                      _red,
                      () => open(
                        'Uninstalled on ${fmt.format(d)}',
                        removed[i],
                        'Nobody uninstalled that day',
                        (u) => DateFormat('h:mm a').format(u.uninstalledAt!),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_showInstalls) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _howCounted = !_howCounted),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _howCounted
                      ? 'How is this counted?  ▾'
                      : 'How is this counted?  ›',
                  style: h(
                    13,
                    color: AppColors.soft,
                    w: FontWeight.w700,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
            if (_howCounted)
              Text(
                'Install: a phone with the app is counted once, on the day Android says the app was installed. '
                'It is shown with the account that last used that phone.\n\n'
                'Uninstall: once a day our server asks Google if each phone can still get messages (nobody is sent anything). '
                'If Google says the phone is gone, we mark the app as removed that day. We never guess.\n\n'
                'Honest limits: an uninstall can show a day or two late. A phone that was switched off is only noticed when Google answers. '
                'If the phone comes back later, the uninstall mark is removed. '
                'Android only. On iPhone, Apple does not tell us about uninstalls.',
                style: h(
                  12.5,
                  color: AppColors.soft,
                  w: FontWeight.w500,
                ).copyWith(height: 1.35),
              ),
          ],
        ],
      ),
    );
  }

  // ---- Funnel ----

  Widget _funnelCard(AdminStats st, List<AdminUser> users) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From joining to subscribing', style: h(17)),
          Text(
            'Of everyone who installed. Tap a step to see who got there.',
            style: h(12, color: AppColors.soft, w: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < st.funnel.length; i++) _funnelRow(st, i, users),
          if (st.biggestDrop != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Most people leave between "${st.funnel[st.biggestDrop! - 1].label}" and "${st.funnel[st.biggestDrop!].label}".',
                style: h(13, w: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _funnelRow(AdminStats st, int i, List<AdminUser> users) {
    final s = st.funnel[i];
    final worst = st.biggestDrop == i;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminPeopleScreen(
            title: s.label,
            users: users.where((u) => u.reached(s.key)).toList(),
            repo: _repo,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.label, style: h(14, w: FontWeight.w600)),
                ),
                Text('${s.count}', style: h(14)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(s.percent * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: h(
                      13,
                      color: worst ? _red : AppColors.soft,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: s.percent.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.card,
                color: worst ? _red : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- When paying did not happen ----

  Widget _payFailCard(List<AdminUser> users) {
    final kinds = ['cancelled', 'failed', 'store'];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When paying did not happen', style: h(17)),
          const SizedBox(height: 10),
          for (final k in kinds)
            Builder(
              builder: (context) {
                final people = users
                    .where((u) => u.payFails.any((f) => f.kind == k))
                    .toList();
                final times = users.fold<int>(
                  0,
                  (a, u) => a + u.payFails.where((f) => f.kind == k).length,
                );
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminPeopleScreen(
                        title: payFailTitles[k]!,
                        users: people,
                        repo: _repo,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$times',
                            textAlign: TextAlign.center,
                            style: h(18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${payFailTitles[k]}  ·  ${people.length} people',
                                style: h(14, w: FontWeight.w700),
                              ),
                              Text(
                                payFailReasons[k]!,
                                style: h(
                                  12,
                                  color: AppColors.soft,
                                  w: FontWeight.w500,
                                ).copyWith(height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---- Where people heard about us ----

  Widget _sourceCard(List<AdminUser> users) {
    const order = [
      'TikTok',
      'Instagram',
      'YouTube',
      'Facebook',
      'App Store or Play Store',
      'Friend or family',
      'Church',
      'Other',
    ];
    final counts = {
      for (final o in order) o: users.where((u) => u.heardFrom == o).toList(),
    };
    final peak = counts.values
        .map((e) => e.length)
        .fold<int>(1, (a, b) => b > a ? b : a);
    final asked = users.where((u) => u.heardFrom != null).length;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where people heard about us', style: h(17)),
          Text(
            '$asked people answered. Tap a bar to see them.',
            style: h(12, color: AppColors.soft, w: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          for (final e in counts.entries)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminPeopleScreen(
                    title: 'Heard about us from ${e.key}',
                    users: e.value,
                    repo: _repo,
                    emptyText: 'Nobody picked ${e.key}',
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 118,
                      child: Text(
                        e.key,
                        style: h(13, w: FontWeight.w600),
                        maxLines: 2,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: e.value.length / peak,
                          minHeight: 18,
                          backgroundColor: AppColors.card,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${e.value.length}',
                        style: h(14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- small parts ----------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: h(11, w: FontWeight.w800)),
  );
}

class _Bar {
  final int value;
  final int peak;
  final Color color;
  final VoidCallback onTap;
  const _Bar(this.value, this.peak, this.color, this.onTap);
}

/// One day of the chart: one or two bars, the number on top, the date under.
class _DayColumn extends StatelessWidget {
  final double width;
  final String label;
  final String? net;
  final Color netColor;
  final List<_Bar> bars;
  const _DayColumn({
    required this.width,
    required this.label,
    required this.bars,
    this.net,
    this.netColor = AppColors.soft,
  });

  @override
  Widget build(BuildContext context) {
    const maxH = 120.0;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: maxH + 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final b in bars)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: b.onTap,
                    child: SizedBox(
                      width: bars.length == 1 ? 26 : 24,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${b.value}', style: h(11, w: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Container(
                            height: b.value == 0
                                ? 3
                                : (maxH * b.value / b.peak).clamp(6.0, maxH),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: b.value == 0
                                  ? b.color.withValues(alpha: 0.25)
                                  : b.color,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: h(10, color: AppColors.soft, w: FontWeight.w600),
          ),
          if (net != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                net!,
                textAlign: TextAlign.center,
                style: h(9.5, color: netColor, w: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
