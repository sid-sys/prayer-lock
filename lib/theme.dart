import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0B0B10);
  static const card = Color(0xFF1A1A22);
  static const peach = Color(0xFFFFC999);
  static const blue = Color(0xFF9FA8FF);
  static const mint = Color(0xFF7FD9B8);
  static const pink = Color(0xFFFF9CC9);
  static const yellow = Color(0xFFFFE27A);
  static const gold = yellow;
  static const soft = Color(0xFFA9AECB);
  static const ink = Color(0xFF14141C);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.peach,
      onPrimary: AppColors.ink,
      surface: AppColors.card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// Headline font (round and friendly, close to the reference).
TextStyle h(double size, {Color color = Colors.white, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.kumbhSans(fontSize: size, height: 1.2, color: color, fontWeight: w);

/// Bible and prayer text.
TextStyle serif(double size, {Color? color}) => GoogleFonts.lora(
      fontSize: size,
      height: 1.5,
      color: color ?? Colors.white,
    );

/// Picture from the sprite sheet.
class Pic extends StatelessWidget {
  final String name;
  final double size;
  const Pic(this.name, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/img/$name.png', width: size, height: size, filterQuality: FilterQuality.medium);
}

/// Colored rounded card like the reference ("Anger / Anxiety / Insomnia").
class PastelCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const PastelCard({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(padding: padding, child: DefaultTextStyle.merge(style: const TextStyle(color: AppColors.ink), child: child)),
        ),
      );
}

/// Small white round arrow button (top right of pastel cards).
class ArrowDot extends StatelessWidget {
  const ArrowDot({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.north_east, size: 18, color: AppColors.ink),
      );
}

/// Thin segmented progress bar at the top of onboarding.
class SegBar extends StatelessWidget {
  final int count;
  final int index;
  final Color active;
  final Color idle;
  const SegBar({super.key, required this.count, required this.index, this.active = Colors.white, this.idle = const Color(0x55FFFFFF)});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= index ? active : idle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      );
}
