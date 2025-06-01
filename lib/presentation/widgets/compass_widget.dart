import 'package:flutter/material.dart';
import 'dart:math' as math;

class CompassWidget extends StatelessWidget {
  final double direction;
  final double qiblaDirection;

  const CompassWidget({
    Key? key,
    required this.direction,
    required this.qiblaDirection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rrethi i jashtëm i busullës
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          // Gradët e busullës
          Transform.rotate(
            angle: -direction * (math.pi / 180),
            child: CustomPaint(
              size: const Size(280, 280),
              painter: CompassPainter(),
            ),
          ),

          // Qendra e busullës
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 4,
              ),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Shigjetë e veriut
          Transform.rotate(
            angle: -direction * (math.pi / 180),
            child: Container(
              width: 2,
              height: 120,
              color: Colors.red,
              margin: const EdgeInsets.only(bottom: 120),
            ),
          ),

          // Shigjetë e jugut
          Transform.rotate(
            angle: -direction * (math.pi / 180),
            child: Container(
              width: 2,
              height: 110,
              color: Colors.grey,
              margin: const EdgeInsets.only(top: 130),
            ),
          ),

          // Shigjeta e Kibles
          Transform.rotate(
            angle: (qiblaDirection - direction) * (math.pi / 180),
            child: Container(
              margin: const EdgeInsets.only(bottom: 140),
              child: Icon(
                Icons.arrow_upward,
                size: 40,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),

          // Drejtimi i Kibles me tekst
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${qiblaDirection.toStringAsFixed(1)}°',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Vizato rrathët
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.8, paint);

    // Vizato vijat e gradëve
    for (int i = 0; i < 360; i += 15) {
      final angle = i * math.pi / 180;
      final outerPoint = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );

      final innerPoint = i % 45 == 0
          ? Offset(
              center.dx + radius * 0.7 * math.sin(angle),
              center.dy - radius * 0.7 * math.cos(angle),
            )
          : Offset(
              center.dx + radius * 0.75 * math.sin(angle),
              center.dy - radius * 0.75 * math.cos(angle),
            );

      final degreePaint = Paint()
        ..color = i % 90 == 0 ? Colors.black.withOpacity(0.8) : Colors.black.withOpacity(0.3)
        ..strokeWidth = i % 90 == 0 ? 2 : 1;

      canvas.drawLine(innerPoint, outerPoint, degreePaint);
    }

    // Shkruaj N, E, S, W
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );

    _drawTextOnCanvas(canvas, 'N', center.dx, center.dy - radius * 0.6, textStyle);
    _drawTextOnCanvas(canvas, 'E', center.dx + radius * 0.6, center.dy, textStyle);
    _drawTextOnCanvas(canvas, 'S', center.dx, center.dy + radius * 0.6, textStyle);
    _drawTextOnCanvas(canvas, 'W', center.dx - radius * 0.6, center.dy, textStyle);

    // Shkruaj gradët kryesore
    const smallTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );

    for (int i = 0; i < 360; i += 45) {
      if (i % 90 != 0) {  // Skip the cardinal directions we already drew
        final angle = i * math.pi / 180;
        final textRadius = radius * 0.65;
        final textPoint = Offset(
          center.dx + textRadius * math.sin(angle),
          center.dy - textRadius * math.cos(angle),
        );

        _drawTextOnCanvas(canvas, '$i°', textPoint.dx, textPoint.dy, smallTextStyle);
      }
    }
  }

  void _drawTextOnCanvas(Canvas canvas, String text, double x, double y, TextStyle style) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
