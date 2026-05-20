import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class TestTubeWidget extends StatelessWidget {
  final int index;
  final List<Color> bottle;
  final int? selectedBottleIndex;
  final int? pouringTargetIndex;
  final List<List<Color>> bottles;
  final GlobalKey? key;
  final bool isCompleted;
  final bool isAnimating;
  final AnimationController completionAnimationController;
  final Color? pourAnimationColor;

  const TestTubeWidget({
    required this.index,
    required this.bottle,
    required this.selectedBottleIndex,
    required this.pouringTargetIndex,
    required this.bottles,
    this.key,
    required this.isCompleted,
    required this.isAnimating,
    required this.completionAnimationController,
    required this.pourAnimationColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 52,
      height: 202,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedBottleIndex == index ? Colors.blue.shade600 : (pouringTargetIndex == index ? Colors.green.shade600 : Colors.grey.shade300),
          width: selectedBottleIndex == index ? 4 : (pouringTargetIndex == index ? 3 : 2),
        ),
        boxShadow: [
          BoxShadow(
            color: selectedBottleIndex == index ? Colors.blue.shade300.withOpacity(0.6) : (pouringTargetIndex == index ? Colors.green.shade300.withOpacity(0.5) : Colors.grey.shade300.withOpacity(0.4)),
            blurRadius: selectedBottleIndex == index ? 14 : (pouringTargetIndex == index ? 12 : 8),
            offset: const Offset(0, 4),
            spreadRadius: selectedBottleIndex == index ? 3 : (pouringTargetIndex == index ? 2 : 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: bottle.isEmpty
                        ? Container()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5 - bottle.length,
                                child: Container(
                                  color: Colors.white,
                                ),
                              ),
                              for (int i = 0; i < bottle.length; i++)
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: bottle[i],
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          bottle[i].withOpacity(0.85),
                                          bottle[i].withOpacity(0.95),
                                        ],
                                      ),
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade300,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (selectedBottleIndex == index && bottle.isNotEmpty)
              Positioned(
                top: -38,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: selectedBottleIndex == index ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedScale(
                      scale: selectedBottleIndex == index ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: bottle.first,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: bottle.first.withOpacity(0.8),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.pan_tool_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (pouringTargetIndex == index)
              Positioned(
                top: -38,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: pouringTargetIndex == index ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedScale(
                      scale: pouringTargetIndex == index ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: pourAnimationColor ?? (selectedBottleIndex != null ? bottles[selectedBottleIndex!].first : Colors.grey),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (pourAnimationColor ?? (selectedBottleIndex != null ? bottles[selectedBottleIndex!].first : Colors.grey)).withOpacity(0.8),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.pan_tool_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (isAnimating)
              AnimatedBuilder(
                animation: completionAnimationController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: completionAnimationController.value * 2.2,
                          colors: [
                            Colors.yellow.withOpacity(0.9 * (1 - completionAnimationController.value)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: completionAnimationController.value,
                          child: Transform.scale(
                            scale: completionAnimationController.value,
                            child: Icon(
                              Icons.celebration_rounded,
                              color: Colors.white,
                              size: 55,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (isCompleted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        Colors.yellow.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 55,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final int level;

  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<List<Color>> bottles;
  int? selectedBottleIndex;
  int? pouringTargetIndex;
  final Random random = Random();
  late AnimationController _pourAnimationController;
  int? _pourFromIndex;
  int? _pourToIndex;
  Color? _pourAnimationColor;
  bool _isPouring = false;
  int _moveCount = 0;
  final Map<int, GlobalKey> _bottleKeys = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<int> _completedBottles = {};
  late AnimationController _completionAnimationController;
  int? _animatingCompletionIndex;

  @override
  void initState() {
    super.initState();
    _pourAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _completionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initializeGame();
    for (int i = 0; i < 10; i++) {
      _bottleKeys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _pourAnimationController.dispose();
    _completionAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeGame() {
    bottles = _generateGameState();
  }

  List<List<Color>> _generateGameState() {
    List<Color> colors = [
      Colors.red.shade600,
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.yellow.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.pink.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.amber.shade600,
    ];

    // Calculate number of colors based on level (more colors = harder)
    int numColors = 5 + (widget.level ~/ 10); // Every 10 levels add 1 more color
    if (numColors > 10) numColors = 10; // Max 10 colors

    List<Color> gameColors = colors.sublist(0, numColors);
    List<List<Color>> gameBottles = [];

    for (Color color in gameColors) {
      gameBottles.add([color, color, color, color, color]);
    }

    for (int i = 0; i < 5; i++) {
      gameBottles.add([]);
    }

    List<Color> allColors = [];
    for (int j = 0; j < numColors; j++) {
      allColors.addAll(gameBottles[j]);
    }

    allColors.shuffle(random);

    for (int j = 0; j < numColors; j++) {
      gameBottles[j] = allColors.sublist(j * 5, (j + 1) * 5);
    }

    gameBottles.shuffle(random);

    return gameBottles;
  }

  void _onBottleTap(int index) async {
    if (_isPouring) return;

    setState(() {
      if (selectedBottleIndex == null) {
        if (bottles[index].isNotEmpty) {
          selectedBottleIndex = index;
        }
      } else {
        if (selectedBottleIndex == index) {
          selectedBottleIndex = null;
          pouringTargetIndex = null;
        } else {
          pouringTargetIndex = index;
          _pourWaterWithAnimation(selectedBottleIndex!, index);
        }
      }
    });
  }

  Future<void> _pourWaterWithAnimation(int fromIndex, int toIndex) async {
    if (bottles[fromIndex].isEmpty || bottles[toIndex].length >= 5) {
      setState(() {
        selectedBottleIndex = null;
        pouringTargetIndex = null;
      });
      return;
    }

    List<Color> fromBottle = bottles[fromIndex];
    List<Color> toBottle = bottles[toIndex];

    Color bottomColor = fromBottle.first;

    if (toBottle.isEmpty || toBottle.last == bottomColor) {
      int sameColorCount = 0;
      for (int i = 0; i < fromBottle.length; i++) {
        if (fromBottle[i] == bottomColor) {
          sameColorCount++;
        } else {
          break;
        }
      }

      int pourCount = sameColorCount;
      if (toBottle.length + pourCount > 5) {
        pourCount = 5 - toBottle.length;
      }

      if (pourCount > 0 && sameColorCount > 0) {
        _pourFromIndex = fromIndex;
        _pourToIndex = toIndex;
        _pourAnimationColor = bottomColor;

        setState(() {
          _isPouring = true;
          selectedBottleIndex = null;
        });

        _audioPlayer.play(AssetSource('audio/water_sound.mp3'));

        await _pourAnimationController.forward(from: 0.0);

        for (int i = 0; i < pourCount; i++) {
          Color waterColor = fromBottle.removeAt(0);
          toBottle.add(waterColor);
        }

        await _pourAnimationController.reverse();

        // Increment move count
        setState(() {
          _moveCount++;
        });

        setState(() {
          _isPouring = false;
          _pourFromIndex = null;
          _pourToIndex = null;
          _pourAnimationColor = null;
          selectedBottleIndex = null;
          pouringTargetIndex = null;
        });

        setState(() {});

        for (int i = 0; i < bottles.length; i++) {
          if (bottles[i].length == 5 && bottles[i].every((color) => color == bottles[i][0])) {
            if (!_completedBottles.contains(i)) {
              _completedBottles.add(i);
              _animatingCompletionIndex = i;
              _completionAnimationController.forward(from: 0.0).then((_) {
                _animatingCompletionIndex = null;
              });
            }
          }
        }

        bool gameWon = _isGameWon();

        if (gameWon) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              _showSuccessDialog();
            }
          });
        }
      } else {
        setState(() {
          selectedBottleIndex = null;
        });
      }
    } else {
      setState(() {
        selectedBottleIndex = null;
      });
    }
  }

  bool _isGameWon() {
    int completedBottles = 0;

    for (var bottle in bottles) {
      if (bottle.isEmpty) continue;

      if (bottle.length == 5) {
        Color firstColor = bottle[0];
        bool allSameColor = true;

        for (var color in bottle) {
          if (color != firstColor) {
            allSameColor = false;
            break;
          }
        }

        if (allSameColor) {
          completedBottles++;
        }
      }
    }

    return completedBottles >= 5;
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
                  color: Colors.blue[800]!,
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
                  color: Colors.blue[700]!,
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
      appBar: AppBar(
        title: Text('Level ${widget.level}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                selectedBottleIndex = null;
                _isPouring = false;
                _pourFromIndex = null;
                _pourToIndex = null;
                _pourAnimationColor = null;
                _pourAnimationController.reset();
                _completedBottles.clear();
                _animatingCompletionIndex = null;
                _completionAnimationController.reset();
                selectedBottleIndex = null;
                pouringTargetIndex = null;
                _initializeGame();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Sort liquid colors into bottles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a bottle to select, then tap another to pour',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Show selected color indicator
                  if (selectedBottleIndex != null && bottles[selectedBottleIndex!].isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 33,
                          decoration: BoxDecoration(
                            color: bottles[selectedBottleIndex!].first,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: bottles[selectedBottleIndex!].last.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected: Top color will be poured',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  if (selectedBottleIndex == null)
                    Container(
                      padding: const EdgeInsets.only(top: 12.0),
                      height: 33,
                      color: Colors.transparent,
                    )
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: bottles.length <= 5 ? bottles.length : 5,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.5,
                    ),
                    itemCount: bottles.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _onBottleTap(index),
                        child: TestTubeWidget(
                          index: index,
                          bottle: bottles[index],
                          selectedBottleIndex: selectedBottleIndex,
                          pouringTargetIndex: pouringTargetIndex,
                          bottles: bottles,
                          key: _bottleKeys[index],
                          isCompleted: _completedBottles.contains(index),
                          isAnimating: _animatingCompletionIndex == index,
                          completionAnimationController: _completionAnimationController,
                          pourAnimationColor: _pourAnimationColor,
                        ),
                      );
                    },
                  ),
                  if (_isPouring && _pourFromIndex != null && _pourToIndex != null && _pourAnimationColor != null)
                    AnimatedBuilder(
                      animation: _pourAnimationController,
                      builder: (context, child) {
                        Offset? startPos;
                        Offset? endPos;

                        // Get positions from GlobalKeys
                        if (_bottleKeys[_pourFromIndex!]?.currentContext != null && _bottleKeys[_pourToIndex!]?.currentContext != null) {
                          final RenderBox? fromBox = _bottleKeys[_pourFromIndex!]!.currentContext!.findRenderObject() as RenderBox?;
                          final RenderBox? toBox = _bottleKeys[_pourToIndex!]!.currentContext!.findRenderObject() as RenderBox?;

                          if (fromBox != null && toBox != null) {
                            startPos = fromBox.localToGlobal(Offset.zero);
                            endPos = toBox.localToGlobal(Offset.zero);

                            // Adjust to position above the top center of bottles for pouring animation
                            startPos = Offset(
                              startPos.dx + fromBox.size.width / 2,
                              startPos.dy - 130, // Position above the bottle
                            );
                            endPos = Offset(
                              endPos.dx + toBox.size.width / 2,
                              endPos.dy - 130, // Position above the bottle
                            );
                          }
                        }

                        if (startPos == null || endPos == null) {
                          return const SizedBox.shrink();
                        }

                        final curvedValue = Curves.easeInOut.transform(_pourAnimationController.value);
                        // Calculate straight line path above the bottles
                        final position = Offset.lerp(startPos, endPos, curvedValue)!;

                        // Calculate hand position (slightly above the water drop)
                        final handPosition = Offset(
                          position.dx - 30,
                          position.dy - 50,
                        );

                        return Stack(
                          children: [
                            // Hand icon animation
                            Positioned(
                              left: handPosition.dx,
                              top: handPosition.dy,
                              child: Transform.rotate(
                                angle: _pourAnimationController.value * 0.3,
                                child: Opacity(
                                  opacity: 1.0 - (_pourAnimationController.value * 0.3),
                                  child: Icon(
                                    Icons.pan_tool,
                                    size: 40,
                                    color: Colors.brown.shade600,
                                  ),
                                ),
                              ),
                            ),
                            // Water drop animation
                            Positioned(
                              left: position.dx - 20,
                              top: position.dy - 20,
                              child: Transform.scale(
                                scale: 1.0 + (0.3 * _pourAnimationController.value),
                                child: Opacity(
                                  opacity: 0.9 - (_pourAnimationController.value * 0.5),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _pourAnimationColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _pourAnimationColor!.withOpacity(0.6),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.water_drop,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Water stream effect
                            Positioned(
                              left: position.dx - 3,
                              top: handPosition.dy + 30,
                              child: Opacity(
                                opacity: 0.7 * (1.0 - _pourAnimationController.value),
                                child: Container(
                                  width: 6,
                                  height: 30 * _pourAnimationController.value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        _pourAnimationColor!.withOpacity(0.8),
                                        _pourAnimationColor!.withOpacity(0.4),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Powered By ",
                      style: TextStyle(color: Colors.grey), // এখানে তোমার পছন্দের রঙ দাও
                    ),
                    TextSpan(
                      text: "Kingkar",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.0,)
          ],
        ),
      ),
    );
  }
}
