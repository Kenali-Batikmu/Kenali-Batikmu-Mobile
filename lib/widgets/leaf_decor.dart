import 'package:flutter/material.dart';

class LeafDecor extends StatelessWidget {
  final String asset;
  final double size;
  final double angle;
  final double opacity;

  const LeafDecor({
    super.key,
    required this.asset,
    this.size = 90,
    this.angle = 0,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );

    if (opacity < 1.0) {
      image = Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: image,
      );
    }

    if (angle != 0) {
      image = Transform.rotate(
        angle: angle,
        child: image,
      );
    }

    return IgnorePointer(
      child: image,
    );
  }
}
