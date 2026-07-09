import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/achievement_controller.dart';
import 'package:watersortapp/controllers/daily_reward_controller.dart';
import 'package:watersortapp/theme/app_theme.dart';
import 'package:watersortapp/widgets/staggered_fade_in.dart';
import 'package:watersortapp/widgets/tap_scale.dart';

/// Opens the 7-day login streak dialog with a frosted-glass card over a
/// blurred backdrop and a springy pop-in transition. Safe to call whether
/// or not today's reward has already been claimed — it just shows the
/// claimed state.
void showDailyRewardDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Daily Reward',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const DailyRewardDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 6 * fade.value,
          sigmaY: 6 * fade.value,
        ),
        child: FadeTransition(
          opacity: fade,
          child: Transform.scale(
            scale: 0.82 + 0.18 * curved.value.clamp(0.0, 1.2),
            child: child,
          ),
        ),
      );
    },
  );
}

class DailyRewardDialog extends StatelessWidget {
  const DailyRewardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DailyRewardController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.92),
                  Colors.blue.shade50.withOpacity(0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 1,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BouncingGift(),
                const SizedBox(height: 10),
                Text(
                  'Daily Reward',
                  style: AppTextStyles.heading(fontSize: 22, color: Colors.blue.shade900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Come back every day for bigger rewards!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 22),
                Obx(
                  () => Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      DailyRewardController.dayRewards.length,
                      (i) {
                        final day = i + 1;
                        final state = day < controller.currentDay.value
                            ? _DayState.claimed
                            : day == controller.currentDay.value
                                ? (controller.claimedToday.value
                                    ? _DayState.claimed
                                    : _DayState.today)
                                : _DayState.upcoming;
                        return StaggeredFadeIn(
                          delay: Duration(milliseconds: i * 60),
                          child: _DayCell(
                            day: day,
                            reward: DailyRewardController.dayRewards[i],
                            state: state,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Obx(
                  () => _ClaimButton(
                    canClaim: controller.canClaim,
                    reward: controller.todaysReward,
                    onClaim: () {
                      controller.claim();
                      Get.find<AchievementController>().checkAll();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gift emoji with a soft continuous bob + rotate, so the dialog feels
/// alive the instant it appears instead of a static header.
class _BouncingGift extends StatefulWidget {
  const _BouncingGift();

  @override
  State<_BouncingGift> createState() => _BouncingGiftState();
}

class _BouncingGiftState extends State<_BouncingGift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -4 * t),
          child: Transform.rotate(
            angle: (t - 0.5) * 0.12,
            child: child,
          ),
        );
      },
      child: const Text('🎁', style: TextStyle(fontSize: 44)),
    );
  }
}

enum _DayState { claimed, today, upcoming }

class _DayCell extends StatelessWidget {
  final int day;
  final int reward;
  final _DayState state;

  const _DayCell({
    required this.day,
    required this.reward,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final bool isToday = state == _DayState.today;
    final bool isClaimed = state == _DayState.claimed;

    final List<Color> gradientColors = isToday
        ? [Colors.amber.shade300, Colors.orange.shade400]
        : isClaimed
            ? [Colors.green.shade200, Colors.green.shade100]
            : [Colors.white.withOpacity(0.55), Colors.white.withOpacity(0.25)];

    final Color border = isToday
        ? Colors.amber.shade600
        : isClaimed
            ? Colors.green.shade400
            : Colors.white.withOpacity(0.6);

    final Widget cell = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: isToday ? 2 : 1.2),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Day $day',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          isClaimed
              ? Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 18)
              : Icon(Icons.monetization_on_rounded,
                  color: isToday ? Colors.white : Colors.grey.shade400,
                  size: 18),
          const SizedBox(height: 2),
          Text(
            '$reward',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );

    return isToday ? _PulseGlow(child: cell) : cell;
  }
}

/// Soft breathing glow used to draw the eye to today's claimable reward
/// (and the claim button) without being as loud as a shake or bounce.
class _PulseGlow extends StatefulWidget {
  final Widget child;
  const _PulseGlow({required this.child});

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.25 + 0.25 * t),
                blurRadius: 10 + 10 * t,
                spreadRadius: 1 + 1.5 * t,
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

class _ClaimButton extends StatelessWidget {
  final bool canClaim;
  final int reward;
  final VoidCallback onClaim;

  const _ClaimButton({
    required this.canClaim,
    required this.reward,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final button = TapScale(
      onTap: canClaim ? onClaim : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: canClaim
              ? LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade200],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: canClaim ? Colors.white.withOpacity(0.6) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canClaim ? Icons.monetization_on_rounded : Icons.check_circle_rounded,
              color: canClaim ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              canClaim ? 'Claim $reward Coins' : 'See you tomorrow!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: canClaim ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );

    return canClaim ? _PulseGlow(child: button) : button;
  }
}
