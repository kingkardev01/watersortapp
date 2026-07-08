import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/level_controller.dart';
import 'package:watersortapp/data/worlds.dart';
import 'package:watersortapp/game_screen.dart';
import 'package:watersortapp/how_to_play_screen.dart';
import 'package:watersortapp/settings_screen.dart';
import 'package:watersortapp/shop_screen.dart';
import 'package:watersortapp/theme/app_theme.dart';
import 'package:watersortapp/widgets/animated_water_background.dart';
import 'package:watersortapp/widgets/coin_balance_chip.dart';
import 'package:watersortapp/widgets/staggered_fade_in.dart';
import 'package:watersortapp/widgets/tap_scale.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LevelController levelController = Get.put(LevelController());
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SortPuz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const CoinBalanceChip(),
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'Shop',
            onPressed: () => Get.to(
              () => const ShopScreen(),
              transition: Transition.rightToLeftWithFade,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'How to Play',
            onPressed: () => Get.to(
              () => const HowToPlayScreen(),
              transition: Transition.rightToLeftWithFade,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Get.to(
              () => const SettingsScreen(),
              transition: Transition.rightToLeftWithFade,
            ),
          ),
        ],
      ),
      body: AnimatedWaterBackground(
        gradientColors: AppColors.homeBackground,
        bubbleColor: AppColors.primary,
        bubbleCount: 14,
        maxBubbleOpacity: 0.09,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Select a Level',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exercise your logical ability',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: gameWorlds.length,
                itemBuilder: (context, index) {
                  return _WorldSection(
                    world: gameWorlds[index],
                    levelController: levelController,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One themed group of 10 levels: a gradient header banner (name, level
/// range, progress bar) followed by that world's 5x2 level grid.
class _WorldSection extends StatelessWidget {
  final GameWorld world;
  final LevelController levelController;

  const _WorldSection({required this.world, required this.levelController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            int completed = 0;
            for (int lvl = world.startLevel; lvl <= world.endLevel; lvl++) {
              if (levelController.isLevelCompleted(lvl)) completed++;
            }
            final bool isWorldComplete = completed == world.levelCount;
            final double progress = completed / world.levelCount;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: world.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: world.accent.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(world.icon, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              world.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (isWorldComplete) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 12, color: Colors.black87),
                                    SizedBox(width: 2),
                                    Text(
                                      'Complete',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Levels ${world.startLevel}-${world.endLevel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$completed/${world.levelCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: world.levelCount,
            itemBuilder: (context, idx) {
              final level = world.startLevel + idx;
              return StaggeredFadeIn(
                delay: Duration(milliseconds: idx * 25),
                child: _LevelCard(
                  level: level,
                  levelController: levelController,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final LevelController levelController;

  const _LevelCard({required this.level, required this.levelController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isUnlocked = levelController.isLevelUnlocked(level);
      final bool isCurrentLevel = level == levelController.unlockedLevels.value;
      final bool isCompleted = levelController.isLevelCompleted(level);
      final int bestScore = levelController.getBestScore(level);
      final int stars =
          isCompleted ? WaterSortGame.starRating(level, bestScore) : 0;
      final int numColors = WaterSortGame.numColorsForLevel(level);

      final card = TapScale(
        onTap: isUnlocked
            ? () async {
                final result = await Get.to(
                  () => GameScreen(level: level),
                  transition: Transition.rightToLeftWithFade,
                );
                if (result == true &&
                    level == levelController.unlockedLevels.value) {
                  levelController.unlockNextLevel();
                }
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Please complete Level ${level - 1} first!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        child: Container(
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isCompleted
                        ? [
                            Colors.green.shade100,
                            Colors.green.shade50,
                          ]
                        : isCurrentLevel
                            ? [
                                Colors.blue.shade400,
                                Colors.blue.shade200,
                              ]
                            : [
                                Colors.blue.shade50,
                                Colors.white,
                              ],
                  )
                : null,
            color: isUnlocked ? null : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: isUnlocked
                ? Border.all(
                    color: isCompleted
                        ? Colors.green.shade400
                        : isCurrentLevel
                            ? Colors.blue.shade300
                            : Colors.blue.shade200,
                    width: (isCurrentLevel || isCompleted) ? 2 : 1.5,
                  )
                : Border.all(
                    color: AppColors.lockedBorder,
                    width: 1.4,
                  ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: isCompleted
                          ? Colors.green.shade200.withOpacity(0.4)
                          : Colors.blue.shade200.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.shade400.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.elasticOut,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isUnlocked
                      ? (isCompleted ? Icons.check_circle_rounded : Icons.water_drop)
                      : Icons.lock,
                  key: ValueKey('$level-$isUnlocked-$isCompleted'),
                  size: 34,
                  color: isUnlocked
                      ? (isCompleted
                          ? Colors.green.shade600
                          : isCurrentLevel
                              ? Colors.blue.shade700
                              : Colors.blue.shade600)
                      : AppColors.lockedIcon,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Level $level',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? (isCompleted
                          ? Colors.green.shade800
                          : isCurrentLevel
                              ? Colors.blue.shade900
                              : Colors.blue.shade800)
                      : AppColors.lockedText,
                ),
              ),
              const SizedBox(height: 3),
              // Difficulty preview: one dot per color used in this level,
              // so players can gauge harder levels before tapping in.
              if (isUnlocked)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  children: List.generate(numColors, (i) {
                    return Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: WaterSortGame.palette[i].shade400,
                      ),
                    );
                  }),
                ),
              if (isCompleted) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Icon(
                      i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: i < stars ? Colors.amber : Colors.grey.shade400,
                      size: 12,
                    );
                  }),
                ),
              ] else if (isCurrentLevel) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEW!',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

      return _PulsingGlow(
        active: isCurrentLevel,
        color: Colors.blue.shade400,
        child: card,
      );
    });
  }
}

/// Wraps [child] with a slow breathing glow so the current/next level to
/// play stands out at a glance among 100 otherwise-similar cards.
class _PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool active;

  const _PulsingGlow({
    required this.child,
    required this.color,
    required this.active,
  });

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.25 + 0.3 * t),
                blurRadius: 10 + 12 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
