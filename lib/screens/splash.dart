import 'package:flutter/material.dart';

/// Shown for about 1.6 seconds when the app starts. It is the splash picture
/// from the brand sheet, full screen. The phone's own launch screen is plain
/// peach-pink (flutter_native_splash in pubspec.yaml), so there is no flash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEB498),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/img/splash_art.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
