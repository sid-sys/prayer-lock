import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import 'admin_data.dart';

final _day = DateFormat('d MMM');
final _dayTime = DateFormat('d MMM, h:mm a');

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 2) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  if (d.inDays < 30) return '${d.inDays} d ago';
  return _day.format(t);
}

Color planColor(String plan) => switch (plan) {
  'lifetime' => const Color(0xFFC9A6FF),
  'yearly' => AppColors.mint,
  'monthly' => AppColors.blue,
  _ => const Color(0xFFE6E0D8),
};

String planLabel(String plan) => switch (plan) {
  'lifetime' => 'Lifetime',
  'yearly' => 'Yearly',
  'monthly' => 'Monthly',
  _ => 'Free',
};

Widget _tag(String t, [Color? c]) => Container(
  margin: const EdgeInsets.only(right: 6, top: 4),
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: c ?? const Color(0xFFEFE7DD),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Text(t, style: h(11, w: FontWeight.w700)),
);

class Avatar extends StatelessWidget {
  final AdminUser user;
  final double size;
  const Avatar(this.user, {super.key, this.size = 44});
  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.blue,
      AppColors.yellow,
      AppColors.mint,
      AppColors.pink,
      Color(0xFFC9A6FF),
      Color(0xFF8FD8FF),
    ];
    final c = colors[user.id.codeUnitAt(0) % colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      child: Text(user.initials, style: h(size * 0.36)),
    );
  }
}

/// One person in a list: real name, real email, plan, time, tags.
class PersonRow extends StatelessWidget {
  final AdminUser user;
  final String? time; // text on the right, under the plan
  final Widget? trailing;
  final VoidCallback onTap;
  const PersonRow({
    super.key,
    required this.user,
    required this.onTap,
    this.time,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final showEmail =
        (user.name?.trim().isNotEmpty ?? false) &&
        (user.email?.isNotEmpty ?? false);
    final reason = hiddenReason(user);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: h(15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showEmail)
                      Text(
                        user.email!,
                        style: h(12, color: AppColors.soft, w: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Wrap(
                      children: [
                        _tag(planLabel(user.plan), planColor(user.plan)),
                        if (user.isGuest) _tag('Guest'),
                        if (user.testPurchase)
                          _tag('Test purchase', AppColors.yellow),
                        if (user.uninstalled)
                          _tag('Removed the app', const Color(0xFFFFD6D6)),
                        if (reason != null && !user.testPurchase)
                          _tag(reason, AppColors.yellow),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time ?? 'Seen ${_ago(user.lastSeen)}',
                        style: h(11, color: AppColors.soft, w: FontWeight.w600),
                      ),
                      Text(
                        'Joined ${_day.format(user.joinedAt)}',
                        style: h(11, color: AppColors.soft, w: FontWeight.w500),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A short list of people behind a number or a bar.
// ---------------------------------------------------------------------------

class AdminPeopleScreen extends StatelessWidget {
  final String title;
  final List<AdminUser> users;
  final AdminRepository repo;
  final String emptyText;

  /// Text on the right of each row (for example the install time).
  final String Function(AdminUser)? timeOf;
  const AdminPeopleScreen({
    super.key,
    required this.title,
    required this.users,
    required this.repo,
    this.emptyText = 'Nobody here yet',
    this.timeOf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: h(18)), centerTitle: false),
      body: users.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: h(18, color: AppColors.soft, w: FontWeight.w600),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              itemCount: users.length + 1,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Text(
                    '${users.length} ${users.length == 1 ? 'person' : 'people'}',
                    style: h(13, color: AppColors.soft, w: FontWeight.w600),
                  );
                }
                final u = users[i - 1];
                return PersonRow(
                  user: u,
                  time: timeOf?.call(u),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminUserScreen(user: u)),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 2: All users
// ---------------------------------------------------------------------------

class AdminUsersScreen extends StatefulWidget {
  final List<AdminUser> users;
  final AdminRepository repo;
  final bool realOnly;
  const AdminUsersScreen({
    super.key,
    required this.users,
    required this.repo,
    required this.realOnly,
  });
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _q = '';
  String _filter = 'All';
  String _sort = 'Signed up';

  static const _filters = ['All', 'Subscribed', 'Free', 'Active today'];
  static const _sorts = ['Signed up', 'Last seen', 'Installed', 'Uninstalled'];

  List<AdminUser> get _list {
    final today = DateTime.now();
    var l = widget.users.where((u) {
      switch (_filter) {
        case 'Subscribed':
          if (!u.subscribed) return false;
        case 'Free':
          if (u.subscribed) return false;
        case 'Active today':
          if (!u.activeOn(today)) return false;
      }
      if (_q.isEmpty) return true;
      final q = _q.toLowerCase();
      return (u.name ?? '').toLowerCase().contains(q) ||
          (u.email ?? '').toLowerCase().contains(q) ||
          u.displayName.toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case 'Signed up':
        l.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
      case 'Last seen':
        l.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
      case 'Installed':
        l.sort((a, b) => b.installedAt.compareTo(a.installedAt));
      case 'Uninstalled':
        l = l.where((u) => u.uninstalled).toList()
          ..sort((a, b) => b.uninstalledAt!.compareTo(a.uninstalledAt!));
    }
    return l;
  }

  String _timeFor(AdminUser u) => switch (_sort) {
    'Installed' => 'Installed ${_day.format(u.installedAt)}',
    'Uninstalled' => 'Removed ${_day.format(u.uninstalledAt!)}',
    _ => 'Seen ${_ago(u.lastSeen)}',
  };

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Scaffold(
      appBar: AppBar(
        title: Text('All users', style: h(18)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search name or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      showCheckmark: false,
                      selectedColor: AppColors.ink,
                      backgroundColor: Colors.white,
                      labelStyle: h(
                        13,
                        color: _filter == f ? Colors.white : AppColors.ink,
                        w: FontWeight.w700,
                      ),
                      side: BorderSide.none,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${list.length} ${list.length == 1 ? 'person' : 'people'}',
                    style: h(13, color: AppColors.soft, w: FontWeight.w600),
                  ),
                ),
                Text(
                  'Sort: ',
                  style: h(13, color: AppColors.soft, w: FontWeight.w600),
                ),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox(),
                  isDense: true,
                  style: h(13, w: FontWeight.w800),
                  items: [
                    for (final s in _sorts)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? _sort),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      _sort == 'Uninstalled'
                          ? 'Nobody has removed the app'
                          : 'Nobody found',
                      style: h(17, color: AppColors.soft, w: FontWeight.w600),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: list.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => PersonRow(
                      user: list[i],
                      time: _timeFor(list[i]),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUserScreen(user: list[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 3: One user
// ---------------------------------------------------------------------------

class AdminUserScreen extends StatelessWidget {
  final AdminUser user;
  const AdminUserScreen({super.key, required this.user});

  DateTime? _firstEvent(String type) {
    DateTime? best;
    for (final e in user.events) {
      if (e.type == type && (best == null || e.at.isBefore(best))) best = e.at;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final u = user;
    final reason = hiddenReason(u);

    // The journey, using this app's real steps.
    final journey = <(String, DateTime?, bool)>[
      ('Installed the app', u.installedAt, true),
      ('Opened the app', u.installedAt, true),
      ('Finished onboarding', _firstEvent('onboarding_done'), u.onboardingDone),
      ('Held the commit button', _firstEvent('committed'), u.committed),
      (
        'Signed up or guest',
        _firstEvent('signed_up'),
        u.reached('signup'),
      ),
      ('Saw the paywall', _firstEvent('paywall_view'), u.paywallViews > 0),
      ('Tried to pay', _firstEvent('payment_attempt'), u.paymentAttempts > 0),
      ('Subscribed (${planLabel(u.plan)})', u.subscribedAt, u.subscribed),
      ('First prayer', _firstPrayer(), u.prayedOnce),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Person', style: h(18)), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (reason != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Hidden from the numbers when "Real users only" is on: $reason.',
                style: h(13, w: FontWeight.w700),
              ),
            ),
          _box(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(u, size: 60),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.displayName, style: h(20)),
                      if ((u.name?.isNotEmpty ?? false) &&
                          (u.email?.isNotEmpty ?? false))
                        Text(
                          u.email!,
                          style: h(
                            13,
                            color: AppColors.soft,
                            w: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Wrap(
                        children: [
                          _tag(u.country),
                          _tag(u.isGuest ? 'Guest' : 'Signed up'),
                          _tag(planLabel(u.plan), planColor(u.plan)),
                          if (u.testPurchase)
                            _tag('Test purchase', AppColors.yellow),
                          if (u.uninstalled)
                            _tag('Removed the app', const Color(0xFFFFD6D6)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Joined ${_dayTime.format(u.joinedAt)}  ·  Last seen ${_ago(u.lastSeen)}'
                        '${u.streak > 0 ? '  ·  ${u.streak} day streak' : ''}',
                        style: h(12, color: AppColors.soft, w: FontWeight.w500),
                      ),
                      if (u.paid > 0)
                        Text(
                          'Paid so far: \$${u.paid.toStringAsFixed(2)}',
                          style: h(
                            12,
                            color: AppColors.soft,
                            w: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Journey', style: h(17)),
                const SizedBox(height: 10),
                for (var i = 0; i < journey.length; i++)
                  _journeyRow(
                    journey[i].$1,
                    journey[i].$2,
                    journey[i].$3,
                    i == journey.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What they told us', style: h(17)),
                const SizedBox(height: 8),
                if (u.answers.isEmpty)
                  Text(
                    'Left before answering any question',
                    style: h(14, color: AppColors.soft, w: FontWeight.w600),
                  )
                else
                  for (final e in u.answers.entries.where(
                    (e) => e.value.isNotEmpty,
                  ))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: h(
                              12,
                              color: AppColors.soft,
                              w: FontWeight.w600,
                            ),
                          ),
                          Text(e.value, style: h(15, w: FontWeight.w600)),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity', style: h(17)),
                const SizedBox(height: 8),
                if (u.events.isEmpty)
                  Text(
                    'No activity yet',
                    style: h(14, color: AppColors.soft, w: FontWeight.w600),
                  ),
                for (final e in u.events.take(60))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title, style: h(14, w: FontWeight.w700)),
                              if (e.detail.isNotEmpty)
                                Text(
                                  e.detail,
                                  style: h(
                                    12,
                                    color: AppColors.soft,
                                    w: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _dayTime.format(e.at),
                          style: h(
                            11,
                            color: AppColors.soft,
                            w: FontWeight.w600,
                          ),
                        ),
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

  DateTime? _firstPrayer() {
    DateTime? best;
    for (final e in user.events) {
      if (e.type.startsWith('prayer_') && (best == null || e.at.isBefore(best)))
        best = e.at;
    }
    return best;
  }

  Widget _box(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );

  Widget _journeyRow(String label, DateTime? at, bool done, bool last) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: done ? AppColors.ink : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done ? AppColors.ink : Colors.black26,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done ? AppColors.ink : Colors.black12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: h(
                        14,
                        color: done ? AppColors.ink : Colors.black38,
                        w: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (done && at != null)
                    Text(
                      _dayTime.format(at),
                      style: h(11, color: AppColors.soft, w: FontWeight.w600),
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

// ---------------------------------------------------------------------------
// Screen 4: Feedback
// ---------------------------------------------------------------------------

class AdminFeedbackScreen extends StatefulWidget {
  final AdminRepository repo;
  const AdminFeedbackScreen({super.key, required this.repo});
  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<AdminFeedback>? _items;

  @override
  void initState() {
    super.initState();
    widget.repo.loadFeedback().then((v) {
      if (mounted) setState(() => _items = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback and bug reports', style: h(18)),
        centerTitle: false,
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
          : items.isEmpty
          ? Center(
              child: Text(
                'No feedback yet',
                style: h(18, color: AppColors.soft, w: FontWeight.w600),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final f = items[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: f.handled ? const Color(0xFFFFF3E6) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _tag(
                                  f.kind == 'bug' ? 'Bug report' : 'Feedback',
                                  f.kind == 'bug'
                                      ? const Color(0xFFFFD6D6)
                                      : AppColors.mint,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${f.from}  ·  ${_ago(f.at)}',
                                    style: h(
                                      12,
                                      color: AppColors.soft,
                                      w: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              f.text,
                              style: h(
                                14,
                                w: FontWeight.w500,
                              ).copyWith(height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Checkbox(
                            value: f.handled,
                            activeColor: AppColors.ink,
                            onChanged: (v) =>
                                setState(() => f.handled = v ?? false),
                          ),
                          Text(
                            'Handled',
                            style: h(
                              10,
                              color: AppColors.soft,
                              w: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
