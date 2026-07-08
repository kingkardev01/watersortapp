import 'dart:math';
import 'package:flutter/material.dart';

/// Facial expression presets for [MascotDroplet], reused across the splash
/// screen and story intro so the same character reads as consistent while
/// still reacting to what's happening on screen.
enum MascotExpression { happy, excited, wink, sleepy, cheer }

/// "Drippy" — the app's droplet-shaped baby mascot. Drawn entirely in code
/// (no image assets) as a teardrop body with a big-eyed baby face, so it
/// stays on-theme with the water-sort game while being fully vector/code
/// driven. Bobs and blinks continuously to feel alive.
class MascotDroplet extends StatefulWidget {
  final double size;
  final MascotExpression expression;
  final Color color;

  const MascotDroplet({
    super.key,
    this.size = 140,
    this.expression = MascotExpression.happy,
    this.color = const Color(0xFF4F8CFF),
  });

  @override
  State<MascotDroplet> createState() => _MascotDropletState();
}

class _MascotDropletState extends State<MascotDroplet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double t = _controller.value * 2 * pi;
        final double bob = sin(t) * widget.size * 0.03;
        final double tilt = sin(t * 0.5) * 0.04;

        // Blink briefly once per loop rather than a continuous flutter.
        final double blinkPhase = _controller.value;
        final bool blinking = blinkPhase > 0.94 || blinkPhase < 0.985 &&
            blinkPhase > 0.965;

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: tilt,
            child: CustomPaint(
              size: Size(widget.size, widget.size * 1.15),
              painter: _MascotPainter(
                color: widget.color,
                expression: widget.expression,
                blinking: blinking && widget.expression != MascotExpression.sleepy,
                time: t,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  final Color color;
  final MascotExpression expression;
  final bool blinking;
  final double time;

  _MascotPainter({
    required this.color,
    required this.expression,
    required this.blinking,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h * 0.56);

    _drawGroundShadow(canvas, size);
    _drawBody(canvas, size);
    _drawArms(canvas, size);
    _drawFace(canvas, center, w);
  }

  void _drawGroundShadow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.98),
        width: size.width * 0.55,
        height: size.height * 0.07,
      ),
      paint,
    );
  }

  Path _bodyPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    // Classic teardrop: pointed top, round bottom.
    return Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..quadraticBezierTo(w * 0.94, h * 0.52, w * 0.94, h * 0.66)
      ..quadraticBezierTo(w * 0.94, h * 0.98, w * 0.5, h * 0.98)
      ..quadraticBezierTo(w * 0.06, h * 0.98, w * 0.06, h * 0.66)
      ..quadraticBezierTo(w * 0.06, h * 0.52, w * 0.5, h * 0.02)
      ..close();
  }

  void _drawBody(Canvas canvas, Size size) {
    final Path body = _bodyPath(size);

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.25)!,
          color,
          Color.lerp(color, Colors.black, 0.18)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(body, bodyPaint);

    // Soft rim light down the left edge, like the bottle glass rendering.
    canvas.save();
    canvas.clipPath(body);
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.white.withOpacity(0.35), Colors.white.withOpacity(0.0)],
        stops: const [0.0, 0.6],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, rimPaint);

    // Big glossy highlight, upper-left — gives the "cute plastic toy" shine.
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.36, size.height * 0.42),
        width: size.width * 0.22,
        height: size.height * 0.14,
      ),
      highlightPaint,
    );
    final smallHighlightPaint = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.55),
        width: size.width * 0.08,
        height: size.height * 0.05,
      ),
      smallHighlightPaint,
    );
    canvas.restore();

    final outlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.014;
    canvas.drawPath(body, outlinePaint);
  }

  void _drawArms(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final armPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    // Left arm: resting on hip.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.14, h * 0.78)
        ..quadraticBezierTo(w * 0.02, h * 0.72, w * 0.08, h * 0.6),
      armPaint,
    );

    // Right arm: waving for excited/cheer expressions, resting otherwise.
    final bool waving = expression == MascotExpression.excited ||
        expression == MascotExpression.cheer;
    final double waveLift = waving ? sin(time * 3) * h * 0.05 : 0;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.86, h * 0.78)
        ..quadraticBezierTo(
          w * 0.99,
          h * (0.6 + waveLift / h),
          w * 0.9,
          h * (0.42 + waveLift / h),
        ),
      armPaint,
    );
  }

  void _drawFace(Canvas canvas, Offset center, double w) {
    final double eyeOffsetX = w * 0.15;
    final double eyeY = center.dy - w * 0.02;
    final double eyeRadius = w * 0.085;

    for (final side in [-1.0, 1.0]) {
      final Offset eyeCenter = Offset(center.dx + side * eyeOffsetX, eyeY);

      if (blinking) {
        final blinkPaint = Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.02
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(eyeCenter.dx - eyeRadius * 0.7, eyeCenter.dy),
          Offset(eyeCenter.dx + eyeRadius * 0.7, eyeCenter.dy),
          blinkPaint,
        );
        continue;
      }

      final bool isWinkEye = expression == MascotExpression.wink && side < 0;
      if (isWinkEye) {
        final winkPaint = Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.018
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: eyeCenter,
            width: eyeRadius * 1.5,
            height: eyeRadius * 1.1,
          ),
          0.2,
          pi - 0.4,
          false,
          winkPaint,
        );
        continue;
      }

      final bool sleepy = expression == MascotExpression.sleepy;

      // White of the eye.
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawOval(
        Rect.fromCenter(
          center: eyeCenter,
          width: eyeRadius * (sleepy ? 1.5 : 1.7),
          height: eyeRadius * (sleepy ? 0.9 : 2.0),
        ),
        whitePaint,
      );

      if (sleepy) {
        final lidPaint = Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.016
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: eyeCenter.translate(0, -eyeRadius * 0.2),
            width: eyeRadius * 1.5,
            height: eyeRadius,
          ),
          0.15,
          pi - 0.3,
          false,
          lidPaint,
        );
      } else {
        // Big dark pupil, offset slightly up for a "baby" look, with a
        // tiny highlight dot so the eyes read as glossy, not flat.
        final pupilPaint = Paint()..color = const Color(0xFF2B2B3C);
        final Offset pupilCenter = eyeCenter.translate(0, eyeRadius * 0.15);
        canvas.drawCircle(pupilCenter, eyeRadius * 0.62, pupilPaint);
        final glintPaint = Paint()..color = Colors.white;
        canvas.drawCircle(
          pupilCenter.translate(-eyeRadius * 0.22, -eyeRadius * 0.28),
          eyeRadius * 0.18,
          glintPaint,
        );
      }
    }

    // Blush cheeks.
    final blushPaint = Paint()..color = Colors.pink.shade200.withOpacity(0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - w * 0.24, center.dy + w * 0.09),
        width: w * 0.13,
        height: w * 0.07,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + w * 0.24, center.dy + w * 0.09),
        width: w * 0.13,
        height: w * 0.07,
      ),
      blushPaint,
    );

    // Mouth.
    final mouthPaint = Paint()
      ..color = const Color(0xFF2B2B3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    final Offset mouthCenter = Offset(center.dx, center.dy + w * 0.16);

    switch (expression) {
      case MascotExpression.excited:
      case MascotExpression.cheer:
        final mouthFillPaint = Paint()..color = const Color(0xFFB33951);
        final path = Path()
          ..moveTo(mouthCenter.dx - w * 0.11, mouthCenter.dy)
          ..quadraticBezierTo(
            mouthCenter.dx,
            mouthCenter.dy + w * 0.11,
            mouthCenter.dx + w * 0.11,
            mouthCenter.dy,
          )
          ..quadraticBezierTo(
            mouthCenter.dx,
            mouthCenter.dy + w * 0.03,
            mouthCenter.dx - w * 0.11,
            mouthCenter.dy,
          )
          ..close();
        canvas.drawPath(path, mouthFillPaint);
        canvas.drawPath(path, mouthPaint);
        break;
      case MascotExpression.sleepy:
        canvas.drawOval(
          Rect.fromCenter(center: mouthCenter, width: w * 0.05, height: w * 0.03),
          mouthPaint,
        );
        break;
      case MascotExpression.happy:
      case MascotExpression.wink:
        canvas.drawArc(
          Rect.fromCenter(
            center: mouthCenter.translate(0, -w * 0.03),
            width: w * 0.2,
            height: w * 0.14,
          ),
          0.15,
          pi - 0.3,
          false,
          mouthPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.blinking != blinking ||
      oldDelegate.expression != expression ||
      oldDelegate.color != color;
}
