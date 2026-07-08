import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/coin_controller.dart';

/// Coin balance pill shown in app bars — shared between Home and Shop so
/// the balance reads consistently wherever coins are earned or spent.
class CoinBalanceChip extends StatelessWidget {
  const CoinBalanceChip({super.key});

  @override
  Widget build(BuildContext context) {
    final coinController = Get.find<CoinController>();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Obx(
                () => Text(
                  '${coinController.coins.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
