import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/prayer_flow.dart';
import 'screens/onboarding.dart';
import 'screens/paywall.dart';
import 'screens/shell.dart';
import 'services/blocker_service.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final state = AppState();
  await state.load();
  await NotificationService.init();
  BlockerService.preload(); // load the app list in the background
  runApp(ChangeNotifierProvider.value(value: state, child: const PrayerLockApp()));
}

final navigatorKey = GlobalKey<NavigatorState>();

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
    final onboarded = context.select<AppState, bool>((s) => s.onboarded);
    final entitled = context.select<AppState, bool>((s) => s.entitled);
    if (!onboarded) return const Onboarding();
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
