import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/model/dashboard_models.dart';

class EquipmentSumBadge extends StatelessWidget {
  final MapIconModel icon;
  final int equipmentCount;
  final VoidCallback onTap;

  const EquipmentSumBadge({
    super.key,
    required this.icon,
    required this.equipmentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.warning, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, color: AppTheme.warning, size: 16),
            const SizedBox(width: 6),
            Text(
              '$equipmentCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}