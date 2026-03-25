import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/model/dashboard_models.dart';

class MaterialSumBadge extends StatelessWidget {
  final MapIconModel icon;
  final int materialCount;
  final VoidCallback onTap;

  const MaterialSumBadge({
    super.key,
    required this.icon,
    required this.materialCount,
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
          border: Border.all(color: const Color(0xFF64D2FF), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2, color: Color(0xFF64D2FF), size: 16),
            const SizedBox(width: 6),
            Text(
              '$materialCount',
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