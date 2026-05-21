
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class BottleComponent extends PositionComponent with TapCallbacks {
  final int index;
  List<Color> colors;
  bool isSelected = false;
  final Function(int) onTap;
  late Vector2 initialPosition;

  double waveTime = 0;
  bool isPouringWave = false;

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

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Do not add RectangleHitbox for tap here.
    // TapCallbacks uses containsPoint().
    // This way the visible bottle body and the touch area stay exactly same.

    // Turn true only if you want to see the real component box.
    debugMode = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    waveTime += dt * 4.0;
  }

  @override
  bool containsPoint(Vector2 point) {
    // This fixes your half-touch issue.
    // Bottle is now drawn from 0,0 to width,height.
    // So the touch area is the same full bottle rectangle.
    final localPoint = absoluteToLocal(point);

    final rect = Rect.fromLTWH(
      0,
      0,
      width,
      height,
    );

    return rect.contains(localPoint.toOffset());
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap(index);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue.shade400 : Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;

    final rect = Rect.fromLTWH(0, 0, width, height);

    final bottleRRect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: const Radius.circular(borderRadius),
      bottomRight: const Radius.circular(borderRadius),
      topLeft: const Radius.circular(7),
      topRight: const Radius.circular(7),
    );

    // Glass body
    canvas.drawRRect(bottleRRect, glassPaint);

    // Liquid layers
    final double innerLeft = 4;
    final double innerWidth = width - 8;
    final double bottomY = height - 8;
    final double layerHeight = (height - 16) / maxCapacity;

    for (int i = 0; i < colors.length; i++) {
      final double topY = bottomY - (i + 1) * layerHeight;
      final double liquidBottomY = bottomY - i * layerHeight;

      final colorPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors[i].withOpacity(0.78),
            colors[i],
          ],
        ).createShader(
          Rect.fromLTWH(innerLeft, topY, innerWidth, layerHeight),
        );

      final path = Path();

      final bool isTopLayer = i == colors.length - 1;

      if (isTopLayer) {
        final double wavePower = isPouringWave ? 5.5 : 2.0;
        final double wave1 = sin(waveTime) * wavePower;
        final double wave2 = sin(waveTime + 1.8) * wavePower;

        path.moveTo(innerLeft, topY + wave1);
        path.quadraticBezierTo(
          innerLeft + innerWidth * 0.5,
          topY - wavePower,
          innerLeft + innerWidth,
          topY + wave2,
        );
        path.lineTo(innerLeft + innerWidth, liquidBottomY);
        path.lineTo(innerLeft, liquidBottomY);
        path.close();
      } else {
        path.addRect(
          Rect.fromLTWH(
            innerLeft,
            topY,
            innerWidth,
            layerHeight - 1,
          ),
        );
      }

      canvas.drawPath(path, colorPaint);
    }

    // Bottom rounded liquid mask feel
    if (colors.isNotEmpty) {
      final bottomColorPaint = Paint()..color = colors.first;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            innerLeft,
            bottomY - layerHeight,
            innerWidth,
            layerHeight,
          ),
          bottomLeft: const Radius.circular(borderRadius - 5),
          bottomRight: const Radius.circular(borderRadius - 5),
        ),
        bottomColorPaint,
      );
    }

    // Glass highlight
    final shinePaint = Paint()..color = Colors.white.withOpacity(0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 14, 4, height - 35),
        const Radius.circular(4),
      ),
      shinePaint,
    );

    // Border and top rim
    canvas.drawRRect(bottleRRect, borderPaint);
    canvas.drawOval(
      Rect.fromLTWH(-2, -4, width + 4, 9),
      borderPaint,
    );
  }
}

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
    time += dt * 10;
  }

  @override
  void render(Canvas canvas) {
    final diff = target - position;

    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(0, 0);

    final waveOffset = sin(time) * 8;

    path.quadraticBezierTo(
      diff.x * 0.45 + waveOffset,
      diff.y * -0.12,
      diff.x,
      diff.y,
    );

    canvas.drawPath(path, paint);

    final dropPaint = Paint()
      ..color = color.withOpacity(0.75)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(diff.x * 0.5 + sin(time) * 5, diff.y * 0.45),
      3,
      dropPaint,
    );

    canvas.drawCircle(
      Offset(diff.x * 0.75 + cos(time) * 4, diff.y * 0.7),
      2,
      dropPaint,
    );
  }
}

class WaterSortGame extends FlameGame {
  final int level;
  final Function(int) onMoveUpdate;
  final VoidCallback onWin;

  late List<List<Color>> bottlesData;
  List<BottleComponent> bottleComponents = [];

  int? selectedIndex;
  bool _isAnimating = false;

  WaterSortGame({
    required this.level,
    required this.onMoveUpdate,
    required this.onWin,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeGameData();
    _createBottleComponents();
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

    // 8 bottles: 6 filled color bottles, 2 empty bottles
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

  void _handleBottleTap(int index) {
    if (_isAnimating) return;

    if (selectedIndex == null) {
      if (bottlesData[index].isNotEmpty) {
        _isAnimating = true;
        selectedIndex = index;

        final bottle = bottleComponents[index];
        bottle.isSelected = true;

        bottle.add(
          MoveEffect.to(
            bottle.initialPosition - Vector2(0, 25),
            EffectController(duration: 0.15, curve: Curves.easeOut),
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
        if (_isValidMove(selectedIndex!, index)) {
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
        EffectController(duration: 0.2, curve: Curves.easeInOut),
        onComplete: () {
          selectedIndex = null;
          _isAnimating = false;
        },
      ),
    );
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

    final double liftY = min(
          fromBottle.initialPosition.y,
          toBottle.initialPosition.y,
        ) -
        BottleComponent.bottleHeight * 0.7;

    fromBottle.add(
      MoveEffect.to(
        Vector2(fromBottle.position.x, liftY),
        EffectController(duration: 0.2, curve: Curves.easeOut),
        onComplete: () {
          fromBottle.add(
            MoveEffect.to(
              toBottle.position +
                  Vector2(
                    BottleComponent.bottleWidth * 0.80,
                    -BottleComponent.bottleHeight * 0.72,
                  ),
              EffectController(duration: 0.3, curve: Curves.easeInOut),
              onComplete: () {
                fromBottle.add(
                  RotateEffect.to(
                    -1.55,
                    EffectController(duration: 0.35, curve: Curves.easeInOut),
                    onComplete: () async {
                      fromBottle.isPouringWave = true;
                      toBottle.isPouringWave = true;

                      final stream = WaterStreamComponent(
                        color: colorToPour,
                        position: fromBottle.centerPosition +
                            Vector2(
                              -BottleComponent.bottleWidth * 0.45,
                              -BottleComponent.bottleHeight * 0.38,
                            ),
                        target: toBottle.centerPosition +
                            Vector2(
                              0,
                              -BottleComponent.bottleHeight * 0.47,
                            ),
                      );

                      add(stream);

                      for (int i = 0; i < pourAmount; i++) {
                        await Future.delayed(
                          const Duration(milliseconds: 220),
                        );

                        if (bottlesData[from].isNotEmpty) {
                          bottlesData[to].add(bottlesData[from].removeLast());
                        }
                      }

                      await Future.delayed(
                        const Duration(milliseconds: 120),
                      );

                      onMoveUpdate(1);
                      remove(stream);

                      fromBottle.isPouringWave = false;
                      toBottle.isPouringWave = false;

                      fromBottle.add(
                        RotateEffect.to(
                          0,
                          EffectController(
                            duration: 0.3,
                            curve: Curves.easeInOut,
                          ),
                          onComplete: () {
                            fromBottle.add(
                              MoveEffect.to(
                                Vector2(fromBottle.initialPosition.x, liftY),
                                EffectController(duration: 0.2),
                                onComplete: () {
                                  fromBottle.add(
                                    MoveEffect.to(
                                      fromBottle.initialPosition,
                                      EffectController(
                                        duration: 0.2,
                                        curve: Curves.easeIn,
                                      ),
                                      onComplete: () {
                                        fromBottle.isSelected = false;
                                        selectedIndex = null;
                                        _isAnimating = false;

                                        if (_checkWin()) {
                                          onWin();
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
