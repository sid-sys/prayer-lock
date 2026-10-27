import 'dart:async';
import 'package:flutter/material.dart';

/// The little girl as a flip-book. Frames are assets/img/girl_<kind>_1..N.png:
/// kind 'pray' (praying), 'read' (reading the Bible), 'joy' (celebrating).
/// Frames are cut from the same sheet cell size, so they line up when played.
class GirlAnim extends StatefulWidget {
  final String kind;
  final int frames;
  final double size;
  final int ms; // time per frame
  final bool pingPong; // forward then back (for loops like praying)
  const GirlAnim({
    super.key,
    this.kind = 'pray',
    this.frames = 6,
    this.size = 190,
    this.ms = 170,
    this.pingPong = true,
  });

  @override
  State<GirlAnim> createState() => _GirlAnimState();
}

class _GirlAnimState extends State<GirlAnim> {
  Timer? _t;
  int _step = 0;

  late final List<int> _seq = [
    for (var i = 0; i < widget.frames; i++) i,
    if (widget.pingPong) for (var i = widget.frames - 2; i >= 1; i--) i,
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(Duration(milliseconds: widget.ms), (_) {
      if (mounted) setState(() => _step = (_step + 1) % _seq.length);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var i = 1; i <= widget.frames; i++) {
      precacheImage(AssetImage('assets/img/girl_${widget.kind}_$i.png'), context);
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/img/girl_${widget.kind}_${_seq[_step] + 1}.png',
        width: widget.size,
        height: widget.size * 329 / 244,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      );
}
