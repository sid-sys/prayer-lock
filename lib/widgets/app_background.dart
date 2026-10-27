import 'package:flutter/material.dart';

/// The app background: one full sky picture (assets/img/bg_sky.png), made from
/// the sunrise and cloud panels. It fills the screen like the bell page.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFFCD2A5)),
        Image.asset(
          'assets/img/bg_sky.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        child,
      ],
    );
  }
}
