import 'package:flutter/material.dart';
import 'package:watersortapp/theme/app_theme.dart';
import 'package:watersortapp/widgets/animated_water_background.dart';

/// Short, plain-language rules screen — written so it makes sense to both
/// young kids and older players without prior puzzle-game experience.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const List<_Step> _steps = [
    _Step(
      icon: Icons.touch_app_rounded,
      title: '1. Tap a bottle',
      description: 'Tap any bottle to pick up the color on top.',
    ),
    _Step(
      icon: Icons.arrow_downward_rounded,
      title: '2. Tap another bottle',
      description:
          'Tap a second bottle to pour that color into it. You can only '
          'pour onto an empty bottle or the same color.',
    ),
    _Step(
      icon: Icons.check_circle_rounded,
      title: '3. Fill a bottle with one color',
      description:
          'When a bottle is completely full of a single color, it locks '
          'and celebrates — that color is sorted!',
    ),
    _Step(
      icon: Icons.emoji_events_rounded,
      title: '4. Sort every color to win',
      description: 'Clear all the colors into their own bottles to finish '
          'the level. Fewer moves earn more stars.',
    ),
    _Step(
      icon: Icons.undo_rounded,
      title: 'Stuck? Use Undo or Restart',
      description:
          'The Undo button takes back your last move, and Restart gives '
          'you a fresh board — no penalty either way.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedWaterBackground(
        gradientColors: AppColors.homeBackground,
        bubbleColor: AppColors.primary,
        bubbleCount: 10,
        maxBubbleOpacity: 0.08,
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) => _StepCard(step: _steps[index]),
        ),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String title;
  final String description;

  const _Step({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _StepCard extends StatelessWidget {
  final _Step step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: Colors.blue.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.heading(
                    fontSize: 17,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: AppTextStyles.body(
                    fontSize: 14,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
