import 'package:flutter/material.dart';
import '../theme.dart';

/// The praying girl, breathing gently, while a prayer is being written.
/// Five frames from assets/img/girl_pray_1..5.png, played back and forth.
class PrayingLoader extends StatefulWidget {
  final String text;
  const PrayingLoader({super.key, this.text = 'Writing your prayer…'});
  @override
  State<PrayingLoader> createState() => _PrayingLoaderState();
}

class _PrayingLoaderState extends State<PrayingLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final f = Curves.easeInOut.transform(_c.value) * 4; // 0..4
            final a = f.floor().clamp(0, 4);
            final b = (a + 1).clamp(0, 4);
            final t = f - a;
            Widget frame(int i, double o) => Opacity(
                  opacity: o.clamp(0.0, 1.0),
                  child: Image.asset('assets/img/girl_pray_${i + 1}.png',
                      width: 190, filterQuality: FilterQuality.medium),
                );
            return SizedBox(
              width: 190,
              height: 228,
              child: Stack(children: [frame(a, 1), if (b != a) frame(b, t)]),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(widget.text, style: h(16, color: AppColors.soft, w: FontWeight.w600)),
      ],
    );
  }
}
