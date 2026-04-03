import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/level_controller.dart';
import 'package:watersortapp/game_screen.dart';

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
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: 100,
                itemBuilder: (context, index) {
                  return Obx(() {
                    int level = index + 1;
                    bool isUnlocked = levelController.isLevelUnlocked(level);
                    return GestureDetector(
                      onTap: isUnlocked
                          ? () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameScreen(level: level),
                                ),
                              );
                              if (result == true && level == levelController.unlockedLevels.value) {
                                // Level completed, unlock next level
                                levelController.unlockNextLevel();
                              }
                            }
                          : () {
                              // Show message for locked level
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please complete Level ${level - 1} first!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked ? Colors.white : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.shade200,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUnlocked ? Icons.water_drop : Icons.lock,
                              size: 40,
                              color: isUnlocked ? Colors.blue.shade600 : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Level $level',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? Colors.blue.shade800 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
    
  }
}