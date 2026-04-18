import 'package:flutter/material.dart';

class ClipShadow extends StatelessWidget {
  final List<BoxShadow> boxShadow;
  final CustomClipper<Path> clipper;
  final Widget child;

  const ClipShadow({
    super.key,
    required this.boxShadow,
    required this.clipper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ClipShadowPainter(
        clipper: clipper,
        boxShadow: boxShadow,
      ),
      child: ClipPath(
        clipper: clipper,
        child: child,
      ),
    );
  }
}

class _ClipShadowPainter extends CustomPainter {
  final CustomClipper<Path> clipper;
  final List<BoxShadow> boxShadow;

  _ClipShadowPainter({
    required this.clipper,
    required this.boxShadow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    for (final shadow in boxShadow) {
      final paint = shadow.toPaint();
      final shift = shadow.offset;
      canvas.drawPath(path.shift(shift), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}



