import 'package:flutter/material.dart';
import '../theme.dart';

/// Shown for about 1.6 seconds when the app starts: the logo, the name, a line
/// of comfort and three soft dots. Its top colour matches the phone's launch
/// screen (see flutter_native_splash in pubspec.yaml), so there is no flash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFEB498), Color(0xFFFFCBA4), Color(0xFFFBB7D0), Color(0xFFD9B8F0)],
            stops: [0, 0.45, 0.8, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, v, child) => Opacity(
                    opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: v, child: child)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFFE27A).withValues(alpha: 0.7),
                          blurRadius: 50,
                          spreadRadius: 6),
                    ],
                  ),
                  child: const Pic('logo', size: 150),
                ),
              ),
              const SizedBox(height: 26),
              Text('Prayer Lock', style: h(42)),
              const SizedBox(height: 8),
              Text('Stay close to God,\nwherever you are.',
                  textAlign: TextAlign.center,
                  style: h(17, color: AppColors.ink.withValues(alpha: 0.75), w: FontWeight.w600)),
              const Spacer(flex: 4),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.ink.withValues(
                              alpha: 0.25 + 0.6 * ((_c.value * 3 - i).clamp(0.0, 1.0) * (1 - ((_c.value * 3 - i) - 1).clamp(0.0, 1.0)))),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('Loading your prayer space…',
                  style: h(13, color: AppColors.ink.withValues(alpha: 0.6), w: FontWeight.w600)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
