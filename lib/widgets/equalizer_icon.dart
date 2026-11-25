import 'package:flutter/material.dart';

/// The three-slider icon from the design.
class EqualizerIcon extends StatelessWidget {
  const EqualizerIcon({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(size: Size.square(size), painter: _EqIconPainter(c));
  }
}

class _EqIconPainter extends CustomPainter {
  _EqIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color;
    for (final x in [6.0, 12.0, 18.0]) {
      canvas.drawLine(Offset(x * s, 4 * s), Offset(x * s, 20 * s), line);
    }
    canvas.drawCircle(Offset(6 * s, 9 * s), 2 * s, fill);
    canvas.drawCircle(Offset(12 * s, 15 * s), 2 * s, fill);
    canvas.drawCircle(Offset(18 * s, 7 * s), 2 * s, fill);
  }

  @override
  bool shouldRepaint(_EqIconPainter old) => old.color != color;
}
