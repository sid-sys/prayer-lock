import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io' show File, Platform;
import 'admin/admin_dashboard.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'screens/plan_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/commit_screen.dart';
import 'screens/prayer_flow.dart';
import 'screens/onboarding.dart';
import 'screens/paywall.dart';
import 'screens/shell.dart';
import 'screens/splash.dart';
import 'screens/trial_reminder.dart';
import 'services/review_service.dart';
import 'services/auth_service.dart';
import 'services/blocker_service.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/badge_toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final state = AppState();
  await state.load();
  await NotificationService.init();
  BlockerService.preload(); // load the app list in the background
  if (kShotMode) {
    // The workflow starts the app with the environment variable SHOT=<screen>.
    _shot = Platform.environment['SHOT'] ?? 'home';
  }
  runApp(ChangeNotifierProvider.value(value: state, child: const PrayerLockApp()));
}

final navigatorKey = GlobalKey<NavigatorState>();

/// Screen to show in screenshot mode (see kShotMode).
String _shot = 'home';

Widget _shotScreen() {
  switch (_shot) {
    case 'onboarding_0':
      return const Onboarding(startAt: 0);
    case 'onboarding_1':
      return const Onboarding(startAt: 1);
    case 'onboarding_2':
      return const Onboarding(startAt: 2);
    case 'onboarding_3':
      return const Onboarding(startAt: 3);
    case 'onboarding_4':
      return const Onboarding(startAt: 4);
    case 'onboarding_9':
      return const Onboarding(startAt: 9);
    case 'onboarding_12':
      return const Onboarding(startAt: 12);
    case 'lockintro':
      return const PrayerFlow(kind: 'gate', openAfter: 'ios');
    case 'insights_a':
      return const Scaffold(body: SafeArea(child: InsightsScreen(scrollTo: 520)));
    case 'insights_b':
      return const Scaffold(body: SafeArea(child: InsightsScreen(scrollTo: 1450)));
    case 'insights_c':
      return const Scaffold(body: SafeArea(child: InsightsScreen(scrollTo: 2900)));
    case 'compare':
      return const Onboarding(startAt: 6);
    case 'reminder':
      return const TrialReminderScreen();
    case 'commit':
      return const CommitScreen();
    case 'commit_hold':
      return const CommitScreen(demoProgress: 0.8);
    case 'badges':
      return const StreakScreen(scrollTo: 640);
    case 'paywall':
      return const Paywall();
    case 'prayer':
      return const PrayerFlow(kind: 'gate');
    case 'insights':
      return const Shell(initialIndex: 1);
    case 'locked':
      return const Shell(initialIndex: 2);
    case 'profile':
      return const Shell(initialIndex: 3);
    case 'streak':
      return const StreakScreen();
    case 'plan':
      return const PlanScreen();
    case 'admin':
      return const AdminDashboard();
    default:
      return const Shell();
  }
}

class PrayerLockApp extends StatefulWidget {
  const PrayerLockApp({super.key});
  @override
  State<PrayerLockApp> createState() => _PrayerLockAppState();
}

class _PrayerLockAppState extends State<PrayerLockApp> with WidgetsBindingObserver {
  bool _flowOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A locked app was opened: show the prayer first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlockerService.listenBlocked(_onBlocked);
      NotificationService.onOpenPrayer = _openScheduled;
      final first = NotificationService.launchKind; // app started by a reminder
      NotificationService.launchKind = null;
      if (first != null) _openScheduled(first);
      context.read<AppState>().touch(); // the 3-day comeback clock starts again
      _maybeAskReview();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().touch();
      _maybeAskReview();
    }
  }

  /// Once a week, until the person has rated, ask for a rating.
  /// Only for people who are inside the app (signed in and past the paywall).
  Future<void> _maybeAskReview() async {
    if (kShotMode) return;
    await Future<void>.delayed(const Duration(seconds: 4));
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted || _flowOpen) return;
    final s = ctx.read<AppState>();
    if (FirebaseAuth.instance.currentUser == null || !s.entitled) return;
    await ReviewService.maybeAsk(ctx, s);
  }

  /// [raw] is "com.app" (a locked app was opened) or "com.app|morning" (an open
  /// app was opened while a morning or night prayer is waiting).
  void _onBlocked(String raw) {
    final parts = raw.split('|');
    final pkg = parts.first;
    final kind = parts.length > 1 ? parts[1] : 'gate';
    final nav = navigatorKey.currentState;
    if (nav == null || _flowOpen) return;
    // Only after onboarding, paywall and sign in are done.
    if (FirebaseAuth.instance.currentUser == null) return;
    final s = context.read<AppState>();
    if (!s.onboarded || !s.entitled) return;
    _flowOpen = true;
    if (kind == 'gate') s.logEvent('gate_shown', pkg); // a locked app was opened and we paused it
    nav
        .push(MaterialPageRoute(
            builder: (_) => PrayerFlow(kind: kind, openAfter: pkg)))
        .whenComplete(() => _flowOpen = false);
  }

  /// The person tapped the morning or night reminder: open that prayer.
  void _openScheduled(String kind) {
    final nav = navigatorKey.currentState;
    if (nav == null || _flowOpen) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    final s = context.read<AppState>();
    if (!s.onboarded || !s.entitled) return;
    _flowOpen = true;
    nav
        .push(MaterialPageRoute(builder: (_) => PrayerFlow(kind: kind)))
        .whenComplete(() => _flowOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => BadgeToaster(child: child ?? const SizedBox()),
      title: 'Prayer Lock',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Gate(),
    );
  }
}

/// Order: onboarding -> paywall -> sign in -> app.
///
/// The sign in stream is created once. If it was created inside build(),
/// every small change (lock an app, flip a switch) made a new stream,
/// showed a spinner and sent the user back to the Home tab.
class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  late final Stream<User?> _auth = FirebaseAuth.instance.authStateChanges();
  Timer? _shotTimer;
  bool _splashDone = kShotMode;

  @override
  void initState() {
    super.initState();
    if (!kShotMode) {
      Future<void>.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _splashDone = true);
      });
    }
    if (kShotMode) {
      // Screenshot mode: the workflow writes the screen name into a file on
      // the Mac (the simulator can read it). We look at it twice a second.
      _shotTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        try {
          final name = File('/tmp/prayerlock_shot.txt').readAsStringSync().trim();
          if (name.isNotEmpty && name != _shot && mounted) {
            debugPrint('SHOT -> $name');
            setState(() => _shot = name);
          }
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _shotTimer?.cancel();
    super.dispose();
  }


  /// Give the Firebase account the first name from onboarding (only if the
  /// account has no name yet, for example email sign up).
  void _syncProfileName(User user) {
    final name = context.read<AppState>().userName;
    if (name.isEmpty || (user.displayName?.isNotEmpty ?? false) || user.isAnonymous) return;
    user.updateDisplayName(name).catchError((_) {});
  }
  @override
  Widget build(BuildContext context) {
    if (kShotMode) return KeyedSubtree(key: ValueKey(_shot), child: _shotScreen());
    if (!_splashDone) return const SplashScreen();
    final onboarded = context.select<AppState, bool>((s) => s.onboarded);
    final entitled = context.select<AppState, bool>((s) => s.entitled);
    final committed = context.select<AppState, bool>((s) => s.committed);
    final reminderSeen = context.select<AppState, bool>((s) => s.trialReminderSeen);
    // Order: splash -> onboarding -> commit -> sign up -> paywall -> app.
    if (!onboarded) return const Onboarding();
    if (!committed) return const CommitScreen();
    return StreamBuilder<User?>(
      stream: _auth,
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData) return const AuthScreen();
        if (!entitled && AuthService.isReviewer(snap.data)) {
          // Store reviewer: give Pro (lifetime) right away, no paywall.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<AppState>().startTrial('lifetime');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        _syncProfileName(snap.data!);
        if (!entitled) return reminderSeen ? const Paywall() : const TrialReminderScreen();
        return const Shell();
      },
    );
  }
}
