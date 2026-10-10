import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/admin_dashboard.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'screens/plan_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/commit_screen.dart';
import 'screens/prayer_flow.dart';
import 'screens/onboarding.dart';
import 'screens/paywall.dart';
import 'screens/shell.dart';
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
    final p = await SharedPreferences.getInstance();
    _shot = p.getString('shot') ?? 'home';
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
    case 'onboarding_3':
      return const Onboarding(startAt: 3);
    case 'onboarding_6':
      return const Onboarding(startAt: 6);
    case 'commit':
      return const CommitScreen();
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

class _PrayerLockAppState extends State<PrayerLockApp> {
  bool _flowOpen = false;

  @override
  void initState() {
    super.initState();
    // A locked app was opened: show the prayer first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlockerService.listenBlocked(_onBlocked);
    });
  }

  void _onBlocked(String pkg) {
    final nav = navigatorKey.currentState;
    if (nav == null || _flowOpen) return;
    // Only after onboarding, paywall and sign in are done.
    if (FirebaseAuth.instance.currentUser == null) return;
    final s = context.read<AppState>();
    if (!s.onboarded || !s.entitled) return;
    _flowOpen = true;
    nav
        .push(MaterialPageRoute(
            builder: (_) => PrayerFlow(kind: 'gate', openAfter: pkg)))
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

  @override
  Widget build(BuildContext context) {
    if (kShotMode) return _shotScreen();
    final onboarded = context.select<AppState, bool>((s) => s.onboarded);
    final entitled = context.select<AppState, bool>((s) => s.entitled);
    final committed = context.select<AppState, bool>((s) => s.committed);
    if (!onboarded) return const Onboarding();
    if (!committed) return const CommitScreen();
    if (!entitled) return const Paywall();
    return StreamBuilder<User?>(
      stream: _auth,
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.hasData ? const Shell() : const AuthScreen();
      },
    );
  }
}
