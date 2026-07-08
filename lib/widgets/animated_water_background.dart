import 'dart:math';
import 'package:flutter/material.dart';

/// Soft drifting-bubble background used behind Splash/Home/Settings/Game
/// screens so the app reads as one cohesive "water" world instead of a
/// flat gradient fill on each screen.
class AnimatedWaterBackground extends StatefulWidget {
  final List<Color> gradientColors;
  final Color bubbleColor;
  final int bubbleCount;
  final double maxBubbleOpacity;
  final Widget? child;

  const AnimatedWaterBackground({
    super.key,
    required this.gradientColors,
    this.bubbleColor = Colors.white,
    this.bubbleCount = 16,
    this.maxBubbleOpacity = 0.16,
    this.child,
  });

  @override
  State<AnimatedWaterBackground> createState() =>
      _AnimatedWaterBackgroundState();
}

class _AnimatedWaterBackgroundState extends State<AnimatedWaterBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    // Long, slow loop — bubbles should feel ambient, not busy.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();

    final rng = Random(widget.bubbleCount * 97 + widget.gradientColors.length);
    _bubbles = List.generate(widget.bubbleCount, (_) {
      return _Bubble(
        dx: rng.nextDouble(),
        startDy: rng.nextDouble(),
        radius: 5 + rng.nextDouble() * 18,
        speed: 0.3 + rng.nextDouble() * 0.7,
        wobblePhase: rng.nextDouble() * pi * 2,
        wobbleAmount: 6 + rng.nextDouble() * 14,
        opacity: 0.35 + rng.nextDouble() * 0.65,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.gradientColors,
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _BubblesPainter(
                  bubbles: _bubbles,
                  progress: _controller.value,
                  color: widget.bubbleColor,
                  maxOpacity: widget.maxBubbleOpacity,
                ),
              );
            },
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Bubble {
  final double dx; // horizontal position, 0..1 of width
  final double startDy; // starting vertical phase, 0..1
  final double radius;
  final double speed; // loops per animation cycle
  final double wobblePhase;
  final double wobbleAmount;
  final double opacity;

  _Bubble({
    required this.dx,
    required this.startDy,
    required this.radius,
    required this.speed,
    required this.wobblePhase,
    required this.wobbleAmount,
    required this.opacity,
  });
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress;
  final Color color;
  final double maxOpacity;

  _BubblesPainter({
    required this.bubbles,
    required this.progress,
    required this.color,
    required this.maxOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      // Rises from bottom to top, wrapping around continuously so the
      // loop never visibly resets.
      final double raw = bubble.startDy - progress * bubble.speed;
      final double dy = raw - raw.floorToDouble();
      final double wobble =
          sin(progress * 2 * pi * bubble.speed + bubble.wobblePhase) *
              bubble.wobbleAmount;

      final double cx = bubble.dx * size.width + wobble;
      final double cy = dy * size.height;

      // Fade in/out near the top and bottom edges so bubbles don't pop
      // in or out abruptly.
      final double edgeFade = (dy < 0.08
              ? dy / 0.08
              : (dy > 0.92 ? (1 - dy) / 0.08 : 1.0))
          .clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(maxOpacity * bubble.opacity * edgeFade);
      canvas.drawCircle(Offset(cx, cy), bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
