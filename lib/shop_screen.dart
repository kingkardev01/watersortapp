import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:watersortapp/controllers/coin_controller.dart';
import 'package:watersortapp/controllers/settings_controller.dart';
import 'package:watersortapp/controllers/shop_controller.dart';
import 'package:watersortapp/models/bottle_style.dart';
import 'package:watersortapp/theme/app_theme.dart';
import 'package:watersortapp/widgets/animated_water_background.dart';
import 'package:watersortapp/widgets/bottle_glass_preview.dart';
import 'package:watersortapp/widgets/coin_balance_chip.dart';

/// Where coins earned from clearing levels actually get spent: hint/undo
/// top-ups and cosmetic bottle-style unlocks.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = Get.find<ShopController>();
    final coins = Get.find<CoinController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [CoinBalanceChip()],
      ),
      body: AnimatedWaterBackground(
        gradientColors: AppColors.homeBackground,
        bubbleColor: AppColors.primary,
        bubbleCount: 12,
        maxBubbleOpacity: 0.08,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Power-Ups', style: AppTextStyles.heading(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Spend coins for extra hints and undos mid-level',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Obx(
              () => _PowerUpCard(
                icon: Icons.lightbulb_rounded,
                iconColor: Colors.amber.shade600,
                label: 'Hints',
                owned: shop.hintTokens.value,
                packSize: ShopController.hintPackSize,
                price: ShopController.hintPackPrice,
                onBuy: () => _buy(context, shop.buyHintPack, coins),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => _PowerUpCard(
                icon: Icons.undo_rounded,
                iconColor: Colors.blue.shade600,
                label: 'Undos',
                owned: shop.undoTokens.value,
                packSize: ShopController.undoPackSize,
                price: ShopController.undoPackPrice,
                onBuy: () => _buy(context, shop.buyUndoPack, coins),
              ),
            ),
            const SizedBox(height: 28),
            Text('Bottle Styles', style: AppTextStyles.heading(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Unlock new glassware — equip it anytime from Settings',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Obx(
              () => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
                children: BottleStyle.values.map((style) {
                  final info = bottleStyleInfo[style]!;
                  final bool owned = shop.isOwned(style);
                  final bool equipped = settings.bottleStyle.value == style;
                  return _StyleCard(
                    style: style,
                    label: info.label,
                    price: info.price,
                    owned: owned,
                    equipped: equipped,
                    onTap: () {
                      if (owned) {
                        settings.setBottleStyle(style);
                      } else {
                        _confirmUnlock(context, shop, coins, style, info);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _buy(
    BuildContext context,
    bool Function() attempt,
    CoinController coins,
  ) {
    if (attempt()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase complete!')),
      );
    } else {
      _showNotEnoughCoins(context);
    }
  }

  void _confirmUnlock(
    BuildContext context,
    ShopController shop,
    CoinController coins,
    BottleStyle style,
    BottleStyleInfo info,
  ) {
    if (coins.coins.value < info.price) {
      _showNotEnoughCoins(context);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unlock ${info.label}?'),
        content: Text('This costs ${info.price} coins.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (shop.unlockStyle(style)) {
                Get.find<SettingsController>().setBottleStyle(style);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${info.label} unlocked!')),
                );
              } else {
                _showNotEnoughCoins(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _showNotEnoughCoins(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not enough coins — clear more levels to earn some!'),
      ),
    );
  }
}

class _PowerUpCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int owned;
  final int packSize;
  final int price;
  final VoidCallback onBuy;

  const _PowerUpCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.owned,
    required this.packSize,
    required this.price,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have: $owned',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('+$packSize for $price'),
          ),
        ],
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final BottleStyle style;
  final String label;
  final int price;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  const _StyleCard({
    required this.style,
    required this.label,
    required this.price,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped ? Colors.blue.shade600 : Colors.blue.shade100,
            width: equipped ? 2.2 : 1.4,
          ),
          boxShadow: equipped
              ? [
                  BoxShadow(
                    color: Colors.blue.shade300.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppColors.gameBackgroundGradient,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Opacity(
                    opacity: owned ? 1.0 : 0.45,
                    child: BottleGlassPreview(
                      style: style,
                      width: 34,
                      height: 84,
                    ),
                  ),
                ),
                if (!owned)
                  Icon(Icons.lock_rounded,
                      color: Colors.white.withOpacity(0.85), size: 26),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: equipped ? Colors.blue.shade700 : Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: 3),
            if (equipped)
              Icon(Icons.check_circle_rounded,
                  size: 14, color: Colors.blue.shade600)
            else if (owned)
              Text(
                'Tap to equip',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on_rounded,
                      size: 12, color: Colors.amber.shade700),
                  const SizedBox(width: 2),
                  Text(
                    '$price',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
