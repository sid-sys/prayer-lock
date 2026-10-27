import 'package:flutter/material.dart';

/// The app background: the peach, pink and lavender sky from the splash
/// screen, with soft clouds at the bottom (assets/img/bg_clouds.png).
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFEB498), Color(0xFFFFCBA4), Color(0xFFFBC0CF), Color(0xFFE3BDEB)],
              stops: [0, 0.5, 0.82, 1],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.85,
              child: Image.asset('assets/img/bg_clouds.png',
                  fit: BoxFit.fitWidth, filterQuality: FilterQuality.high),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
