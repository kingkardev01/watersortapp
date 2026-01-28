import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class TestTubeWidget extends StatelessWidget {
  final int index;
  final List<Color> bottle;
  final int? selectedBottleIndex;
  final GlobalKey? key;
  final bool isCompleted;
  final bool isAnimating;
  final AnimationController completionAnimationController;

  const TestTubeWidget({
    required this.index,
    required this.bottle,
    required this.selectedBottleIndex,
    this.key,
    required this.isCompleted,
    required this.isAnimating,
    required this.completionAnimationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, // Adjust the width for the test tube
      height: 200, // Height of the test tube
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedBottleIndex == index ? Colors.blue.shade600 : Colors.grey.shade300,
          width: selectedBottleIndex == index ? 4 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: selectedBottleIndex == index ? Colors.blue.shade300.withOpacity(0.6) : Colors.grey.shade300.withOpacity(0.4),
            blurRadius: selectedBottleIndex == index ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: selectedBottleIndex == index ? 2 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              children: [
                // Test tube neck/rim (top)
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
                // Test tube body (liquid part)
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
                              // Fill empty space at the bottom of the test tube
                              Expanded(
                                flex: 5 - bottle.length,
                                child: Container(
                                  color: Colors.white,
                                ),
                              ),
                              // Liquid layers from top to bottom
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
                                          bottle[i].withOpacity(0.9),
                                          bottle[i],
                                        ],
                                      ),
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                // Test tube base (flat bottom)
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
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
            // Show selected color indicator above the test tube
            if (selectedBottleIndex == index && bottle.isNotEmpty)
              Positioned(
                top: -35,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bottle.first, // Bottom color
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: bottle.first.withOpacity(0.7),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            // Completion indicator animation
            if (isAnimating)
              AnimatedBuilder(
                animation: completionAnimationController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: completionAnimationController.value * 2,
                          colors: [
                            Colors.yellow.withOpacity(0.8 * (1 - completionAnimationController.value)),
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
                              Icons.celebration,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Permanent completion indicator
            if (isCompleted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.yellow.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 50,
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
  final Random random = Random();
  late AnimationController _pourAnimationController;
  int? _pourFromIndex;
  int? _pourToIndex;
  Color? _pourAnimationColor;
  bool _isPouring = false;
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
    // Initialize keys for all bottles (max 10 bottles)
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
    // Create a solvable game state
    bottles = _generateGameState();
  }

  List<List<Color>> _generateGameState() {
    // Generate colors for the game - vibrant and distinct colors
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

    // Always use 5 colors with 5 empty bottles (10 total bottles)
    int numColors = 5;
    List<Color> gameColors = colors.sublist(0, numColors);
    List<List<Color>> gameBottles = [];

    // Create 5 filled bottles (5 units each, all same color)
    for (Color color in gameColors) {
      gameBottles.add([color, color, color, color, color]);
    }

    // Add exactly 5 empty bottles
    for (int i = 0; i < 5; i++) {
      gameBottles.add([]);
    }

    // Shuffle the colors in each filled bottle to mix them
    // Collect all colors from the filled bottles
    List<Color> allColors = [];
    for (int j = 0; j < numColors; j++) {
      allColors.addAll(gameBottles[j]);
    }

    // Shuffle all colors
    allColors.shuffle(random);

    // Redistribute into bottles (5 colors each)
    for (int j = 0; j < numColors; j++) {
      gameBottles[j] = allColors.sublist(j * 5, (j + 1) * 5);
    }

    // Shuffle bottles
    gameBottles.shuffle(random);

    return gameBottles;
  }

  void _onBottleTap(int index) async {
    if (_isPouring) return;

    setState(() {
      if (selectedBottleIndex == null) {
        // Select a bottle
        if (bottles[index].isNotEmpty) {
          selectedBottleIndex = index;
        }
      } else {
        // Try to pour
        if (selectedBottleIndex == index) {
          // Deselect
          selectedBottleIndex = null;
        } else {
          _pourWaterWithAnimation(selectedBottleIndex!, index);
        }
      }
    });
  }

  Future<void> _pourWaterWithAnimation(int fromIndex, int toIndex) async {
    if (bottles[fromIndex].isEmpty || bottles[toIndex].length >= 5) {
      setState(() {
        selectedBottleIndex = null;
      });
      return;
    }

    List<Color> fromBottle = bottles[fromIndex];
    List<Color> toBottle = bottles[toIndex];

    // Get the bottom color from source bottle (first element = bottom)
    // Only pour the bottom color, not top colors
    Color bottomColor = fromBottle.first;

    // Check if destination is empty or has same color on top
    if (toBottle.isEmpty || toBottle.last == bottomColor) {
      // Count how many consecutive same colors from BOTTOM ONLY
      // Start from the bottom (first element) and count up
      int sameColorCount = 0;
      for (int i = 0; i < fromBottle.length; i++) {
        if (fromBottle[i] == bottomColor) {
          sameColorCount++;
        } else {
          // Stop if we hit a different color - only pour bottom colors
          break;
        }
      }

      // Pour as many as possible (max 5 - toBottle.length)
      int pourCount = sameColorCount;
      if (toBottle.length + pourCount > 5) {
        pourCount = 5 - toBottle.length;
      }

      // Only pour if we have bottom colors to pour
      if (pourCount > 0 && sameColorCount > 0) {
        _pourFromIndex = fromIndex;
        _pourToIndex = toIndex;
        _pourAnimationColor = bottomColor;

        setState(() {
          _isPouring = true;
          selectedBottleIndex = null;
        });

        // Play pour sound
        _audioPlayer.play(AssetSource('audio/water_sound.mp3'));

        // Start animation
        await _pourAnimationController.forward(from: 0.0);

        // Perform the pour after animation
        // Only pour consecutive bottom colors (same color from bottom)
        // Remove from bottom of source (first elements) and add to top of destination
        for (int i = 0; i < pourCount; i++) {
          // Remove from bottom of source (first element = bottom color)
          Color waterColor = fromBottle.removeAt(0);
          // Add to top of destination (append to end = top)
          toBottle.add(waterColor);
        }

        await _pourAnimationController.reverse();

        setState(() {
          _isPouring = false;
          _pourFromIndex = null;
          _pourToIndex = null;
          _pourAnimationColor = null;
        });

        // Update UI to show the new state after pouring
        setState(() {});

        // Check for newly completed bottles and animate them
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

        // Check if game is won after pouring
        // Game is won when exactly 5 bottles are FULL (each with 5 colors, all same color)
        // This happens when player successfully sorts all colors into 5 separate bottles
        bool gameWon = _isGameWon();

        if (gameWon) {
          print('✅ Win condition met: 5 bottles are full with matching colors');
          // Small delay to ensure UI is updated before showing congratulations popup
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

    // Check each bottle in the game
    for (var bottle in bottles) {
      // Skip empty bottles - they don't count
      if (bottle.isEmpty) continue;

      // Bottle must be FULL (exactly 5 colors) - no more, no less
      if (bottle.length == 5) {
        // Get the first color to compare with others
        Color firstColor = bottle[0];
        bool allSameColor = true;

        // Check if all 5 colors in this bottle are exactly the same
        for (var color in bottle) {
          if (color != firstColor) {
            allSameColor = false;
            break; // Found different color, this bottle is not complete
          }
        }

        // If all 5 colors match perfectly, this bottle is complete
        if (allSameColor) {
          completedBottles++;
        }
      }
    }

    // Game is won when EXACTLY 5 bottles are FULL with matching colors
    // Each of the 5 bottles must have exactly 5 colors, all the same color
    // We need exactly 5 completed bottles (one for each color: red, blue, green, yellow, orange)
    bool gameWon = (completedBottles == 5);

    // Debug: Print win status (can be removed in production)
    if (gameWon) {
      print('🎉 Game Won! 5 bottles are full with matching colors!');
    }

    return gameWon;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

          title: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, color: Colors.amber, size: 60),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          // ✅ ONE VALUE CARD ONLY
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top success row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 34),
                    const SizedBox(width: 10),
                    Text(
                      'Level ${widget.level} Completed',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Small highlight badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'All 5 Bottles Full! 🎉',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 10),

                // Your existing rule/message but inside same card
                Text(
                  'Each bottle has 5 matching colors!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  'Perfect sorting! 🎊',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _restartGame();
              },
              child: const Text('Restart Game'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Home'),
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
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
      _initializeGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Level ${widget.level}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: 'Restart Game',
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
        child: SafeArea(
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
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            
                            Container(
                              width: 24,
                              height: 24,
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
                      ),
                      if(selectedBottleIndex ==null)
                      Container(
                         padding: const EdgeInsets.only(top: 12.0),
                        height: 33,color: Colors.transparent,)
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: bottles.length <= 5 ? bottles.length : 5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: bottles.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _onBottleTap(index),
                          child: TestTubeWidget(
                            index: index,
                            bottle: bottles[index],
                            selectedBottleIndex: selectedBottleIndex,
                            key: _bottleKeys[index],
                            isCompleted: _completedBottles.contains(index),
                            isAnimating: _animatingCompletionIndex == index,
                            completionAnimationController: _completionAnimationController,
                          ),
                        );
                      },
                    ),
                    // Pouring animation overlay
                    if (_isPouring && _pourFromIndex != null && _pourToIndex != null && _pourAnimationColor != null)
                      AnimatedBuilder(
                        animation: _pourAnimationController,
                        builder: (context, child) {
                          Offset? startPos;
                          Offset? endPos;

                          // Get positions from GlobalKeys
                          if (_bottleKeys[_pourFromIndex]?.currentContext != null && _bottleKeys[_pourToIndex]?.currentContext != null) {
                            final RenderBox? fromBox = _bottleKeys[_pourFromIndex]!.currentContext!.findRenderObject() as RenderBox?;
                            final RenderBox? toBox = _bottleKeys[_pourToIndex]!.currentContext!.findRenderObject() as RenderBox?;

                            if (fromBox != null && toBox != null) {
                              startPos = fromBox.localToGlobal(Offset.zero);
                              endPos = toBox.localToGlobal(Offset.zero);

                              // Adjust to center of bottles
                              startPos = Offset(
                                startPos.dx + fromBox.size.width / 2,
                                startPos.dy + fromBox.size.height / 2,
                              );
                              endPos = Offset(
                                endPos.dx + toBox.size.width / 2,
                                endPos.dy + toBox.size.height / 2,
                              );
                            }
                          }

                          if (startPos == null || endPos == null) {
                            return const SizedBox.shrink();
                          }

                          final curvedValue = Curves.easeInOut.transform(_pourAnimationController.value);
                          // Calculate curved path using quadratic Bezier curve
                          final controlPoint = Offset(
                            (startPos.dx + endPos.dx) / 2,
                            min(startPos.dy, endPos.dy) - 100, // Control point above the line
                          );
                          final t = curvedValue;
                          final position = Offset(
                            (1 - t) * (1 - t) * startPos.dx + 2 * (1 - t) * t * controlPoint.dx + t * t * endPos.dx,
                            (1 - t) * (1 - t) * startPos.dy + 2 * (1 - t) * t * controlPoint.dy + t * t * endPos.dy,
                          );

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
            ],
          ),
        ),
      ),
    );
  }
}
