import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Sparkle particle for the bottle-sorted celebration
// ---------------------------------------------------------------------------
class SparkleParticle extends PositionComponent {
  final Color color;
  final double sparkleAngle;
  final double speed;
  double _life = 1.0;
  final double _size;

  SparkleParticle({
    required this.color,
    required this.sparkleAngle,
    required this.speed,
    required Vector2 position,
    double size = 5.0,
  })  : _size = size,
        super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt * 1.8;
    position.x += cos(sparkleAngle) * speed * dt;
    position.y += sin(sparkleAngle) * speed * dt + 60 * dt; // gravity
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_life <= 0) return;
    final paint = Paint()
      ..color = color.withOpacity(_life.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    // Draw a small star/diamond shape
    final s = _size * _life;
    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.35, -s * 0.35)
      ..lineTo(s, 0)
      ..lineTo(s * 0.35, s * 0.35)
      ..lineTo(0, s)
      ..lineTo(-s * 0.35, s * 0.35)
      ..lineTo(-s, 0)
      ..lineTo(-s * 0.35, -s * 0.35)
      ..close();
    canvas.drawPath(path, paint);
  }
}

// ---------------------------------------------------------------------------
// Celebration burst: spawns sparkles around a bottle mouth
// ---------------------------------------------------------------------------
class CelebrationBurst extends PositionComponent {
  final Color bottleColor;
  final _rng = Random();

  CelebrationBurst({
    required this.bottleColor,
    required Vector2 position,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnParticles();
  }

  void _spawnParticles() {
    const int count = 22;
    final List<Color> palette = [
      bottleColor,
      Colors.white,
      Colors.yellow.shade300,
      Colors.amber,
      bottleColor.withOpacity(0.7),
    ];

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i + _rng.nextDouble() * 0.4;
      final speed = 60.0 + _rng.nextDouble() * 90.0;
      final color = palette[_rng.nextInt(palette.length)];
      final size = 3.5 + _rng.nextDouble() * 4.0;

      add(SparkleParticle(
        color: color,
        sparkleAngle: angle,
        speed: speed,
        position: Vector2.zero(),
        size: size,
      ));
    }

    // Auto-remove this burst after all particles are gone (~0.7 s)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (isMounted) removeFromParent();
    });
  }
}

// ---------------------------------------------------------------------------
// BottleComponent
// ---------------------------------------------------------------------------
class BottleComponent extends PositionComponent with TapCallbacks {
  final int index;
  List<Color> colors;
  bool isSelected = false;
  final Function(int) onTap;
  late Vector2 initialPosition;

  double waveTime = 0;
  bool isPouringWave = false;

  // Celebration state
  bool _isCelebrating = false;
  double _celebrateTime = 0;

  static const double bottleWidth = 58;
  static const double bottleHeight = 145;
  static const int maxCapacity = 4;
  static const double borderRadius = 22;

  BottleComponent({
    required this.index,
    required this.colors,
    required this.onTap,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(bottleWidth, bottleHeight),
          anchor: Anchor.topLeft,
        ) {
    initialPosition = position.clone();
  }

  Vector2 get centerPosition => position + size / 2;
  Vector2 get mouthCenter => position + Vector2(width / 2, 0);

  /// Trigger the bounce + glow celebration animation
  void celebrate() {
    if (_isCelebrating) return;
    _isCelebrating = true;
    _celebrateTime = 0;

    // Bounce sequence: up → down → up → settle
    add(
      MoveEffect.by(
        Vector2(0, -18),
        EffectController(duration: 0.18, curve: Curves.easeOut),
        onComplete: () {
          add(
            MoveEffect.by(
              Vector2(0, 18),
              EffectController(duration: 0.14, curve: Curves.easeIn),
              onComplete: () {
                add(
                  MoveEffect.by(
                    Vector2(0, -10),
                    EffectController(duration: 0.12, curve: Curves.easeOut),
                    onComplete: () {
                      add(
                        MoveEffect.by(
                          Vector2(0, 10),
                          EffectController(
                              duration: 0.10, curve: Curves.easeIn),
                          onComplete: () {
                            _isCelebrating = false;
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    debugMode = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    waveTime += dt * 4.0;
    if (_isCelebrating) _celebrateTime += dt;
  }

  @override
  bool containsPoint(Vector2 point) {
    final localPoint = absoluteToLocal(point);
    final rect = Rect.fromLTWH(0, 0, width, height);
    return rect.contains(localPoint.toOffset());
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap(index);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Celebration glow overlay
    if (_isCelebrating) {
      final glowAlpha = (sin(_celebrateTime * 12) * 0.5 + 0.5) * 0.35;
      final glowPaint = Paint()
        ..color = (colors.isNotEmpty ? colors.last : Colors.white)
            .withOpacity(glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          const Radius.circular(22),
        ),
        glowPaint,
      );
    }

    final glassFillPaint = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.fill;

    final glassBorderPaint = Paint()
      ..color = _isCelebrating
          ? Colors.amber.shade300
          : isSelected
              ? Colors.blue.shade400
              : Colors.white.withOpacity(0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isCelebrating ? 2.8 : isSelected ? 2.8 : 1.9
      ..strokeCap = StrokeCap.round;

    final sideHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.fill;

    final sideShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final double bodyLeft = 4;
    final double bodyTop = 8;
    final double bodyRight = width - 4;
    final double bodyBottom = height;
    final double bodyWidth = bodyRight - bodyLeft;
    final double bottomCurveHeight = 36;

    final tubeFillPath = Path()
      ..moveTo(bodyLeft, bodyTop)
      ..lineTo(bodyLeft, bodyBottom - bottomCurveHeight)
      ..quadraticBezierTo(bodyLeft, bodyBottom, width / 2, bodyBottom)
      ..quadraticBezierTo(
          bodyRight, bodyBottom, bodyRight, bodyBottom - bottomCurveHeight)
      ..lineTo(bodyRight, bodyTop)
      ..close();

    final double innerLeft = 7;
    final double innerTop = 15;
    final double innerRight = width - 7;
    final double innerBottom = height - 2;
    final double innerBottomCurveHeight = 31;
    final double innerWidth = innerRight - innerLeft;
    final double innerHeight = innerBottom - innerTop;

    final innerLiquidPath = Path()
      ..moveTo(innerLeft, innerTop)
      ..lineTo(innerLeft, innerBottom - innerBottomCurveHeight)
      ..quadraticBezierTo(innerLeft, innerBottom, width / 2, innerBottom)
      ..quadraticBezierTo(
          innerRight, innerBottom, innerRight, innerBottom - innerBottomCurveHeight)
      ..lineTo(innerRight, innerTop)
      ..close();

    canvas.drawPath(tubeFillPath, glassFillPaint);

    canvas.save();
    canvas.clipPath(innerLiquidPath);

    final double liquidBottomY = innerBottom + 1;
    final double layerHeight = innerHeight / maxCapacity;

    for (int i = 0; i < colors.length; i++) {
      final double topY = liquidBottomY - (i + 1) * layerHeight;
      final double bottomY = liquidBottomY - i * layerHeight;

      final colorPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors[i].withOpacity(0.84),
            colors[i],
          ],
        ).createShader(
          Rect.fromLTWH(innerLeft, topY, innerWidth, layerHeight),
        );

      final bool isTopLayer = i == colors.length - 1;
      final path = Path();

      if (isTopLayer) {
        final double wavePower = isPouringWave ? 6.0 : 2.0;
        final double wave1 = sin(waveTime) * wavePower;
        final double wave2 = sin(waveTime + 1.8) * wavePower;

        path.moveTo(innerLeft, topY + wave1);
        path.quadraticBezierTo(
          innerLeft + innerWidth * 0.50,
          topY - wavePower,
          innerRight,
          topY + wave2,
        );
        path.lineTo(innerRight, bottomY + 2);
        path.lineTo(innerLeft, bottomY + 2);
        path.close();
      } else {
        path.addRect(
          Rect.fromLTWH(innerLeft, topY, innerWidth, layerHeight + 2),
        );
      }

      canvas.drawPath(path, colorPaint);
    }

    if (colors.isNotEmpty) {
      final bottomDepthPaint = Paint()
        ..color = colors.first.withOpacity(0.24)
        ..style = PaintingStyle.fill;

      canvas.drawOval(
        Rect.fromLTWH(innerLeft + 3, height - 29, innerWidth - 6, 23),
        bottomDepthPaint,
      );
    }

    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(11, 27, 4, height - 52),
        const Radius.circular(4),
      ),
      sideHighlightPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width - 10, 27, 2.5, height - 52),
        const Radius.circular(4),
      ),
      sideShadowPaint,
    );

    final borderPath = Path()
      ..moveTo(bodyLeft, bodyTop + 3)
      ..lineTo(bodyLeft, bodyBottom - bottomCurveHeight)
      ..quadraticBezierTo(bodyLeft, bodyBottom, width / 2, bodyBottom)
      ..quadraticBezierTo(
          bodyRight, bodyBottom, bodyRight, bodyBottom - bottomCurveHeight)
      ..lineTo(bodyRight, bodyTop + 3);

    canvas.drawPath(borderPath, glassBorderPaint);

    final mouthOuterRect =
        Rect.fromLTWH(bodyLeft, bodyTop - 6, bodyWidth, 13);
    final mouthInnerRect =
        Rect.fromLTWH(bodyLeft + 5, bodyTop - 3, bodyWidth - 10, 7);

    final mouthInnerPaint = Paint()
      ..color = Colors.black.withOpacity(0.30)
      ..style = PaintingStyle.fill;

    final mouthBorderPaint = Paint()
      ..color = _isCelebrating
          ? Colors.amber.shade300
          : isSelected
              ? Colors.blue.shade400
              : Colors.white.withOpacity(0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isCelebrating ? 2.5 : isSelected ? 2.5 : 1.7;

    final mouthShinePaint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(mouthInnerRect, mouthInnerPaint);
    canvas.drawOval(mouthOuterRect, mouthBorderPaint);

    canvas.drawArc(
      Rect.fromLTWH(bodyLeft + 4, bodyTop - 5, bodyWidth - 8, 11),
      pi * 1.03,
      pi * 0.42,
      false,
      mouthShinePaint,
    );

    final bottomShinePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(9, height - 32, width - 18, 28),
      0.18,
      pi - 0.36,
      false,
      bottomShinePaint,
    );
  }
}

// ---------------------------------------------------------------------------
// WaterStreamComponent
// ---------------------------------------------------------------------------
class WaterStreamComponent extends PositionComponent {
  final Color color;
  final Vector2 target;
  double time = 0;

  WaterStreamComponent({
    required this.color,
    required Vector2 position,
    required this.target,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    time += dt * 8;
  }

  @override
  void render(Canvas canvas) {
    final diff = target - position;

    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(0, 0);
    final waveOffset = sin(time) * 3;

    path.quadraticBezierTo(
      diff.x * 0.45 + waveOffset,
      diff.y * -0.08,
      diff.x,
      diff.y,
    );

    canvas.drawPath(path, paint);

    final dropPaint = Paint()
      ..color = color.withOpacity(0.70)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(diff.x * 0.52 + sin(time) * 3, diff.y * 0.45),
      2.8,
      dropPaint,
    );

    canvas.drawCircle(
      Offset(diff.x * 0.77 + cos(time) * 3, diff.y * 0.72),
      2,
      dropPaint,
    );
  }
}

// ---------------------------------------------------------------------------
// WaterSortGame
// ---------------------------------------------------------------------------
class WaterSortGame extends FlameGame {
  final int level;
  final Function(int) onMoveUpdate;
  final VoidCallback onWin;

  late List<List<Color>> bottlesData;
  List<BottleComponent> bottleComponents = [];

  int? selectedIndex;
  bool _isAnimating = false;

  // Audio player for water pour sound
  final AudioPlayer _audioPlayer = AudioPlayer();

  WaterSortGame({
    required this.level,
    required this.onMoveUpdate,
    required this.onWin,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Pre-load the audio so first play has no delay
    await _audioPlayer.setSource(AssetSource('audio/water_sound.mp3'));
    _initializeGameData();
    _createBottleComponents();
  }

  @override
  void onRemove() {
    _audioPlayer.dispose();
    super.onRemove();
  }

  Future<void> _playWaterSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/water_sound.mp3'));
    } catch (_) {
      // Silently ignore audio errors so gameplay is not interrupted
    }
  }

  void _initializeGameData() {
    final List<Color> palette = [
      Colors.red.shade600,
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.yellow.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
    ];

    const int numColors = 6;
    final List<Color> gameColors = palette.sublist(0, numColors);

    final List<Color> allColors = [];
    for (final color in gameColors) {
      for (int i = 0; i < BottleComponent.maxCapacity; i++) {
        allColors.add(color);
      }
    }

    allColors.shuffle();

    bottlesData = List.generate(8, (i) => []);

    for (int i = 0; i < numColors; i++) {
      bottlesData[i] = allColors.sublist(
        i * BottleComponent.maxCapacity,
        (i + 1) * BottleComponent.maxCapacity,
      );
    }
  }

  void _createBottleComponents() {
    const double spacingX = 38;
    const double spacingY = 50;

    final layout = [3, 3, 2];
    int bottleIdx = 0;

    double currentCenterY = BottleComponent.bottleHeight / 2 + 50;

    for (final rowSize in layout) {
      final double rowWidth =
          (rowSize * BottleComponent.bottleWidth) + ((rowSize - 1) * spacingX);

      double currentCenterX =
          (size.x - rowWidth) / 2 + BottleComponent.bottleWidth / 2;

      for (int i = 0; i < rowSize; i++) {
        final topLeftPosition = Vector2(
          currentCenterX - BottleComponent.bottleWidth / 2,
          currentCenterY - BottleComponent.bottleHeight / 2,
        );

        final bottle = BottleComponent(
          index: bottleIdx,
          colors: bottlesData[bottleIdx],
          position: topLeftPosition,
          onTap: _handleBottleTap,
        );

        bottleComponents.add(bottle);
        add(bottle);

        currentCenterX += BottleComponent.bottleWidth + spacingX;
        bottleIdx++;
      }

      currentCenterY += BottleComponent.bottleHeight + spacingY;
    }
  }

  bool _isCompletedBottle(int index) {
    final bottle = bottlesData[index];
    return bottle.length == BottleComponent.maxCapacity &&
        bottle.every((color) => color == bottle.first);
  }

  void _handleBottleTap(int index) {
    if (_isAnimating) return;

    if (_isCompletedBottle(index)) return;

    if (selectedIndex == null) {
      if (bottlesData[index].isNotEmpty) {
        _isAnimating = true;
        selectedIndex = index;

        final bottle = bottleComponents[index];
        bottle.isSelected = true;

        bottle.add(
          MoveEffect.to(
            bottle.initialPosition - Vector2(0, 25),
            EffectController(duration: 0.20, curve: Curves.easeOut),
            onComplete: () {
              _isAnimating = false;
            },
          ),
        );
      }
    } else {
      if (selectedIndex == index) {
        _deselect();
      } else {
        if (_isCompletedBottle(selectedIndex!) || _isCompletedBottle(index)) {
          _deselect();
        } else if (_isValidMove(selectedIndex!, index)) {
          _tryPour(selectedIndex!, index);
        } else {
          _deselect();
        }
      }
    }
  }

  bool _isValidMove(int from, int to) {
    if (bottlesData[from].isEmpty) return false;
    if (bottlesData[to].length >= BottleComponent.maxCapacity) return false;

    if (bottlesData[to].isNotEmpty &&
        bottlesData[to].last != bottlesData[from].last) {
      return false;
    }

    return true;
  }

  void _deselect() {
    if (selectedIndex == null) return;

    _isAnimating = true;

    final bottle = bottleComponents[selectedIndex!];
    bottle.isSelected = false;

    bottle.add(
      MoveEffect.to(
        bottle.initialPosition,
        EffectController(duration: 0.22, curve: Curves.easeInOut),
        onComplete: () {
          selectedIndex = null;
          _isAnimating = false;
        },
      ),
    );
  }

  /// Trigger celebration for a bottle that just became fully sorted
  void _celebrateBottle(int index) {
    final bottle = bottleComponents[index];
    bottle.celebrate();

    // Spawn sparkle burst at the bottle mouth
    final burstPosition = bottle.initialPosition + Vector2(BottleComponent.bottleWidth / 2, 0);
    final burst = CelebrationBurst(
      bottleColor: bottlesData[index].first,
      position: burstPosition,
    );
    add(burst);
  }

  Future<void> _tryPour(int from, int to) async {
    final Color colorToPour = bottlesData[from].last;

    int pourAmount = 0;

    for (int i = bottlesData[from].length - 1; i >= 0; i--) {
      if (bottlesData[from][i] == colorToPour &&
          (bottlesData[to].length + pourAmount) < BottleComponent.maxCapacity) {
        pourAmount++;
      } else {
        break;
      }
    }

    _isAnimating = true;

    final fromBottle = bottleComponents[from];
    final toBottle = bottleComponents[to];

    const double pourDirection = 1.0;

    final double liftY = min(
          fromBottle.initialPosition.y,
          toBottle.initialPosition.y,
        ) -
        BottleComponent.bottleHeight * 0.72;

    fromBottle.add(
      MoveEffect.to(
        Vector2(fromBottle.position.x, liftY),
        EffectController(duration: 0.35, curve: Curves.easeOutCubic),
        onComplete: () {
          final Vector2 closePourPosition =
              toBottle.mouthCenter + Vector2(-6, -18);

          fromBottle.add(
            MoveEffect.to(
              closePourPosition,
              EffectController(duration: 0.60, curve: Curves.easeInOutCubic),
              onComplete: () {
                fromBottle.add(
                  RotateEffect.to(
                    -pourDirection * 1.28,
                    EffectController(
                      duration: 0.60,
                      curve: Curves.easeInOutCubic,
                    ),
                    onComplete: () async {
                      fromBottle.isPouringWave = true;
                      toBottle.isPouringWave = true;

                      final streamStart =
                          fromBottle.position + Vector2(3, 4);
                      final streamTarget =
                          toBottle.mouthCenter + Vector2(0, 7);

                      final stream = WaterStreamComponent(
                        color: colorToPour,
                        position: streamStart,
                        target: streamTarget,
                      );

                      add(stream);

                      // ---- Play water sound as soon as stream starts ----
                      _playWaterSound();

                      // Slow liquid transfer
                      for (int i = 0; i < pourAmount; i++) {
                        await Future.delayed(
                          const Duration(milliseconds: 420),
                        );

                        if (bottlesData[from].isNotEmpty) {
                          bottlesData[to].add(bottlesData[from].removeLast());
                        }
                      }

                      await Future.delayed(
                        const Duration(milliseconds: 220),
                      );

                      onMoveUpdate(1);
                      remove(stream);

                      fromBottle.isPouringWave = false;
                      toBottle.isPouringWave = false;

                      fromBottle.add(
                        RotateEffect.to(
                          0,
                          EffectController(
                            duration: 0.45,
                            curve: Curves.easeInOutCubic,
                          ),
                          onComplete: () {
                            fromBottle.add(
                              MoveEffect.to(
                                Vector2(fromBottle.initialPosition.x, liftY),
                                EffectController(
                                  duration: 0.35,
                                  curve: Curves.easeInOutCubic,
                                ),
                                onComplete: () {
                                  fromBottle.add(
                                    MoveEffect.to(
                                      fromBottle.initialPosition,
                                      EffectController(
                                        duration: 0.35,
                                        curve: Curves.easeInCubic,
                                      ),
                                      onComplete: () {
                                        fromBottle.isSelected = false;
                                        selectedIndex = null;
                                        _isAnimating = false;

                                        // ---- Check if destination bottle is now sorted ----
                                        if (_isCompletedBottle(to)) {
                                          _celebrateBottle(to);
                                        }
                                        // Also check source bottle (edge case: it emptied perfectly)
                                        if (bottlesData[from].isEmpty ||
                                            _isCompletedBottle(from)) {
                                          if (_isCompletedBottle(from)) {
                                            _celebrateBottle(from);
                                          }
                                        }

                                        if (_checkWin()) {
                                          // Small delay so celebration plays before dialog
                                          Future.delayed(
                                            const Duration(milliseconds: 700),
                                            onWin,
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _checkWin() {
    return bottlesData.every(
      (bottle) =>
          bottle.isEmpty ||
          (bottle.length == BottleComponent.maxCapacity &&
              bottle.every((color) => color == bottle[0])),
    );
  }

  void reset() {
    removeAll(bottleComponents);
    bottleComponents.clear();

    _initializeGameData();
    _createBottleComponents();

    selectedIndex = null;
    _isAnimating = false;
  }
}

// ---------------------------------------------------------------------------
// GameScreen widget
// ---------------------------------------------------------------------------
class GameScreen extends StatefulWidget {
  final int level;

  const GameScreen({
    super.key,
    required this.level,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late WaterSortGame _game;
  int _moveCount = 0;

  @override
  void initState() {
    super.initState();

    _game = WaterSortGame(
      level: widget.level,
      onMoveUpdate: (count) {
        setState(() {
          _moveCount += count;
        });
      },
      onWin: _showSuccessDialog,
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 48,
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
              Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You completed Level ${widget.level}!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Moves: $_moveCount',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Level ${widget.level}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _moveCount = 0;
                _game.reset();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GameWidget(game: _game),
            ),
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Powered By ',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const TextSpan(
                      text: 'Kingkar',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
