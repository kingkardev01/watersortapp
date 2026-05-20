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
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: 100,
                itemBuilder: (context, index) {
                  return Obx(() {
                    int level = index + 1;
                    bool isUnlocked = levelController.isLevelUnlocked(level);
                    bool isCurrentLevel = level == levelController.unlockedLevels.value;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
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
                            gradient: isUnlocked
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isCurrentLevel
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
                            color: isUnlocked ? null : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                            border: isUnlocked
                                ? Border.all(
                                    color: isCurrentLevel
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade200,
                                    width: isCurrentLevel ? 2 : 1.5,
                                  )
                                : Border.all(
                                    color: Colors.grey.shade400,
                                    width: 1,
                                  ),
                            boxShadow: isUnlocked
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.shade200.withOpacity(0.4),
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
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.elasticOut,
                                transform: Matrix4.identity()
                                  ..scale(isCurrentLevel ? 1.1 : 1.0),
                                child: Icon(
                                  isUnlocked ? Icons.water_drop : Icons.lock,
                                  size: 40,
                                  color: isUnlocked 
                                      ? (isCurrentLevel 
                                          ? Colors.blue.shade700 
                                          : Colors.blue.shade600)
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Level $level',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked 
                                      ? (isCurrentLevel 
                                          ? Colors.blue.shade900 
                                          : Colors.blue.shade800)
                                      : Colors.grey.shade600,
                                ),
                              ),
                              if (isCurrentLevel)
                                Container(
                                  
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'NEW!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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