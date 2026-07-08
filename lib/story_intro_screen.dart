import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:watersortapp/home_screen.dart';
import 'package:watersortapp/theme/app_theme.dart';
import 'package:watersortapp/widgets/animated_water_background.dart';
import 'package:watersortapp/widgets/mascot_droplet.dart';

class _StoryPanel {
  final MascotExpression expression;
  final String title;
  final String body;

  const _StoryPanel({
    required this.expression,
    required this.title,
    required this.body,
  });
}

const List<_StoryPanel> _panels = [
  _StoryPanel(
    expression: MascotExpression.happy,
    title: "Meet Drippy!",
    body: "Once upon a splash, a curious little water drop named Drippy "
        "was born in Shallow Bay.",
  ),
  _StoryPanel(
    expression: MascotExpression.sleepy,
    title: "A colorful mess",
    body: "One stormy night, all the colors of Sort Puz Land got mixed up "
        "together in a jumble of bottles!",
  ),
  _StoryPanel(
    expression: MascotExpression.excited,
    title: "Drippy needs YOU",
    body: "Only a clever sorter can pour, match, and untangle the colors "
        "one bottle at a time. Will you help?",
  ),
  _StoryPanel(
    expression: MascotExpression.wink,
    title: "Earn your way",
    body: "Clear levels to earn coins and unlock new worlds — from Shallow "
        "Bay all the way to the Galaxy Core!",
  ),
  _StoryPanel(
    expression: MascotExpression.cheer,
    title: "Ready, Sorter?",
    body: "Your adventure with Drippy starts now. Let's sort some water!",
  ),
];

/// One-time narrative intro shown before the player's very first game.
/// Sets a persisted flag on completion (or skip) so it never appears again.
class StoryIntroScreen extends StatefulWidget {
  const StoryIntroScreen({super.key});

  @override
  State<StoryIntroScreen> createState() => _StoryIntroScreenState();
}

class _StoryIntroScreenState extends State<StoryIntroScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    GetStorage().write('storySeen', true);
    Get.offAll(() => const HomeScreen(), transition: Transition.fadeIn);
  }

  void _next() {
    if (_page == _panels.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _page == _panels.length - 1;

    return Scaffold(
      body: AnimatedWaterBackground(
        gradientColors: AppColors.splashGradient,
        bubbleColor: Colors.white,
        bubbleCount: 18,
        maxBubbleOpacity: 0.2,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    child: const Text('Skip'),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _panels.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) {
                    final panel = _panels[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MascotDroplet(
                            size: 150,
                            expression: panel.expression,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            panel.title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading(
                              fontSize: 26,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            panel.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_panels.length, (i) {
                    final bool active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _next,
                    icon: Icon(isLast
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(isLast ? 'Start Playing' : 'Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
