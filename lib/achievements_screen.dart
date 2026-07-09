import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/achievement_controller.dart';
import 'package:watersortapp/models/achievement.dart';
import 'package:watersortapp/theme/app_theme.dart';
import 'package:watersortapp/widgets/animated_water_background.dart';
import 'package:watersortapp/widgets/staggered_fade_in.dart';

/// Full list of achievements with live progress bars — unlocking one here
/// credits coins automatically via [AchievementController.checkAll], which
/// already runs after every level win, daily claim, and shop purchase.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = Get.find<AchievementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedWaterBackground(
        gradientColors: AppColors.homeBackground,
        bubbleColor: AppColors.primary,
        bubbleCount: 12,
        maxBubbleOpacity: 0.08,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: Obx(() {
                final unlocked = achievements.unlockedIds.length;
                final total = allAchievements.length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade200.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlocked / $total unlocked',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : unlocked / total,
                                minHeight: 6,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor:
                                    const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: allAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = allAchievements[index];
                  return StaggeredFadeIn(
                    delay: Duration(milliseconds: index * 35),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AchievementCard(
                        achievement: achievement,
                        controller: achievements,
                      ),
                    ),
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

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final AchievementController controller;

  const _AchievementCard({
    required this.achievement,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Scoped to just this card's own Obx — reading many controllers' Rx
    // values inside one big Obx around the whole list caused GetX's
    // "improper use of a GetX" reentrancy error.
    return Obx(() {
      final bool unlocked = controller.isUnlocked(achievement.id);
      final int progress = controller.progressFor(achievement);
      return _AchievementCardContent(
        achievement: achievement,
        unlocked: unlocked,
        progress: progress,
      );
    });
  }
}

class _AchievementCardContent extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final int progress;

  const _AchievementCardContent({
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? Colors.amber.shade300 : Colors.blue.shade50,
          width: unlocked ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (unlocked ? Colors.amber.shade100 : Colors.blue.shade100)
                .withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: unlocked
                  ? LinearGradient(
                      colors: [Colors.amber.shade300, Colors.orange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: unlocked ? null : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? achievement.icon : Icons.lock_rounded,
              color: unlocked ? Colors.white : Colors.grey.shade400,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: unlocked
                              ? Colors.blueGrey.shade900
                              : Colors.blueGrey.shade400,
                        ),
                      ),
                    ),
                    if (unlocked)
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade500, size: 18)
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on_rounded,
                              size: 13, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                            '${achievement.coinReward}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: achievement.target == 0
                        ? 1
                        : progress / achievement.target,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      unlocked ? Colors.green.shade400 : Colors.blue.shade300,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$progress / ${achievement.target}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
