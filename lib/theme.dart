import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFFFFC999);
  static const card = Color(0xFFFFF3E6);
  static const peach = Color(0xFFFFC999);
  static const blue = Color(0xFF9FA8FF);
  static const mint = Color(0xFF7FD9B8);
  static const pink = Color(0xFFFF9CC9);
  static const yellow = Color(0xFFFFE27A);
  static const gold = Color(0xFFFF8A3D);
  static const soft = Color(0xFF6B5444);
  static const ink = Color(0xFF14141C);
}

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      surface: AppColors.card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.ink,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// Headline font (round and friendly, close to the reference).
TextStyle h(double size, {Color color = AppColors.ink, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.kumbhSans(fontSize: size, height: 1.2, color: color, fontWeight: w);

/// Bible and prayer text.
TextStyle serif(double size, {Color? color}) => GoogleFonts.lora(
      fontSize: size,
      height: 1.5,
      color: color ?? AppColors.ink,
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

/// Switch with a slow, smooth flip (the normal Material one is too quick).
class SmoothSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const SmoothSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    const d = Duration(milliseconds: 520);
    const c = Curves.easeInOutCubic;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: d,
        curve: c,
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: AnimatedAlign(
          duration: d,
          curve: c,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: d,
            curve: c,
            width: value ? 20 : 16,
            height: value ? 20 : 16,
            decoration: BoxDecoration(
              color: value ? Colors.white : AppColors.ink,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
