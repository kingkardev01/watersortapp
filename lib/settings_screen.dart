import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/level_controller.dart';
import 'package:watersortapp/controllers/profile_controller.dart';
import 'package:watersortapp/controllers/settings_controller.dart';
import 'package:watersortapp/models/bottle_style.dart';
import 'package:watersortapp/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final levelController = Get.find<LevelController>();
    final profile = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.homeBackground,
          ),
        ),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Glass Style', style: AppTextStyles.heading(fontSize: 18)),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                children: BottleStyle.values.map((s) {
                  final info = bottleStyleInfo[s]!;
                  final bool selected = settings.bottleStyle.value == s;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => settings.setBottleStyle(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blue.shade600
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? Colors.blue.shade600
                                  : Colors.blue.shade100,
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                info.icon,
                                size: 26,
                                color: selected
                                    ? Colors.white
                                    : Colors.blue.shade600,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                info.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : Colors.blueGrey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
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
