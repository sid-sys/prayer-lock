import 'package:flutter/material.dart';
import '../theme.dart';

/// Shown for about 1.5 seconds when the app starts: only the logo and the name.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, v, child) =>
              Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: v, child: child)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Pic('logo', size: 120),
              const SizedBox(height: 16),
              Text('Prayer Lock', style: serif(34)),
              const SizedBox(height: 6),
              Text('Pray first. Then scroll.',
                  style: h(15, color: AppColors.soft, w: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
