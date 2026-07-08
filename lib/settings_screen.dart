import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/level_controller.dart';
import 'package:watersortapp/controllers/profile_controller.dart';
import 'package:watersortapp/controllers/settings_controller.dart';
import 'package:watersortapp/controllers/shop_controller.dart';
import 'package:watersortapp/how_to_play_screen.dart';
import 'package:watersortapp/models/bottle_style.dart';
import 'package:watersortapp/shop_screen.dart';
import 'package:watersortapp/theme/app_theme.dart';
import 'package:watersortapp/widgets/animated_water_background.dart';
import 'package:watersortapp/widgets/bottle_glass_preview.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final levelController = Get.find<LevelController>();
    final profile = Get.find<ProfileController>();
    final shop = Get.find<ShopController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedWaterBackground(
        gradientColors: AppColors.homeBackground,
        bubbleColor: AppColors.primary,
        bubbleCount: 12,
        maxBubbleOpacity: 0.08,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Profile', style: AppTextStyles.heading(fontSize: 18)),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final bytes = profile.profileImageBytes.value;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: profile.pickProfileImage,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage:
                                  bytes != null ? MemoryImage(bytes) : null,
                              child: bytes == null
                                  ? Icon(Icons.person_rounded,
                                      size: 32, color: Colors.blue.shade400)
                                  : null,
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile.userName.value,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _editName(context, profile),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 13, color: Colors.blue.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit name',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bytes != null)
                        IconButton(
                          onPressed: profile.removeProfileImage,
                          tooltip: 'Remove photo',
                          icon: Icon(Icons.close_rounded,
                              color: Colors.grey.shade400, size: 20),
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 28),
            Text('Preferences', style: AppTextStyles.heading(fontSize: 18)),
            const SizedBox(height: 8),
            Obx(
              () => _SettingsCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: settings.soundEnabled.value,
                      onChanged: settings.toggleSound,
                      activeThumbColor: Colors.blue.shade600,
                      title: const Text('Sound Effects'),
                      subtitle: const Text('Pour and celebration sounds'),
                      secondary: const Icon(Icons.volume_up_rounded),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: settings.hapticsEnabled.value,
                      onChanged: settings.toggleHaptics,
                      activeThumbColor: Colors.blue.shade600,
                      title: const Text('Haptic Feedback'),
                      subtitle: const Text('Vibration on tap and win'),
                      secondary: const Icon(Icons.vibration_rounded),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: settings.largeText.value,
                      onChanged: settings.toggleLargeText,
                      activeThumbColor: Colors.blue.shade600,
                      title: const Text('Large Text & Buttons'),
                      subtitle: const Text(
                          'Bigger text app-wide — easier reading for kids and seniors'),
                      secondary: const Icon(Icons.text_increase_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Help', style: AppTextStyles.heading(fontSize: 18)),
            const SizedBox(height: 8),
            _SettingsCard(
              child: ListTile(
                leading: Icon(Icons.help_outline_rounded,
                    color: Colors.blue.shade600),
                title: const Text('How to Play'),
                subtitle: const Text('A quick refresher on the rules'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Get.to(
                  () => const HowToPlayScreen(),
                  transition: Transition.rightToLeftWithFade,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Glass Style', style: AppTextStyles.heading(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Live preview — rendered the same way as in-game bottles',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Obx(() {
              final ownedStyles =
                  BottleStyle.values.where(shop.isOwned).toList();
              final int lockedCount =
                  BottleStyle.values.length - ownedStyles.length;
              return Row(
                children: [
                  ...ownedStyles.map((s) {
                  final info = bottleStyleInfo[s]!;
                  final bool selected = settings.bottleStyle.value == s;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => settings.setBottleStyle(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? Colors.blue.shade600
                                  : Colors.blue.shade100,
                              width: selected ? 2.2 : 1.4,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.shade300
                                          .withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Same dark backdrop as the game canvas so the
                              // glass/liquid rendering has the contrast it
                              // was designed for, not a flat icon substitute.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: AppColors.gameBackgroundGradient,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: BottleGlassPreview(
                                    style: s,
                                    width: 34,
                                    height: 84,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                info.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.blue.shade700
                                      : Colors.blueGrey.shade700,
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(height: 3),
                                Icon(Icons.check_circle_rounded,
                                    size: 14, color: Colors.blue.shade600),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  }),
                  if (lockedCount > 0)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Get.to(
                            () => const ShopScreen(),
                            transition: Transition.rightToLeftWithFade,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.amber.shade300, width: 1.4),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: AppColors.gameBackgroundGradient,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SizedBox(
                                    height: 84,
                                    child: Center(
                                      child: Icon(Icons.add_circle_rounded,
                                          color: Colors.amber.shade300,
                                          size: 30),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$lockedCount more',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 28),
            Text('Danger Zone', style: AppTextStyles.heading(fontSize: 18)),
            const SizedBox(height: 8),
            _SettingsCard(
              child: ListTile(
                leading: Icon(Icons.delete_forever_rounded,
                    color: Colors.red.shade400),
                title: const Text('Reset Progress'),
                subtitle: const Text('Erases all unlocked levels and scores'),
                onTap: () => _confirmReset(context, levelController),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, LevelController levelController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will erase all unlocked levels and best scores. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              levelController.resetProgress();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress has been reset.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context, ProfileController profile) {
    final controller = TextEditingController(text: profile.userName.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              profile.setUserName(controller.text);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
