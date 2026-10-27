import 'package:flutter/material.dart';

/// One of the illustrations from assets/img/il_<name>.png, centred, with space under it.
class Illustration extends StatelessWidget {
  final String name;
  final double height;
  final double bottom;
  const Illustration(this.name, {super.key, this.height = 110, this.bottom = 12});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Center(
          child: Image.asset('assets/img/il_$name.png',
              height: height, fit: BoxFit.contain, filterQuality: FilterQuality.high),
        ),
      );
}
